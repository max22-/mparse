require "./parser"

source = {{ read_file "./examples/example1.alta" }}

p = Parser.char '|'
puts p.parse source

p2 = Parser.string "|s"
puts p2.parse source

p3 = Parser.digit
puts p3.parse "123"