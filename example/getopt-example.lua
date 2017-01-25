--======== include and declare constant =======================================
-- local getopt = require('getopt.lua')
local LUA_GETOPT_PATH = "../?.lua;"
package.path = LUA_GETOPT_PATH .. package.path
print = require("example.color-p").print
local getopt = require("getopt")

--======== test area ===========================================================
local function empty(...)
	local args = {...}
	print(args)
	return true
end

local function def(...)
	print("def-----")
	empty(...)
end

local function f1(...)
	print("f1-----")
	empty(...)
end

local function unlmt(...)
	print(...)
end

local function initopt()
	getopt.setmain(def)
	getopt.callback("a,cc", empty)
	getopt.callback("b:R:2,3", f1)
	getopt.callback("c:U:0", unlmt)	
end


local function main(...)
	initopt()
	getopt.run(arg)
end

main(...)


