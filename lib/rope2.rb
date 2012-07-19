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
  def initialize(arg1=nil, arg2=nil)
    if arg2
      raise unless Rope === arg1 && Rope === arg2
      @left, @right = arg1, arg2
      @size = @left + @right
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
    when Integer
      enum_from(arg).each{|c| return c}
    when Range
      raise unless arg.exclude_end?
      # Note: we can't use enum_from because of rope[0...7509409] called
p [:slice_range, arg, arg.end-arg.begin]
      # TODO: rangeの範囲が大きいと問題があるかも
      return enum_from(arg.begin).with_index.inject(""){|s, (c, i)|
        return s if (arg.begin+i) == arg.end
        s << c
        s
      }
    else
      raise
    end
  end

  def index(str, pos)
    # TODO: 遅いかも
    enum_from(pos).each.with_index{|c, i|
      return i if enum_from(pos+i).take(str.size).join == str
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
    enum_from(0).to_a.join
  end

  # yields String
  def enum_from(pos)
    Enumerator.new{|y|
      if @leaf
        (@start+pos).upto(@leaf.size-1).each do |i|
          y << @leaf[i]
        end
      else
        @left.enum_from(pos){|c| y << c}
        @right.enum_from(pos-@left.size){|c| y << c}
      end
    }
  end
end
