require 'test-unit'
require 'shoulda-context'
require "rr"
require_relative '../endo.rb'

module Endo
  class TestDNA < Test::Unit::TestCase
    include RR::Adapters::TestUnit

    context "try first example" do
      context "first match-replace" do
        def test_pattern
          assert_equal [:I], DNA.new("CIIC").pattern
          assert_equal ["(", ["!", 2], ")", :P], DNA.new("IIP IP IC P IIC IC IIF".split.join).pattern
        end

        def test_template
          assert_equal [:P, :I, [0, 0]],
            #        P  I [] 0 0 
            DNA.new("IC C IF P P IIC   C F P C".split.join).template
        end

        def test_match
          pat = ["(", ["!", 2], ")", :P]
          tpl = [:P, :I, [0, 0]]

          dna = DNA.new("CFPC")
          mock(dna.dna).shift(3)

          assert_equal [Rope["CF"]], dna.match(pat, tpl)
        end

        def test_replace
          tpl = [:P, :I, [0, 0]]
          dna = DNA.new("C")
          dna.replace(tpl, [Rope["CF"]])
          assert_equal "PICF C".split.join, dna.dna.to_s
        end
      end
    end

    def test_execute_sample1
      dna = DNA.new("IIP IP IC P IIC IC IIF IC C IF P P IIC C F P C".split.join)
      pat = dna.pattern
      assert_equal ["(", ["!", 2], ")", :P], pat
      tpl = dna.template
      assert_equal [:P, :I, [0, 0]], tpl

      env = dna.match(pat, tpl)
      assert_equal [Rope["CF"]], env

      dna.replace(tpl, env)
      assert_equal "PICFC", dna.dna.to_s
    end

    def test_execute_sample2
      dna = DNA.new("IIPIPICPIICICIIFICCIFCCCPPIICCFPC")
      pat = dna.pattern
      tpl = dna.template
      env = dna.match(pat, tpl)
      dna.replace(tpl, env)
      assert_equal "PIICCFCFFPC", dna.dna.to_s
    end

    def test_execute_sample3
                    # (  [!  4]  )       | I     |
      dna = DNA.new("IIP IP IICP IIC IIC   C IIC   FCFC".split.join)
      pat = dna.pattern
      assert_equal ["(", ["!", 4], ")"], pat
      tpl = dna.template
      assert_equal [:I], tpl
#i=4 e=["FCFC"[0...4] == ] c=[0, ]
      env = dna.match(pat, tpl)
      assert_equal [Rope["FCFC"]], env
      dna.replace(tpl, env)
      assert_equal "I", dna.dna.to_s

      assert_equal "I", DNA.new("IIP IP IICP IIC IIC   C IIC   FCFC".split.join).execute.dna.to_s
    end
  end
end
