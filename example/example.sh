echo "config
	getopt.default("D", def)
	getopt.callback("a,cc", empty)
	getopt.callback("b:R:2,3", f1)"
echo "fine example"
echo "lua getopt-example.lua 1 2 3 -ab 6 7 8 9 10"
lua getopt-example.lua 1 2 3 -ab 6 7 8 9 10

echo
echo "less than 2 args in b"
echo "lua getopt-example.lua 1 2 3 -ab 6"
lua getopt-example.lua 1 2 3 -ab 6

echo
echo "undefine d"
echo "lua getopt-example.lua 1 2 3 -ab 6 10 -d "
lua getopt-example.lua 1 2 3 -ab 6 10 -d
