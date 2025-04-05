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

    def initialize(&block : ParseContext -> ParseResult(T))
        @block = block
    end

    def self.char(c : Char)
        Parser.new do | ctx |
            if ctx.eof?
                ParseResult(Char).fail "unexpected eof", ctx
            elsif ctx.source[ctx.idx] != c
                ParseResult(Char).fail "expected #{c}", ctx
            else
                ParseResult.new true, c, nil, ParseContext.advance ctx
            end
        end
    end

    def self.string(s : String)
        Parser.new do | ctx |
            if ctx.eof?
                ParseResult(String).fail "unexpected eof", ctx
            elsif ctx.source[ctx.idx..].starts_with? s
                ParseResult(String).succeed s, ParseContext.advance(ctx, s.size)
            else
                ParseResult(String).fail "expected \"#{s}\"", ctx
            end
        end
    end

    def self.digit
        Parser.new do | ctx |
            if ctx.eof?
                ParseResult(Char).fail "unexpected eof", ctx
            else
                c = ctx.source[ctx.idx]
                if c.ascii_number?
                    ParseResult(Char).succeed c, ParseContext.advance ctx
                else
                    ParseResult(Char).fail "expected digit", ctx
                end
            end
        end
    end

    def self.many(p : Parser(X)) : Parser(Array(X)) forall X
        Parser.new do | ctx |
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

    def parse(source : String)
        ctx = ParseContext.new source, 0
        result = @block.call ctx
        if !result.success
            raise ParseError.new result.error
        end
        result.value
    end
end