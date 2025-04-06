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

p6 = ((P.many1 P.digit)>>(P.many(P.char 'a'))).fby(P.many1 P.digit)
puts p6.parse "123a456"

symbol = (P.whitespace >> P.many1 P.not_in "|:,").apply{ | l | l.join().strip() }.set_name "symbol"
stack = (symbol << P.char ':').set_name "stack"
puts (stack.parse "  abc :").inspect

integer = (P.whitespace >> P.many1 P.digit).set_name "integer"
comma = P.whitespace >> P.char ','
list_of_integers = (P.char '[').fby(integer.sep_by comma).fby P.char ']'
puts list_of_integers.parse "[1, 2, 3]"