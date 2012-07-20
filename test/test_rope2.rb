require_relative "../lib/rope2.rb"
require 'test-unit'

class TestRope2 < Test::Unit::TestCase
  def test_size
    assert_equal 0, Rope[""].size
    assert_equal 1, Rope["a"].size

    assert_equal 2, Rope[Rope["a"], Rope["b"]].size
    assert_equal 4, Rope[ Rope[Rope["a"], Rope["b"]],
                          Rope[Rope["a"], Rope["b"]] ].size
    
    r = Rope["a"]; r.shift(1)
    assert_equal 0, r.size
    r = Rope["a"]; r.shift(2)
    assert_equal 0, r.size

    r = Rope[Rope["a"], Rope["b"]]; r.shift(2)
    assert_equal 0, r.size
    r = Rope[Rope["a"], Rope["b"]]; r.shift(3)
    assert_equal 0, r.size
    r = Rope[Rope["a"], Rope["b"]]; r.shift(1)
    assert_equal 1, r.size
  end

  def test_depth
    assert_equal 1, Rope["a"].depth
    assert_equal 2, Rope[Rope["a"], Rope["b"]].depth
    assert_equal 3, Rope[ Rope[Rope["a"], Rope["b"]],
                          Rope[Rope["a"], Rope["b"]] ].depth
  end

  def test_empty
    assert !Rope["a"].empty?
    assert !Rope[Rope["a"], Rope["b"]].empty?
    assert !Rope[Rope[""], Rope["b"]].empty?

    assert Rope[""].empty?
    r = Rope["a"]; r.shift(9)
    assert r.empty?
    r = Rope[Rope["a"], Rope["b"]]; r.shift(2)
    assert r.empty?
  end

  def test_shift
    r = Rope["abcde"]
    assert_equal "a", r.shift
    assert_equal "bcde", r.to_s
    assert_equal "bcd", r.shift(3)
    assert_equal "e", r.to_s
    assert_equal "e", r.shift(3)
    assert_equal 0, r.size

    r = Rope[Rope["ab"], Rope["cde"]]
    assert_equal "ab", r.shift(2)
    assert_equal "cde", r.to_s

    r = Rope[Rope["ab"], Rope["cde"]]
    assert_equal "abcd", r.shift(4)
    assert_equal "e", r.to_s

    r = Rope[Rope["ab"], Rope["cde"]]
    assert_equal "abcde", r.shift(6)
    assert_equal 0, r.size
  end

#  def test_shift_removes_empty_leaf
#    r = Rope[Rope["ab"], Rope["cde"]]; r.shift(3)
#    assert_equal 2, r.size
#    assert_equal "de", r.to_s
#    assert_equal 1, r.depth
#
#    r = Rope[ Rope[Rope["a"], Rope["b"]],
#              Rope[Rope["c"], Rope["d"]] ]; r.shift(3)
#    assert_equal 1, r.size
#    assert_equal "d", r.to_s
#    assert_equal 1, r.depth
#  end

  def test_char_at
    assert_equal "b", Rope["abc"][1]
    assert_equal "b", Rope[Rope["ab"], Rope["cde"]][1]
    assert_equal "d", Rope[Rope["ab"], Rope["cde"]][3]
    assert_equal "", Rope[Rope["ab"], Rope["cde"]][6]

    r = Rope["abc"]; r.shift
    assert_equal "b", r[0]
  end

  def test_substr
    assert_equal "b", Rope["abc"][1...2].to_s
    assert_equal "b", Rope[Rope["ab"], Rope["cde"]][1...2].to_s
    assert_equal "d", Rope[Rope["ab"], Rope["cde"]][3...4].to_s
    assert_equal "bcd", Rope[Rope["ab"], Rope["cde"]][1...4].to_s

    r = Rope[Rope["ab"], Rope["cde"]]
    r.shift
    assert_equal "bc", r[0...2].to_s
    r.shift
    assert_equal "cd", r[0...2].to_s
  end

  def test_index
    assert_equal 4, Rope["abcde"].index("cd", 1)
    r = Rope["_abcde"]; r.shift
    assert_equal 5, r.index("cde", 1)

    r = Rope[Rope["_ab"], Rope["cde"]]
    r.shift
    assert_equal 4, r.index("cd", 1)
  end

  def test_enum_from
    assert_equal "abcde", Rope["abcde"].enum_from(0).to_a.join
    assert_equal "cde", Rope["abcde"].enum_from(2).to_a.join

    left = Rope["_ab"]; left.shift
    right = Rope["_cde"]; right.shift
    assert_equal "de", Rope[left, right].enum_from(3).to_a.join
  end
end
