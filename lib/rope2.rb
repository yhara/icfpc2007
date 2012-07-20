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
      raise TypeError unless String === arg1
      @node = Node.new(arg1)
    end
  end
  attr_reader :node

  def_delegators :@node, :size, :depth, :empty?, :shift,
    :[], :index, :+, :to_s, :enum_from, :each_char

  def inspect
    "#<Rope #{@node.inspect}>"
  end

  def tree
    "#<Rope #{@node.tree}>"
  end

  class Node
    def initialize(arg1=nil, arg2=nil)
      if arg2
        raise TypeError unless Node === arg1 && Node === arg2
        @left, @right = arg1, arg2
        @size = @left.size + @right.size
        @depth = [@left.depth, @right.depth].max + 1
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

    def shift(n=1)
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

#        if @left.empty?
#          @left, @right = new_left, new_right
#        end
        @size = @left.size + @right.size
        @depth = [@left.depth, @right.depth].max + 1

        ret
      end
    end

    def become_node(new_left, new_right)

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
      # TODO: 遅いかも
      enum_from(pos).each.with_index{|c, i|
        return pos+i+str.size if enum_from(pos+i).take(str.size).join == str
      }
      return nil
    end

    def +(other_rope)
      case
      when self.empty?
        other_rope
      when other_rope.empty?
        self
      else
        Rope.new(self.node, other_rope.node)
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
      Enumerator.new{|y|
        if @leaf
          (@start+pos).upto(@leaf.size-1).each do |i|
            y << @leaf[i]
          end
        else
          @left.enum_from(pos).each{|c| y << c}
          @right.enum_from(pos-@left.size).each{|c| y << c}
        end
      }
    end

    def each_char
      enum_from(0)
    end
  end
end
