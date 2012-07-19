require 'stringio'
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
      @dna = Rope[dna]
      #@rna = StringIO.new
      rna = File.open("rna.rna", "w")
      @rna = Object.new
      def @rna.write(s)
        $pbar.inc(s.size)
      end
    end
    attr_reader :dna

    def rna
      @rna.string
    end

    # Returns RNA
    def execute(return_string=false)
      catch :finish do
        loop do
          pat = pattern
          tpl = template
          env = match(pat, tpl)
          replace(tpl, env)
        end
      end
      $pbar.halt
      self
    end

    def pattern()
      p = []
      lvl = 0
      loop do
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
            when "P"      
              lvl += 1
              p << "("
            when "C", "F"
              if lvl == 0
                return p
              else
                lvl -= 1
                p << ")"
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
        case x = @dna.shift
        when "C" then t << :I
        when "F" then t << :C
        when "P" then t << :F
        when "I"
          case @dna.shift
          when "C" then t << :P
          when "F", "P" then l = nat; n = nat; t << [n, l]
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
        else raise "got #{x.inspect}"
        end
      end
    end

    def match(pat, t)
      i = 0
      env = []
      c = []
      pat.each do |b|
        case b
        when Array
          case b[0]
          when "!"  # skip
            n = b[1]; i += n
            return if i > @dna.size
          when "?"
            s = b[1]
            if (n = @dna.indexxx(s, i))
              i = n
            else
              return
            end
          else raise
          end
        when "("
          c.unshift i
        when ")"
          env << @dna[c[0]...i]
          c.shift
        else
          if @dna[i] == b.to_s then i+=1
          else return
          end
        end
      end
      @dna.shift(i)
      env
    end

    def replace(tpl, env)
p [:replace, tpl: tpl, env: env]
      r = Rope[""]
      tpl.each do |b|
        case b
        when Array
          if b[0] == :abs
            n = b[1]
            r.concat asnat(env[n].size)
          else
            n, l = *b
            r.concat protect(l, env[n])
          end
        else
          r.concat b.to_s
        end
      end
      @dna.prepend(r)
    end

    QUOTES = {"I" => "C", "C" => "F", "F" => "P", "P" => "IC"}
    def protect(l, d)
p [:protect, l: l, d: d]
      l.times{ 
        d = d.each_char.map{|c| QUOTES[c]}.join
      }
      d
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

if $0 == __FILE__
  dna = Endo::DNA.new(File.read("endo.dna"))
  dna.execute
end
