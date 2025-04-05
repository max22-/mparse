require "./parser"

source = {{ read_file "./examples/example1.alta" }}

alias P = Parser

p = P.char '|'
puts p.parse source

p2 = P.string "|s"
puts p2.parse source

p3 = P.many(P.digit).fby(P.char('a').or P.char 'b').apply{|tup| tup[0] << tup[1]}
puts p3.parse "123bbc"

p4 = P.not P.digit.fby(P.char('a'))
puts p4.parse "1b23"

p5 = (P.many P.not_in("|,:")).apply{|l| l.join()}
puts p5.parse("abc123:")