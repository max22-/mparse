class ParseContext
    getter :source
    getter :idx

    def initialize(@source : String, @idx : Int32)
    end

    def eof?
        return @idx >= @source.size
    end

    def self.advance(ctx : ParseContext, amount : Int32 = 1)
        ParseContext.new ctx.source, ctx.idx + amount
    end
end

class ParseResult(T)
    getter :success
    getter :error
    getter :ctx

    def initialize(@success : Bool, @value : T | Nil, @error : String | Nil, @ctx : ParseContext)
    end

    def self.succeed(value : T, ctx : ParseContext)
        ParseResult(T).new true, value, nil, ctx
    end

    def self.fail(error : String, ctx : ParseContext)
        ParseResult(T).new false, nil, error, ctx
    end

    def value
        @value.as(T)
    end
end

class ParseError < Exception
end

class Parser(T)
    getter :block
    getter :name

    def set_name(name : String)
        @name = name
        self
    end

    def initialize(@name : String, &block : ParseContext -> ParseResult(T))
        @block = block
    end

    def self.char(c : Char)
        name = "character '#{c}'"
        Parser.new name do | ctx |
            if ctx.eof?
                ParseResult(Char).fail "unexpected eof", ctx
            elsif ctx.source[ctx.idx] != c
                ParseResult(Char).fail "expected #{name}", ctx
            else
                ParseResult(Char).succeed c, ParseContext.advance ctx
            end
        end
    end

    def self.string(s : String)
        name = "string #{s.inspect}"
        Parser.new name do | ctx |
            if ctx.eof?
                ParseResult(String).fail "unexpected eof", ctx
            elsif ctx.source[ctx.idx..].starts_with? s
                ParseResult(String).succeed s, ParseContext.advance(ctx, s.size)
            else
                ParseResult(String).fail "expected #{name}", ctx
            end
        end
    end

    def self.satisfy(&pred : Char -> Bool)
        name = "character that satisfies #{pred}"
        Parser.new name do | ctx |
            if ctx.eof?
                ParseResult(Char).fail "unexpected eof", ctx
            else
                c = ctx.source[ctx.idx]
                if pred.call c
                    ParseResult(Char).succeed c, ParseContext.advance ctx
                else
                    ParseResult(Char).fail "expected #{name}", ctx
                end
            end
        end
    end

    def self.digit
        (satisfy { | c | c.ascii_number? }).set_name("digit")
    end

    def self.alpha
        (satisfy { | c | c.ascii_letter? }).set_name("alpha")
    end

    def self.not_in(set : String)
        (satisfy { | c | !set.includes?(c) }).set_name("any character not in #{set.inspect}")
    end

    def self.many(p : Parser(X)) : Parser(Array(X)) forall X
        name = "many #{p.name}"
        Parser.new name do | ctx |
            ctx2 = ctx.dup
            result = [] of X
            loop do
                pr = p.block.call ctx2
                break if !pr.success
                result << pr.value
                ctx2 = pr.ctx
            end
            ParseResult.succeed result, ctx2
        end
    end

    def self.many1(p : Parser(X)) : Parser(Array(X)) forall X
        p.fby(Parser.many p).apply{ | tup | [tup[0]] + tup[1] }.set_name("many1 #{p.name}")
    end

    def self.not(p : Parser(X)) : Parser(Nil) forall X
        name = "not(#{p.name})"
        Parser(Nil).new name do | ctx |
            ctx2 = ctx.dup
            pr = p.block.call ctx2
            if pr.success
                ParseResult(Nil).fail "expected #{name}", ctx
            else
                ParseResult(Nil).succeed nil, ctx
            end

        end
    end

    def fby(other : Parser(X)) : Parser(Tuple(T, X)) forall X
        name = "(#{@name}) followed by (#{other.name})"
        Parser(Tuple(T, X)).new name do | ctx |
            ctx2 = ctx.dup
            pr = @block.call ctx2
            next (ParseResult({T, X}).fail "expected #{name}", ctx) if !pr.success
            ctx2 = pr.ctx
            pr_other = other.block.call ctx2
            next (ParseResult({T, X}).fail "expected #{name}", ctx) if !pr_other.success
            ctx2 = pr_other.ctx
            ParseResult.succeed({pr.value, pr_other.value}, ctx2)
        end
    end

    def <<(other : Parser(X)) : Parser(T) forall X
        fby(other).apply{ | tup | tup[0] }
    end

    def >>(other : Parser(X)) : Parser(X) forall X
        fby(other).apply{ | tup | tup[1] }
    end

    def or(other : Parser(X)) : Parser(T | X) forall X
        name = "(#{@name} or #{other.name})"
        Parser(T | X).new name do | ctx |
            ctx2 = ctx
            pr = @block.call ctx2
            next ParseResult(T | X).succeed pr.value, ctx2 if pr.success
            ctx2 = ctx
            pr_other = other.block.call ctx2
            next ParseResult(T | X).succeed pr_other.value, ctx2 if pr_other.success
            ParseResult(T | X).fail "expected #{name}", ctx
        end
    end

    def apply(&f : T -> X) : Parser(X) forall X
        Parser(X).new @name do | ctx |
            pr = @block.call ctx
            if pr.success
                ParseResult(X).succeed f.call(pr.value), pr.ctx
            else
                ParseResult(X).fail pr.error.as(String), pr.ctx
            end
        end
    end

    def parse(source : String)
        ctx = ParseContext.new source, 0
        result = @block.call ctx
        if !result.success
            raise ParseError.new result.error
        end
        result.value
    end
end