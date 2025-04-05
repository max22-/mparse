class ParseContext
    getter :source
    getter :idx

    def initialize(@source : String, @idx : Int32)
    end

    def eof?
        return @idx >= @source.size
    end

    def self.advance(context : ParseContext, amount : Int32 = 1)
        ParseContext.new context.source, context.idx + amount
    end
end

class ParseResult(T)
    getter :success
    getter :value
    getter :error
    getter :context

    def initialize(@success : Bool, @value : T | Nil, @error : String | Nil, @context : ParseContext)
    end

    def self.succeed(value : T, context : ParseContext)
        ParseResult(T).new true, value, nil, context
    end

    def self.fail(error : String, context : ParseContext)
        ParseResult(T).new false, nil, error, context
    end
end

class ParseError < Exception
end

class Parser(T)
    def initialize(&block : ParseContext -> ParseResult(T))
        @block = block
    end

    def self.char(c : Char)
        Parser.new do | context |
            if context.eof?
                ParseResult(Char).fail "unexpected eof", context
            elsif context.source[context.idx] != c
                ParseResult(Char).fail "expected #{c}", context
            else
                ParseResult.new true, c, nil, ParseContext.advance context
            end
        end
    end

    def self.string(s : String)
        Parser.new do | context |
            if context.eof?
                ParseResult(String).fail "unexpected eof", context
            elsif context.source[context.idx..].starts_with? s
                ParseResult(String).succeed s, ParseContext.advance(context, s.size)
            else
                ParseResult(String).fail "expected \"#{s}\"", context
            end
        end
    end

    def self.digit
        Parser.new do | context |
            if context.eof?
                ParseResult(Char).fail "unexpected eof", context
            else
                c = context.source[context.idx]
                if c.ascii_number?
                    ParseResult(Char).succeed c, ParseContext.advance context
                else
                    ParseResult(Char).fail "expected digit", context
                end
            end
        end
    end

    def parse(source : String)
        context = ParseContext.new source, 0
        result = @block.call context
        if !result.success
            raise ParseError.new result.error
        end
        result.value
    end
end