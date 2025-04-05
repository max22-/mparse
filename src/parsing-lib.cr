require "./parser"

source = {{ read_file "./examples/example1.alta" }}

p = Parser.char '|'
puts p.parse source

p2 = Parser.string "|s"
puts p2.parse source

p3 = Parser.many(Parser.digit).fby(Parser.char('a').or Parser.char 'b').map{|tup| tup[0] << tup[1]}
puts p3.parse "123bbc"
