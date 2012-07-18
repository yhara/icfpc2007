require_relative "../lib/rope.rb"
require 'test-unit'

class Rope
  class TestRope < Test::Unit::TestCase
    def setup
      @rope = Rope["foo"]
      @node_rope = Rope[Node["foo", "bar"]]
    end

    def test_initialize
      assert_nothing_raised{ Rope["foo"] }
      assert_nothing_raised{ Rope[Node["foo", "bar"]] }
      assert_nothing_raised{ Rope[Rope["foo"]] }
      assert_raises(TypeError){ Rope[1] }
    end

    def test_size
      assert_equal 3, Rope["foo"].size
      assert_equal 6, Rope[Node["foo", "bar"]].size
    end

    def test_to_s
      assert_rope "foo", Rope["foo"]
      assert_rope "foobar", Rope[Node["foo", "bar"]]
      assert_rope "foo", Rope[Rope["foo"]]
    end

    def test_slice_char_at
      assert_equal "c", Rope["abcde"][2]
      assert_equal "c", Rope[Node["abc", "de"]][2]
    end

    def test_slice_substr
      assert_rope "bc", Rope["abcde"][1, 2]
      assert_rope "bc", Rope[Node["abc", "de"]][1, 2]
      assert_rope "bcd", Rope[Node["abc", "de"]][1, 3]
      assert_rope "d", Rope[Node["abc", "de"]][3, 1]
    end

    def test_prepend_str
      @rope.prepend("bar")
      assert_rope "barfoo", @rope
      assert_equal 6, @rope.size
    end

    def test_prepend_rope
      @rope.prepend(Rope["bar"])
      assert_rope "barfoo", @rope
      assert_equal 6, @rope.size
    end

    def test_concat_leaf_leaf
      @rope.concat("bar")
      assert_rope "foobar", @rope
      assert_equal 6, @rope.size
    end

    def test_concat_leaf_node
      @rope.concat(Rope[Node["bar", "baz"]])
      assert_rope "foobarbaz", @rope
      assert_equal 9, @rope.size
    end

    def test_concat_node_leaf
      @node_rope.concat("baz")
      assert_rope "foobarbaz", @node_rope
      assert_equal 9, @node_rope.size
    end

    def test_concat_node_node
      @node_rope.concat(Rope[Node["bar", "baz"]])
      assert_rope "foobarbarbaz", @node_rope
      assert_equal 12, @node_rope.size
    end

    def test_shift_leaf
    end

    def test_shift_node
    end

    def test_shift_leaf_leaf
    end

    def test_shift_node_node
    end

    private

    def assert_rope(str, given)
      assert_instance_of Rope, given
      assert_equal str, given.to_s
    end

  end
end
