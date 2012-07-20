class Rope
  class Leaf
    def initialize(str)
      raise TypeError, "got #{str.inspect}" unless String === str
      @str = str
      @start = 0
    end

    def empty?
      @start >= @str.size
    end
    alias has_empty_leaf? empty?

    def each_char_from(&block)
      @str.each_char.drop(@start).each(&block)
    end

    def size
      [@str.size - @start, 0].max
    end
    alias length size

    def depth
      1
    end

    def shift(n=1)
      return nil if empty?

      ret = @str[@start, n]
      @start += n
      ret
    end

    def remove_empty_leaf
      self
    end

    def index(str, pos)
      @str.index(str, @start + pos)
    end

    def char_at(nth)
      @str[@start + nth]
    end

    def substr(nth, len)
      Rope[@str[@start + nth, len]]
    end

    def substr_range(range)
      if range.exclude_end?
        Rope[@str[(@start + range.begin) ... (@start + range.end)]]
      else
        Rope[@str[(@start + range.begin) .. (@start + range.end)]]
      end
    end

    def to_s
      @str[@start..-1]
    end

    def inspect
      if size < 80
        "#<Leaf #{to_s} (#{@str}/#{@start})>"
      else
        "#<Leaf #{to_s[0,10]}...(#{@start}/#{@str.size})>"
      end
    end

    def tree
      if size < 80
        "<#{to_s}(#{@start})>"
      else
        "<#{@str[@start,10]}...(#{size}, #{@start})>"
      end
    end
  end
end
