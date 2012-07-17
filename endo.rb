require 'progressbar'
require_relative "lib/rope.rb"
# endo.rb
=begin
DNA ==(execute)=> RNA ==(build)=> image

DNA ::= (I|C|F|P)*
RNA ::= DNA*

# Note: xs[m..n] means Ruby's xs[m...n] 
=end

module Endo
  class DNA
    def initialize(dna)
      $pbar = ProgressBar.new("dna execute", 302450)
      @dna = dna
      def @dna.shift(n=1)
        slice!(0, n)
      end
      @rna = Object.new # $stderr #; File.open("rna.rna", "ab")
      def @rna.write(s)
        $pbar.inc(s.size)
      end
    end

    # Returns RNA
    def execute
      catch :finish do
        loop do
          pat = pattern
          tpl = template
          matchreplace(pat, tpl)
        end
      end
    end

    def pattern()
      p = []
      lvl = 0
      case @dna.shift
      when "C" then p << :I
      when "F" then p << :C
      when "P" then p << :F
      when "I"
        case @dna.shift
        when "C" then p << :P
        when "P" then p << ["!", nat()]
        when "F" then p << ["?", consts()]; @dna.shift
        when "I"
          case @dna.shift
          when "P"      then lvl+=1; p << "("
          when "C", "F"
            if lvl == 0 then return p
            else lvl -= 1; p << ")"
            end
          when "I"
            @rna.write(@dna.shift(7))
          when nil then throw :finish
          else raise
          end
        when nil then throw :finish
        else raise
        end
      when nil then throw :finish
      else raise
      end
    end

    def nat
      case @dna.shift
      when "P"      then 0
      when "I", "F" then 2 * nat
      when "C"      then 2 * nat + 1
      when nil      then nil
      else raise
      end
    end

    def consts
      ret = ""
      loop do  
        case @dna.shift
        when "C" then ret << "I"
        when "F" then ret << "C"
        when "P" then ret << "F"
        when "I"
          if @dna[0] == "C"
            @dna.shift
            ret << "P"
          end
        end
      end
      ret
    end

    def template
      t = []
      loop do
        case @dna.shift
        when "C" then t << :I
        when "F" then t << :C
        when "P" then t << :F
        when "I"
          case @dna.shift
          when "C" then t << :P
          when "F", "P" then t << [nat, nat] # Note: this is [l, n]
          when "I"
            case @dna.shift
            when "C", "F" then
              return t
            when "P" then t << [:abs, nat]
            when "I"
              @rna.write(@dna.shift(7))
            when nil then throw :finish
            else raise
            end
          when nil then throw :finish
          else raise
          end
        when nil then throw :finish
        else raise
        end
      end
    end

    def matchreplace(pat, t)
      i = 0
      e = ""
      c = []
      pat.each do |b|
        case b
        when ["!", n]
          i+=n
          return if i > @dna.size
        when ["?", s]
          if (n = @dna.match_from?(i, s)) then i = n
          else return
          end
        when "("
          c.unshift i
        when ")"
          e.concat(@dna[c[0]...i])
          c.shift
        else
          if @dna[i] == b.to_s then i+=1
          else return
          end
        end
      end
      @dna.shift(i)
      replace(t, e)
    end

    def replace(tpl, e)
      r = ""
      tpl.each do |b|
        case b
        when Array
          if b[0] == :abs
            n = b[1]
            r.concat asnat(len(e[n]))
          else
            l, n = *b
            r.concat protect(l, e[n])
          end
        else
          r << b.to_s
        end
      end
      @dna.prepend(r)
    end

    def protect(l, d)
      ret = d
      l.times{ ret = quote(ret)}
      ret
    end

    QUOTES = {"I" => "C", "C" => "F", "F" => "P", "P" => "IC"}
    def quote(dna)
      dna.chars.map{|c| QUOTES[c]}.join
    end

    def asnat(n)
      ret = ""
      while n > 0
        ret << (if n.even? then "I" else "C" end)
        n /= 2
      end
      ret << "P"
      ret
    end
  end

  # Returns image
  def build(rna)
  end
end

dna = Endo::DNA.new(File.read("endo.dna"))
dna.execute
