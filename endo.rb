#!/usr/bin/env ruby
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

$logfile = File.open("logfile.txt", "w")
$dumping_rna = false
def _log(str, newline=false)
  $logfile.write "\n" if newline && $dumping_rna
  $dumping_rna = (str[-1] != "\n" && newline == false)
  $logfile.write str
  $logfile.write "\n" if newline
end

def log(*args)
  puts args.first
  _log(*args)
end

module Endo
  class DNA
    @iteration = nil
    def self.iteration; @iteration; end
    def self.iteration=(v); @iteration=v; end

    def initialize(dna)
      #$pbar = ProgressBar.new("dna execute", 302450)
      @dna = Rope[dna]
      #@rna = StringIO.new
      #rna = File.open("rna.rna", "w")
      @rna = Object.new
      def @rna.write(s)
        log(s)
        #$pbar.inc(s.size)
      end
    end
    attr_reader :dna

    def rna
      @rna.string
    end

    # Returns RNA
    def execute(return_string=false)
      catch :finish do
        1.upto(Float::INFINITY) do |i|
          DNA.iteration = i
          log("-- iteration #{i}", true)
          pat = pattern
          log("pat: #{inspect_pattern(pat)}", true)
          tpl = template
          log("tpl: #{inspect_template(tpl)}", true)
          env = match(pat, tpl)
          if env.nil?
            log("match returned nil", true)
          else
            log("env: #{env.inspect}", true)
            replace(tpl, env)
          end
          p [:@dna, size:@dna.size, depth:@dna.depth, tree:@dna.tree]
        end
      end
      #$pbar.halt
      self
    end

    def inspect_pattern(pat)
      pat.map{|b|
        if Array === b
          case b[0]
          when "!" then "!#{b[1]}"
          when "?" then "?#{b[1]}"
          else raise
          end
        else
          b
        end
      }.join
    end

    def inspect_template(tpl)
      tpl.map{|b|
        if Array === b
          "(#{b[0]}*#{b[1]})"
        else
          b
        end
      }.join
    end

    def finish
      log("finished from: #{caller[0]}")
      throw :finish
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
            when nil then finish
            else raise
            end
          when nil then finish
          else raise
          end
        when nil then finish
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
p [:consts]
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
          else
            return ""
          end
        when nil
          return ""
        else raise
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
            when nil then finish
            else raise
            end
          when nil then finish
          else raise
          end
        when nil then finish
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
      r = []
      tpl.each do |b|
        case b
        when Array
          if b[0] == :abs
            n = b[1]
            r << asnat(env[n].size)
          else
            n, l = *b
            r << protect(l, env[n])
          end
        else
          r << b.to_s
        end
      end
      @dna.prepend(r.join)
    end

    # Returns String or Rope (when l == 0)
    QUOTES = {"I" => "C", "C" => "F", "F" => "P", "P" => "IC"}
    def protect(l, d)
      l.times{ 
        d = d.each_char.map{|c| QUOTES[c]}.join
      }
      d
    end

    # Returns String
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
  dna = Endo::DNA.new(File.read("dna.dna"))
  dna.execute
end
