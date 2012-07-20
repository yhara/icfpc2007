# 再設計
# - prepend, concatの代わりに+を提供する
#   - +でもべつに性能上問題なかった
# - 空Leafは気にしない事にする
# - RopeがLeafもNodeも表すことにする(experimental)
#
# 提供するAPI
#
# - Rope#new
# - Rope#size -> Integer
# - Rope#shift!(n=1) -> String
# - Rope#[pos]
# - Rope#[from...to]
# - Rope#index(str, pos)
# - Rope#+(other_rope)
# - Rope#to_s
#
# - Rope#empty?
#
# Rope#[from...to]が

require 'forwardable'

module Profilable
  def prof(method_name, opts={})
    alias_method "#{method_name}_noprof", method_name
    define_method method_name do |*args|
      if opts[:when] && opts[:when].call
        p [:prof_start, self, method_name, *args] if opts[:start]
        t1 = Time.now
        ret = __send__("#{method_name}_noprof", *args)
        time = Time.now - t1
        p [:prof, time, self, method_name, *args]
        ret
      else
        __send__("#{method_name}_noprof", *args)
      end
    end
  end
end

class Rope
  extend Forwardable

  # Used from unit tests
  def self.[](arg1, arg2=nil)
    if arg2
      raise TypeError unless Rope === arg1 && Rope === arg2
      new(arg1.node, arg2.node)
    else
      raise TypeError unless String === arg1
      new(arg1)
    end
  end

  def initialize(arg1, arg2=nil)
    if arg2
      raise TypeError unless Node === arg1 && Node === arg2
      @node = Node.new(arg1, arg2)
    else
      case arg1
      when String then @node = Node.new(arg1)
      when Node   then @node = arg1
      else raise TypeError
      end
    end
  end
  attr_reader :node

  def_delegators :@node, :size, :depth, :empty?, :shift,
    :[], :index, :+, :to_s, :enum_from, :each_char

  def shift(*args)
    ret = @node.shift(*args)
    @node = @node.remove_empty_leaf
    @node.update_size_and_depth!
    ret
  end

  def inspect
    "#<Rope #{@node.inspect}>"
  end

  def tree
    "#<Rope #{@node.tree}>"
  end

  class Node
    extend Profilable

    def initialize(arg1=nil, arg2=nil)
      if arg2
        raise TypeError unless Node === arg1 && Node === arg2
        @left, @right = arg1, arg2
        update_size_and_depth!
      else
        if arg1
          raise unless String === arg1
          @leaf = arg1
        else
          @leaf = ""
        end
        @start = 0
        @depth = 1
      end
    end
    attr_reader :depth

    def size
      if @leaf
        [@leaf.size - @start, 0].max
      else
        @size
      end
    end

    def empty?
      if @leaf
        @start >= @leaf.size
      else
        @size == 0
      end
    end

    def shift!(n=1)
      return nil if empty?
      if @leaf
        ret = @leaf[@start, n]
        @start += n
        ret
      else
        l_shift = [n, @left.size].min
        r_shift = n - @left.size

        ret = @left.shift(l_shift) || ""
        ret.concat @right.shift(r_shift) if r_shift >= 0

        update_size_and_depth!

        ret
      end
    end
    alias shift shift!

    def update_size_and_depth!
      if @leaf
        # do nothing
      else
        @size = @left.size + @right.size
        @depth = [@left.depth, @right.depth].max + 1
      end
    end

    def remove_empty_leaf
      if @leaf
        self
      else
        if @left.empty? 
          @right.remove_empty_leaf
        else
          self
        end
      end
    end

    def [](arg)
      case arg
      when Integer then char_at(arg)
      when Range then substr(arg)
      else raise
      end
    end

    def char_at(pos)
      if @leaf
        @leaf[@start+pos] || ""
      else
        if pos < @left.size
          @left.char_at(pos)
        else
          @right.char_at(pos - @left.size)
        end
      end
    end

    def substr(range)
      raise unless range.exclude_end?
      
      from, to = range.begin, range.end
      if @leaf
        Rope.new(@leaf[(@start + from)...(@start + to)])
      else
        case
        when to < @left.size
          @left.substr(from...to)
        when @left.size < from
          @right.substr((from-@left.size)...(to-@left.size))
        else
          Rope.new(@left.substr(from...@left.size).node,
                   @right.substr(0...(to-@left.size)).node)
        end
      end
    end

    def index(str, pos)
      if @leaf
        #     |  pos
        # |        found_pos
        # |___ABCDEstrFGHI|
        # |   @start
        #     |       ret
        found_pos = @leaf.index(str, @start + pos)
        if found_pos
          found_pos + str.size - @start
        else
          nil
        end
      else
        unless @left.size <= pos
          # Need to search @left
          if (found = @left.index(str, pos))
            return found
          else
            #       str        <- we already know this never happens
            #        st   r
            #         s   tr
            #             str  <- we can use @right.index
            # |aabbcc??| |??ffgghh|
            # left       right
            start = @left.size - str.size
            str.size.times{|k|
              if start + k >= 0
                s = enum_from(start + k).take(str.size).join
                return start + k + str.size if s == str
              end
            }
          end
        end
        if (found_pos = @right.index(str, 0))
          @left.size + found_pos
        else
          nil
        end
      end

#      enum_from(pos).each.with_index{|c, i|
#        return pos+i+str.size if enum_from(pos+i).take(str.size).join == str
#      }
#      return nil
    end
    #prof :index, start: true, when: ->{ Endo::DNA.iteration >= 400 }

    def +(other_rope)
      raise TypeError unless Rope === other_rope
      case
      when self.empty?
        other_rope
      when other_rope.empty?
        Rope.new(self)
      else
        Rope.new(self, other_rope.node)
      end
    end

    def to_s
      if @leaf
        @leaf[@start..-1] || ""
      else
        @left.to_s.concat(@right.to_s)
      end
    end

    def inspect
      if size < 80
        "#<#{to_s.inspect}>"
      else
        "#<#{substr(0...10)}..(#{size})>"
      end
    end

    def tree
      if @leaf
        inspect
      else
        "#<N#{@left.tree}, #{@right.tree}>"
      end
    end

    # yields String
    def enum_from(pos)
      raise ArgumentError if pos < 0
      Enumerator.new{|y|
        if @leaf
          (@start+pos).upto(@leaf.size-1).each do |i|
            y << @leaf[i]
          end
        else
          if pos < @left.size
            @left.enum_from(pos).each{|c| y << c}
            @right.enum_from(0).each{|c| y << c}
          else
            @right.enum_from(pos-@left.size).each{|c| y << c}
          end
        end
      }
    end

    def each_char
      enum_from(0)
    end
  end
end
