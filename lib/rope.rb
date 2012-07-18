# rope.rb - pure ruby Rope implementation
require 'forwardable'
require 'delegate'

# http://www.kmonos.net/wlog/39.php#_1841040529
# http://msakai.jp/d/?date=200707

# TODO: AVL木や赤黒木（Red-Black-Tree） 
class Rope
  extend Forwardable

  def self.Node(arg)
    case arg
    when String then Leaf.new(arg)
    when Node then arg
    when Rope then arg.node
    else raise TypeError
    end
  end

  def self.[](arg)
    new(arg)
  end

  def initialize(arg)
    @node = Rope.Node(arg)
  end
  attr_reader :node

  def [](arg1, arg2=nil)
    if arg2
      case arg1
      when Integer then @node.substr(arg1, arg2)
      when String then @node.substr_if_match(arg1)
      when Regexp then @node.regexp_matched(arg1, arg2) # arg2: nth or name
      when Range then @node.substr_range(arg1)
      else raise TypeError
      end
    else
      case arg1
      when Integer then @node.char_at(arg1)
      when String then @node.substr_if_match(arg1)
      when Regexp then @node.regexp_matched(arg1)
      else raise TypeError
      end
    end
  end
  alias slice []

  def_delegators :@node, :+, :to_s, :size, :length, :each_char, :shift,
    :prepend

  def prepend(other)
    if Leaf === @node 
      @node = Node.new(Rope[other], @node)
    else
      @node.prepend(other)
    end
    self
  end

  def concat(other)
    if Leaf === @node 
      @node = Node.new(@node, Rope[other])
    else
      @node.concat(other)
    end
    self
  end

  def shift(n=1)
  end

  def inspect
    "#<Rope #{to_s.inspect}>"
  end

  class Node
    def self.[](l, r)
      new(Rope.Node(l), Rope.Node(r))
    end

    def initialize(left, right)
      @left, @right = left, right
      update_size
    end
    attr_reader :size
    alias length size

    def update_size
      @size = @left.size + @right.size
    end
    private :update_size

    def +(other)
      right = case other
              when String then Leaf.new(other)
              when Rope then other.node
              else raise TypeError
              end

      Rope[Node.new(@node, right)]
    end

    # Destructively prepends other to self
    def prepend(other)
      new_left = case other
                 when String then Leaf.new(other)
                 when Rope then other.node
                 else raise TypeError
                 end

      @left = new_left
      @right = Node.new(@left, @right)
      update_size
    end
    
    # Destructively appends other to self
    def concat(other)
      new_right = case other
                  when String then Leaf.new(other)
                  when Rope then other.node
                  else raise TypeError
                  end

      @left = Node.new(@left, @right)
      @right = new_right
      update_size
    end

    # Returns String
    def char_at(_nth)
      nth = if _nth < 0 then (self.size + _nth) else _nth end
      return nil if nth < 0 || nth >= self.size

      if nth < @left.size
        @left.char_at(nth)
      else
        @right.char_at(nth - @left.size)
      end
    end

    # Returns Rope
    def substr(_nth, len)
      nth = if _nth < 0 then (self.size + _nth) else _nth end
      return nil if nth < 0 || nth >= self.size

      from = nth
      to = [nth + len - 1, self.size - 1].min
      raise ArgumentError if from > to

      case
      when to < @left.size
        @left.substr(from, to)
      when @left.size < from
        @right.substr(from, to)
      else
        Rope[Node.new(@left.substr_range(from..@left.size-1),
                      @right.substr_range(0..(to-@left.size)))]
      end
    end

    # Returns Rope
    def substr_range(range)
      # TODO: Ruby's str[range] may be more complex...
      if range.exclude_end?
        substr(range.begin, (range.end - range.begin - 1))
      else
        substr(range.begin, (range.end - range.begin))
      end
    end

#    # Yields String
#    def each_char(&block)
#      if block
#        @left.each_char(&block)
#        @right.each_char(&block)
#      else
#        Enumerator.new{|y|
#          @left.each_char{|c| y << c}
#          @right.each_char{|c| y << c}
#        }
#      end
#    end

    # Destructively remove first n chars and returns a String.
    def shift(n=1)
      
    end

    # Find first match from nth position.
    # Returns index (Integer) or nil
    def include_from?(nth, str)

    end

    def inspect
      "#<Node #{@left.inspect}, #{@right.inspect}>"
    end

    def to_s
      @left.to_s + @right.to_s
    end
  end

  class Leaf #< DelegateClass(String)
    def initialize(str)
      raise TypeError, "got #{str.inspect}" unless String === str
      @str = str
      @start = 0
    end

    def empty?
      @start >= @str.size
    end

    def size
      [@str.size - @start, 0].max
    end
    alias length size

    def shift(n=1)
      return nil if empty?

      ret = @str[@start, n]
      @start += n
      ret
    end

    def char_at(nth)
      @str[@start + nth]
    end

    def substr(nth, len)
      Rope[@str[@start + nth, len]]
    end

    def substr_range(range)
      if range.exclude_end?
        Rope[@str[(@start + range.begin) ... range.end]]
      else
        Rope[@str[(@start + range.begin) .. range.end]]
      end
    end

    def to_s
      @str[@start..-1]
    end

    def inspect
      "#<Leaf #{@str.inspect}>"
    end
  end
end
