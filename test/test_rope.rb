require_relative "../lib/rope.rb"
require 'test-unit'

class Rope
  class TestRope < Test::Unit::TestCase
    def test_initialize
      assert_nothing_raised{ Rope["foo"] }
      assert_nothing_raised{ Rope[Node.new("foo", "bar")] }
      assert_nothing_raised{ Rope[Rope["foo"]] }
      assert_raises(TypeError){ Rope[1] }
    end

    def test_plus
      assert_rope "foobar", (Rope["foo"] + "bar")
      assert_rope "foobar", (Rope["foo"] + Rope["bar"])
    end

    def test_size
      assert_equal 3, Rope["foo"].size
      assert_equal 6, Rope[Node.new("foo", "bar")].size
    end

    def test_to_s
      assert_rope "foo", Rope["foo"]
      assert_rope "foobar", Rope[Node.new("foo", "bar")]
      assert_rope "foo", Rope[Rope["foo"]]
    end

    def test_slice_char_at
      assert_equal "c", Rope["abcde"][2]
      assert_equal "c", Rope[Node.new("abc", "de")][2]
    end

    def test_slice_substr
      assert_rope "bc", Rope["abcde"][1, 2]
      assert_rope "bc", Rope[Node.new("abc", "de")][1, 2]
      assert_rope "bcd", Rope[Node.new("abc", "de")][1, 3]
      assert_rope "d", Rope[Node.new("abc", "de")][3, 1]
    end

    private

    def assert_rope(str, given)
      assert_instance_of Rope, given
      assert_equal str, given.to_s
    end

  end
end
