
module Flor

  module Lang include Raabro

    # parsing

    def ws_star(i); rex(nil, i, /[ \t]*/); end
    def retnew(i); rex(nil, i, /[\r\n]*/); end
    def dot(i); str(nil, i, '.'); end
    def colon(i); str(nil, i, ':'); end
    def comma(i); str(nil, i, ','); end

    def pstart(i); str(nil, i, '('); end
    def pend(i); str(nil, i, ')'); end
    def sbstart(i); str(nil, i, '['); end
    def sbend(i); str(nil, i, ']'); end
    def pbstart(i); str(nil, i, '{'); end
    def pbend(i); str(nil, i, '}'); end

    def null(i); str(:null, i, 'null'); end
    def number(i); rex(:number, i, /-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?/); end

    def tru(i); str(nil, i, 'true'); end
    def fls(i); str(nil, i, 'false'); end
    def boolean(i); alt(:boolean, i, :tru, :fls); end

    def rf_symbol(i); rex(nil, i, /[^.:;| \b\f\n\r\t"',()\[\]{}#\\]+/); end
    def rf_square_index(i); alt(nil, i, :rf_symbol, :dqstring, :sqstring); end
    def rf_square(i); seq(nil, i, :sbstart, :rf_square_index, :sbend); end
    def rf_dot(i); seq(nil, i, :dot, :rf_symbol); end
    def rf_index(i); alt(nil, i, :rf_dot, :rf_square); end
    def reference(i); seq(:ref, i, :rf_symbol, :rf_index, '*'); end

    def dqstring(i)

      rex(:dqstring, i, %r{
        "(
          \\["\\\/bfnrt] |
          \\u[0-9a-fA-F]{4} |
          [^"\\\b\f\n\r\t]
        )*"
      }x)
    end

    def sqstring(i)

      rex(:sqstring, i, %r{
        '(
          \\['\\\/bfnrt] |
          \\u[0-9a-fA-F]{4} |
          [^'\\\b\f\n\r\t]
        )*'
      }x)
    end

    def rxstring(i)

      rex(:rxstring, i, %r{
        /(
          \\[\/bfnrt] |
          \\u[0-9a-fA-F]{4} |
          [^/\b\f\n\r\t]
        )*/[a-z]*
      }x)
    end

    def comment(i); rex(nil, i, /#[^\r\n]*/); end

    def eol(i); seq(nil, i, :ws_star, :comment, '?', :retnew); end
    def postval(i); rep(nil, i, :eol, 0); end

    def comma_eol(i); seq(nil, i, :comma, :eol, :ws_star); end
    def sep(i); alt(nil, i, :comma_eol, :ws_star); end

    def comma_qmark_eol(i); seq(nil, i, :comma, '?', :eol); end
    def coll_sep(i); alt(nil, i, :comma_qmark_eol, :ws_star); end

    def ent(i); seq(:ent, i, :key, :postval, :colon, :postval, :exp, :postval); end
    def ent_qmark(i); rep(nil, i, :ent, 0, 1); end

    def exp_qmark(i); rep(nil, i, :exp, 0, 1); end

    def obj(i); eseq(:obj, i, :pbstart, :ent_qmark, :coll_sep, :pbend); end
    def arr(i); eseq(:arr, i, :sbstart, :exp_qmark, :coll_sep, :sbend); end

    def par(i); seq(:par, i, :pstart, :eol, :ws_star, :node, :eol, :pend); end

    def val(i)
      altg(:val, i,
        :panode, :par,
        :reference, :sqstring, :dqstring, :rxstring,
        :arr, :obj,
        :number, :boolean, :null)
    end
    def val_ws(i); seq(nil, i, :val, :ws_star); end

    # precedence
    #  %w[ or or ], %w[ and and ],
    #  %w[ equ == != <> ], %w[ lgt < > <= >= ], %w[ sum + - ], %w[ prd * / % ],

    def ssprd(i); rex(:sop, i, /[\*\/%]/); end
    def sssum(i); rex(:sop, i, /[+-]/); end
    def sslgt(i); rex(:sop, i, /(<=?|>=?)/); end
    def ssequ(i); rex(:sop, i, /(==?|!=|<>)/); end
    def ssand(i); str(:sop, i, 'and'); end
    def ssor(i); str(:sop, i, 'or'); end

    def sprd(i); seq(nil, i, :ssprd, :eol, '?'); end
    def ssum(i); seq(nil, i, :sssum, :eol, '?'); end
    def slgt(i); seq(nil, i, :sslgt, :eol, '?'); end
    def sequ(i); seq(nil, i, :ssequ, :eol, '?'); end
    def sand(i); seq(nil, i, :ssand, :eol, '?'); end
    def sor(i); seq(nil, i, :ssor, :eol, '?'); end

    def eprd(i); jseq(:exp, i, :val_ws, :sprd); end
    def esum(i); jseq(:exp, i, :eprd, :ssum); end
    def elgt(i); jseq(:exp, i, :esum, :slgt); end
    def eequ(i); jseq(:exp, i, :elgt, :sequ); end
    def eand(i); jseq(:exp, i, :eequ, :sand); end
    def eor(i); jseq(:exp, i, :eand, :sor); end

    alias exp eor

    def key(i); seq(:key, i, :exp); end
    def keycol(i); seq(nil, i, :key, :ws_star, :colon, :eol, :ws_star); end

    def att(i); seq(:att, i, :sep, :keycol, '?', :exp); end
    def head(i); seq(:head, i, :exp); end
    def indent(i); rex(:indent, i, /[ \t]*/); end
    def node(i); seq(:node, i, :indent, :head, :att, '*'); end

    def linjoin(i); rex(nil, i, /[ \t]*[\\|;][ \t]*/); end
    def outjnl(i); seq(nil, i, :linjoin, :comment, '?', :retnew); end
    def outnlj(i); seq(nil, i, :ws_star, :comment, '?', :retnew, :linjoin); end
    def outdent(i); alt(:outdent, i, :outjnl, :outnlj, :eol); end

    def line(i)
      seq(:line, i, :node, '?', :outdent)
    end
    def panode(i)
      seq(:panode, i, :pstart, :eol, :ws_star, :line, '*', :eol, :pend)
    end

    def flor(i); rep(:flor, i, :line, 0); end

    # rewriting

    def line_number(t)

      t.input.string[0..t.offset].scan("\n").count + 1
    end
    alias ln line_number

    def rewrite_par(t)

      Nod.new(t.lookup(:node), nil).to_a
    end

    def rewrite_ref(t); [ t.string, [], ln(t) ]; end

    UNESCAPE = {
      "'" => "'", '"' => '"', '\\' => '\\', '/' => '/',
      'b' => "\b", 'f' => "\f", 'n' => "\n", 'r' => "\r", 't' => "\t"
    }
    def restring(s)
      s.gsub(
        /\\(?:(['"\\\/bfnrt])|u([\da-fA-F]{4}))/
      ) {
        $1 ? UNESCAPE[$1] : [ "#$2".hex ].pack('U*')
      }
    end

    def rewrite_dqstring(t); [ '_dqs', restring(t.string[1..-2]), ln(t) ]; end
    def rewrite_sqstring(t); [ '_sqs', restring(t.string[1..-2]), ln(t) ]; end
    def rewrite_rxstring(t); [ '_rxs', t.string, ln(t) ]; end

    def rewrite_boolean(t); [ '_boo', t.string == 'true', line_number(t) ]; end
    def rewrite_null(t); [ '_nul', nil, line_number(t) ]; end

    def rewrite_number(t)

      s = t.string; [ '_num', s.index('.') ? s.to_f : s.to_i, ln(t) ]
    end

    def rewrite_obj(t)

      cn =
        t.subgather(nil).inject([]) do |a, tt|
          a << rewrite(tt.c0.c0)
          a << rewrite(tt.c4)
        end
      cn = 0 if cn.empty?

      [ '_obj', cn, ln(t) ]
    end

    def rewrite_arr(t)

      cn = t.subgather(nil).collect { |n| rewrite(n) }
      cn = 0 if cn.empty?

      [ '_arr', cn, ln(t) ]
    end

    def rewrite_val(t)

      rewrite(t.c0)
    end

    def rewrite_exp(t)

      return rewrite(t.c0) if t.children.size == 1

      cn = [ rewrite(t.c0) ]
      op = t.lookup(:sop).string

      tcn = t.children[2..-1].dup

      loop do
        c = tcn.shift; break unless c
        cn << rewrite(c)
        o = tcn.shift; break unless o
        o = o.lookup(:sop).string
        next if o == op
        cn = [ [ op, cn, cn.first[2] ] ]
        op = o
      end

      if op == '-' && cn.all? { |c| c[0] == '_num' }
        op = '+'
        cn[1..-1].each { |c| c[1] = -c[1] }
      end

      [ op, cn, cn.first[2] ]
    end

    class Nod

      attr_accessor :parent, :indent
      attr_reader :children

      def initialize(tree, outdent)

        @parent = nil
        @indent = -1
        @head = 'sequence'
        @children = []
        @line = 0

        @outdent = outdent ? outdent.strip : nil
        @outdent = nil if @outdent && @outdent.size < 1

        read(tree) if tree
      end

      def append(node)

        if @outdent
          if @outdent.index('\\')
            node.indent = self.indent + 2
          elsif @outdent.index('|') || @outdent.index(';')
            node.indent = self.indent
          end
          @outdent = nil
        end

        if node.indent > self.indent
          @children << node
          node.parent = self
        else
          @parent.append(node)
        end
      end

      def to_a

        return @head if @head.is_a?(Array) && @children.empty?

        cn = @children.collect(&:to_a)

        # make sure `[ 1 2 3 ] timeout: '2h'`
        # turns into `_arr timeout: '2h'; 1 | 2 | 3`

        if (
          @head.is_a?(Array) &&
          (@head[0] == '_arr' || @head[0] == '_obj') &&
          #Flor.is_array_of_trees?(@head[1]) &&
          cn.all? { |c| c[0] == '_att' && c[1].size > 1 }
        )
          cn = @head[1] + cn
          @head = @head[0]
          att, non_att = cn.partition { |c| c[0] == '_att' }
          cn = att + non_att
        end

        # detect if/unless suffix

        atts =
          cn.inject([]) { |a, c| a << c[1] if c[0] == '_att'; a }
        i =
          atts.index { |c|
            c.size == 1 && %w[ if unless ].include?(c[0][0]) && c[0][1] == []
          }

        return [ @head, cn, @line ] unless i

        # rewrite if/unless suffix

        t = [ atts[i][0][0] == 'if' ? 'if' : 'unless', [], @line ]
        t[1].concat(atts[i + 1..-1].collect(&:first))

        cn0i = cn[0, i]; if Flor.is_tree?(@head) && cn0i == []
          t[1].push(@head)
        else
          t[1].push([ @head, cn0i, @line ])
        end

        t
      end

      protected

      def read(tree)

        #if it = tree.lookup(:indent)
        #  #s = it.string
        #  #semicount = s.count(';')
        #  #pipe = s.index('|')
        #  #
        #  #@indent =
        #  #  if semicount == 1 then :east
        #  #  elsif semicount > 1 || pipe then :south
        #  #  else s.length; end
        #end
        @indent = tree.lookup(:indent).string.length

        ht = tree.lookup(:head)
        @line = Flor::Lang.line_number(ht)

        @head = Flor::Lang.rewrite(ht.c0)
        @head = @head[0] if @head[0].is_a?(String) && @head[1] == []

        atts =
          tree.children[2..-1].inject([]) do |as, ct|

            kt = ct.children.size == 3 ? ct.children[1].lookup(:key) : nil
            v = Flor::Lang.rewrite(ct.clast)

            if kt
              k = Flor::Lang.rewrite(kt.c0)
              as << [ '_att', [ k, v ], k[2] ]
            elsif %w[ - + ].include?(@head) && v[0, 2] != [ '_', [] ]
              if v[0] == '+'
                as.concat(v[1])
              else
                as << v
              end
            else
              as << [ '_att', [ v ], v[2] ]
            end

            as
          end

        @children.concat(atts)
      end
    end

    def rewrite_flor(t)

      prev = root = Nod.new(nil, nil)

      #t.gather(:node).each do |nt|
      t.gather(:line).each do |lt|
        nt = lt.lookup(:node); next unless nt
        ot = lt.lookup(:outdent).string
        n = Nod.new(nt, ot)
        prev.append(n)
        prev = n
      end

      root.children.count == 1 ? root.children.first.to_a : root.to_a
    end
    alias rewrite_panode rewrite_flor

    def parse(input, fname=nil, opts={})

      opts = fname if fname.is_a?(Hash) && opts.empty?

      #Raabro.pp(super(input, debug: 2))
      #Raabro.pp(super(input, debug: 3))

      r = super(input, opts)
      r << fname if fname

      r
    end
  end # module Lang

  def self.unescape_u(cs)

    s = ''; 4.times { s << cs.next }

    [ s.to_i(16) ].pack('U*')
  end

  def self.unescape(s)

    sio = StringIO.new

    cs = s.each_char

    loop do

      c = cs.next

      break unless c

      if c == '\\'
        case cn = cs.next
          when 'u' then sio.print(unescape_u(cs))
          when '\\', '"', '\'' then sio.print(cn)
          when 'b' then sio.print("\b")
          when 'f' then sio.print("\f")
          when 'n' then sio.print("\n")
          when 'r' then sio.print("\r")
          when 't' then sio.print("\t")
          else sio.print("\\#{cn}")
        end
      else
        sio.print(c)
      end
    end

    sio.string
  end
end

