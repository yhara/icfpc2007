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

class Rope
  def self.[](*args)
    new(*args)
  end

  def initialize(arg1=nil, arg2=nil)
    if arg2
      raise unless Rope === arg1 && Rope === arg2
      @left, @right = arg1, arg2
      @size = @left.size + @right.size
    else
      if arg1
        raise unless String === arg1
        @leaf = arg1
      else
        @leaf = ""
      end
      @start = 0
    end
  end

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
      shift_l = [n, @left.size].min
      shift_r = n - @left.size

      ret = @left.shift(shift_l) || ""
      ret.concat @right.shift(shift_r) if shift_r >= 0
      @size = @left.size + @right.size
      ret
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
        Rope.new(@left.substr(from...@left.size),
                 @right.substr(0...(to-@left.size)))
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
      Rope.new(self, other_rope)
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
      "#<N#{@left.inspect}, #{@right.inspect}>"
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
