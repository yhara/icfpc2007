# rope.rb - pure ruby Rope implementation
require 'forwardable'
require 'delegate'
require_relative "rope/node"
require_relative "rope/leaf"

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

  def_delegators :@node, :+, :to_s, :size, :length, :empty?, :each_char, :char_at, :prepend, :index, :tree, :has_empty_leaf?, :depth

  def ==(other)
    to_s == other.to_s
  end

  def [](arg1, arg2=nil)
    if arg2
      case arg1
      when Integer then @node.substr(arg1, arg2)
      when String then @node.substr_if_match(arg1)
      when Regexp then @node.regexp_matched(arg1, arg2) # arg2: nth or name
      else raise TypeError
      end
    else
      case arg1
      when Integer then @node.char_at(arg1)
      when String then @node.substr_if_match(arg1)
      when Regexp then @node.regexp_matched(arg1)
      when Range then @node.substr_range(arg1)
      else raise TypeError, "got #{arg1.inspect}"
      end
    end
  end
  alias slice []

  def prepend(other)
    case 
    when other.empty?
      # do nothing
    when @node.empty?
      @node = Rope.Node(other)
    else
      if Leaf === @node 
        @node = Node.new(Rope.Node(other), @node)
      else
        @node.prepend(other)
      end
    end
    self
  end

  def concat(other)
    case 
    when other.empty?
      # do nothing
    when @node.empty?
      @node = Rope.Node(other)
    else
      if Leaf === @node 
        @node = Node.new(@node, Rope.Node(other))
      else
        @node.concat(other)
      end
    end
    self
  end

  def shift(n=1)
    $visited = {}
    ret = @node.shift(n)
    @node = @node.remove_empty_leaf
    ret
  end

  def inspect
    if size < 80
      "#<Rope #{to_s.inspect}>"
    else
      "#<Rope #{self[0, 10].inspect}...(#{size})>"
    end
  end
end


