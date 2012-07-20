class Rope
  class Node
    def self.[](l, r)
      new(Rope.Node(l), Rope.Node(r))
    end

    def has_empty_leaf?
      Leaf === @left && @left.empty? or
      Leaf === @right && @right.empty? or
      @left.has_empty_leaf? or @right.has_empty_leaf?
    end

    def initialize(left, right)
      raise TypeError, "got #{left.inspect} as left" unless (Node === left || Leaf === left)
      raise TypeError, "got #{right.inspect} as right" unless (Node === right || Leaf === right)
      @left, @right = left, right
      update_size
      update_depth
    end
    attr_reader :size, :depth
    alias length size

    def update_size; @size = @left.size + @right.size; end
    def update_depth; @depth = [@left.depth, @right.depth].max + 1; end
    private :update_size, :update_depth
   
    def empty?
      @size == 0
    end

#    def +(other)
#      Rope[Node.new(@node, Rope.Node(right))]
#    end

    # Destructively prepends other to self
    def prepend(other)
      @left, @right = Rope.Node(other), Node.new(@left, @right)
      update_size
      update_depth
    end
    
    # Destructively appends other to self
    def concat(other)
      @left, @right = Node.new(@left, @right), Rope.Node(other)
      update_size
      update_depth
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
      return Rope[""] if len == 0

      nth = if _nth < 0 then (self.size + _nth) else _nth end
      return nil if nth < 0 || nth >= self.size

      from = nth
      to = [nth + len - 1, self.size - 1].min
      raise ArgumentError, "args: #{_nth}, #{len} from: #{from}, to: #{to}" if from > to

      case
      when to < @left.size
        @left.substr(from, to)
      when @left.size < from
        @right.substr(from, to)  # これバグってるじゃん…、 -@left.sizeがいる
      else
        Rope[Node[@left.substr_range(from..@left.size-1),
                  @right.substr_range(0..(to-@left.size))]]
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

    # Yields String
    def each_char_from(pos, &block)
      case
      when @left.size < pos
        @right.each_char_from(pos - @left.size, &block)
      else
        @left..char_at(nth - @left.size)
      end
      if block
        @left.each_char(&block)
        @right.each_char(&block)
      else
        Enumerator.new{|y|
          @left.each_char{|c| y << c}
          @right.each_char{|c| y << c}
        }
      end
    end

    # Destructively remove first n chars and returns a String.
    def shift(n=1)
      shift_l = [n, @left.size].min
      shift_r = n - @left.size

      ret = @left.shift(shift_l) || ""
      ret.concat @right.shift(shift_r) if shift_r >= 0
      update_size
      update_depth
      ret
    end

    # We need to cleanup empty leafs after shift
    # Returns a Node or Leaf
    def remove_empty_leaf
      case
      when @left.empty?
        @right.remove_empty_leaf
      when @right.empty?
        @left.remove_empty_leaf
      else
        self
      end
    end

    # Find first match from nth position.
    # str: String
    # Returns Integer or nil
    def index(str, pos)
      case
      when @left.size <= pos
        @right.index(str, pos - @left.size)
      when (ret = @left.index(str, pos))
        ret
      else
        self.each_char_from(pos){|c, i|
        }
        # Search is done for <= @left[]
        left_s = kkk
        left_p = pos
      end
    end

    def inspect
      "#<Node #{@left.inspect}, #{@right.inspect}>"
    end

    def tree
      "<#{@left.tree}, #{@right.tree}>"
    end

    def to_s
      @left.to_s + @right.to_s
    end
  end
end
