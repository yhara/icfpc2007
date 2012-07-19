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

    def test_slice_range
      assert_rope "CF", Leaf.new("CFPC").substr_range(0...2)
      assert_rope "CF", Rope["CFPC"][0...2]
    end

    # prepend

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

    # concat

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

    # shift

    def test_shift_leaf
      rope = Rope["fooo"]
      assert_equal "f", rope.shift 
      assert_equal 3, rope.size
      assert_equal "oo", rope.shift(2)
      assert_equal 1, rope.size
      assert_equal "o", rope.shift(10)
      assert_equal 0, rope.size
      assert_equal nil, rope.shift(100)
      assert_equal 0, rope.size
    end

    def test_shift_node
      rope = Rope[Node["foo", "bar"]]
      assert_equal "fo", rope.shift(2)
      assert_rope "obar", rope
      assert_equal 4, rope.size
    end

    def test_shift_node_consumed
      rope = Rope[Node["foo", "bar"]]
      assert_equal "foob", rope.shift(4)
      assert_rope "ar", rope
      assert_equal 2, rope.size
      assert_instance_of Leaf, rope.node
    end

    def test_shift_node_node
      rope = Rope[Node[Node["foo", "bar"], Node["baz", "quux"]]]
      assert_equal "foobarbazq", rope.shift(10)
      assert_rope "uux", rope
      assert_equal 3, rope.size
      assert_instance_of Leaf, rope.node
    end

    # index

    def test_index_leaf
      assert_equal 1, Rope["foo"].index("oo", 1)
      assert_equal nil, Rope["foo"].index("oop", 1)
    end
    
    def test_index_node
      rope = Rope[Node["foo", "bar"]]
      assert_equal 4, rope.index("ar", 1)
      assert_equal nil, rope.index("arc", 1)
    end

    def test_index_leaf_leaf
      rope = Rope[Node["foo", "bar"]]
      assert_equal 2, rope.index("oba", 1)
      assert_equal nil, rope.index("obb", 1)
    end

    def test_index_node_node
      rope = Rope[Node[Node["foo", "bar"], Node["baz", "quux"]]]
      assert_equal 2,   rope.index("obarbazq", 1)
      assert_equal nil, rope.index("obarbaz_", 1)
    end

    private

    def assert_rope(str, given)
      assert_instance_of Rope, given
      assert_equal str, given.to_s
    end

  end
end
