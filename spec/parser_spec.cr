require "./spec_helper"

alias P = Parser

describe Parser do
    describe "character" do
        it "should parse a character literal" do
            p = P.char 'a'
            (p.parse "abcd").should eq 'a'
        end
    end

    describe "composite parsers" do
        it "should parse many digits followed by 'a' or 'b'" do
            p = P.many(P.digit).fby(P.char('a').or P.char 'b').apply{|tup| tup[0] << tup[1]}
            (p.parse "123b").should eq ['1', '2', '3', 'b']
        end

        it "should parse an integer" do
            p = P.many1(P.digit).apply{|l| l.join.to_i}
            (p.parse "1234").should eq 1234
        end

        it "should parse everything before ':'" do
            p = (P.many P.not_in("|,:")).apply{|l| l.join()}
            (p.parse "abc123:hgohqog").should eq "abc123"
        end
    end

    describe "error reporting" do
        it "should raise an exception with the right name" do
            expect_raises(ParseError, "at 4: expected integer") do
                integer = (P.many1 P.digit).set_name("integer").apply{ | l | l.join }.set_name "integer"
                integer.fby(P.whitespace).fby(integer).fby(P.char 'P').parse "123 fP"
            end
        end
    end
end