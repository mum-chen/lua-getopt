--[[
@auth   mum-chen
@desc   a cmd tool to simplize the 
@init   2016 12 25
--]]
--======== include and extern variable & function ============================
local utils = require("utils")
local config = require("config")

local split = utils.split
local unpack = utils.unpack

-- config
local REDUNDANCY = config.redundancy
local OPT_MODE = config.mode
--======== inner function define ===============================================

--------------------------------------------------------------------------------
-- DEFAULT ERROR FUNCTION(param from command-line)
--------------------------------------------------------------------------------
local function _lakeparams(cmd, expect, fact)
	local pattern = "cmd:%s expect got %d params, only got %d"
	local err = pattern:format(cmd, expect, fact)
	print(err)
	return false, err
end

local function _unimplemented(cmd)
	local err = "the cmd:" .. cmd .. " you input is unimplemented"
	print(err)
	return false, err
end

local function _default(args)
	--[[ error example
	local err = "the input args don't have option"
	print(err)
	return false, err
	--]]
	return true
end

local function _errinput(err)
	print(err)
	return false
end

local function _empty()
	return true
end

local function usage_default()
	local usage = [[
	    setdefault(func, D|U|L|E),
	    U: set the unimplemented function,
	       which called when unimplemented-cmd input
	       function _unimplemented(cmd)

	    L: set the lakeparams function,
	       which called when the necessary param requirement could't meet
	       function _lakeparams(cmd, expect, fact)

	    D: set the default function,
	       which called when the param with null-cmd
	       function default(pattern, func)

	    E: set the errinput function,
	       which called when the error-opt input
	       function _errinput(err)
	]]
	print(usage)
	return usage
end

local function default(pattern, func)
	if "D" == pattern then
		_default = func
	elseif "U" == pattern then

	elseif "E" == pattern then

	elseif "L" == pattern then
		
	else
		usage_default()
		error("error pattern:" .. pattern)
	end

	return true
end
--------------------------------------------------------------------------------
-- CALL BACK(param from code) 
--------------------------------------------------------------------------------

---------- callback item ---------------
local cbitem = {
	f = nil,	-- item callback
	b = nil,	-- begin number(0~n)
	e = nil,	-- end number(0~n, INFINITE)
	INFINITE = -1,
}

function cbitem:new(f, b, e)
	b = tonumber(b)
	e = tonumber(e)
	if not ( b and e) then
		error("the begin and end expect number type")
	end

	local item = {
		f = f;
		b = b;
		e = e;
	}

	setmetatable(item, {__index = self})
	return item
end

function cbitem:isinf()
	return self.e == self.INFINITE
end

function cbitem.new_range(f, b, e)
	assert(b <= e, "begin must small than end")
	return cbitem:new(f, b, e)
end

function cbitem.new_limit(f,e)
	return cbitem:new(f,0,e)
end

function cbitem.new_necessary(f,num)
	return cbitem:new(f, num, num)
end

function cbitem.new_unlimit(f,b)
	return cbitem:new(f, b, self.INFINITE)
end

function cbitem.new_unnecessary(f)
	return cbitem:new(f, 0, 0)
end

function cbitem.get_newfunc(tag)
	if tag == nil then
		return cbitem.new_unnecessary
	elseif tag == "U" then
		return cbitem.new_unlimit
	elseif tag == "N" then
		return cbitem.new_necessary
	elseif tag == "R" then
		return cbitem.new_range
	elseif tag == "L" then
		return cbitem.new_limit
	else
		error("error tag"..tostring(tag))
	end
end

---------- callback map ----------------
local cbmap = {}

local function _set_cbmap(name, item)
	cbmap[name] = item
end

local function __get_cbmap(name)
	return cbmap[name]
end

--[[
pattern:
	short_cmd[ ,long_cmd ][ :type:num1[,num2] ]
	type:N, L, U, R
example:
	s,t,help:R:1,2
--]]
local function unravel_pattern(pattern)
	local temp = split(pattern, ":")
	if (not temp) or (#temp == 0) then
		error("unravel pattern error: option")
	end

	local opts = temp[1]
	local tag = temp[2]
	local num = temp[3]

	local opt_table = split(opts, ",")
	if not tag then
		return opt_table
	end

	local num_table = split(num, ",")

	if (not num_table) or (#num_table == 0) then
		error("unravel pattern error: number")
	end
	
	return opt_table, tag, num_table[1], num_table[2]
end

local function set_cbmap(pattern, func)
	assert(type(pattern) == "string", "pattern input not a string")
	assert(type(func) == "function", "item call back expect a function")
	-- unravel pattern
	local opt_table, tag, num1, num2 = unravel_pattern(pattern)
	
	local newfunc = cbitem.get_newfunc(tag)
	
	for _, opt in pairs(opt_table) do
		local item = newfunc(func, num1, num2)
		_set_cbmap(opt, item)
	end
end

local function usage_callback()
	local usage = [[
	pattern:
		short_cmd[ ,long_cmd ][ :type:num1[,num2] ]
	type:N, L, U, R
	R:range,     "R:1,3", from 1 to 3
	N:necessary, "N:2",   from 2 to 2
	U:unlimited, "U:3",   from 3 to unlimited
	L:limited,   "L:3",   from 1 to 3
	default,     "N:0",   from 0 to 0
	
	example:
		s,t,help:R:1,2
		"a" same as "a:N:0"
	]]
	print(usage)
	return usage
end

--------------------------------------------------------------------------------
-- INPUT(param from command-line)
--------------------------------------------------------------------------------

---------- input item ------------------
local initem = {
	param = nil,
}

function initem:new()
	local item = {
		param = {},
	}

	setmetatable(item, {__index = self})
	return item
end

function initem:add(param)
	table.insert(self.param, param)
end

function initem:unpack(from, to)
	return unpack(self.param, from, to)
end

function initem:getparam()
	return self.param
end

function initem:number()
	return #self.param
end

---------- input map -------------------
local inmap = {}

local function __set_inmap(name, param)
	if not inmap[name] then
		inmap[name] = initem:new()
	end

	inmap[name]:add(param)
end

local function __remove_inmap(name)
	inmap[name] = nil
end

local function input_type(param)
	local prefix, word = string.match(param, "(%-*)(.*)")
	if "" == prefix then
		return "P", param				-- param
	elseif #prefix == 1 then
		if "" == word then
			return "E", "null short opt:" .. param	-- error
		elseif #word == 1 then
			return "S", word			-- short
		else
			return "C", word			-- combine
		end
	elseif #prefix == 2 then
		if "" == word then
			return "B", ""				-- blank
		else
			return "L", word			-- long
		end
	else
		return "E", "error prefix:" .. param		-- error
	end
end


--[[
return  tag, index, pararm, ori_param
such as "L", 1, abbr, --abbr
--]]
local function foreach_input(args)
	local idx = 1
	local args = args

	local isbank = false

	return function()
		local tag, _param, param, _idx

		repeat
			_idx = idx
			idx = idx + 1

			param = args[_idx]
			if not param then
				return nil, _idx, param, param
			end

			if isbank then
				return "P", _idx, param, param
			end

			tag, _param = input_type(param)

			if "B" == tag then
				isbank = true
			elseif "E" == tag then
				local ret = _errinput(_param)
				local _ = (not ret) and os.exit(1)
			end
			-- case "E" loop, else return
		until ("E" ~= tag )

		return tag, _idx, _param, param
	end
end

-- consider all opt is long-opt
local function prefix_input(args)
	local _args = {}
	for t, i, p, ori_p in foreach_input(args) do
		local _p = p
		if ("L" == t) or ("S" == t) or ("C" == t ) then
			_p = "--" .. _p
		end
		
		table.insert(_args, ori_p)
	end

	return _args
end

--[[
  unravel combine short opt,e.g. -abc to -a -b -c
--]]
local function unravel_input(args)
	local _args = {}
	for t, i, p, ori_p in foreach_input(args) do
		if "C" == t then
			for word in p:gmatch("%w") do
				table.insert(_args, "-" .. word)
			end
		else
			table.insert(_args, ori_p)
		end
	end

	return _args
end

local function convert_input(args)
	local covert_args = nil

	if (OPT_MODE == "strict") or (OPT_MODE == "S") then
		covert_args = prefix_input
	else	-- normal mode
		covert_args = unravel_input
	end

	return covert_args(args)
end

local function set_inmap(args)
	local opt = ""

	for t, i, p in foreach_input(args) do
		if (t == "S") or (t == "L" ) or (t == "B")then
			opt = p
			__set_inmap(opt)
		elseif (t == "E") or (t == "C") then
			error("system error")
		else -- case t == param
			__set_inmap(opt, p)
		end
	end
end


local function _union(target, src)
	for _, v in ipairs(src) do
		target:add(v)
	end
end

local function union(target, src)
	_union(target, src:getparam())
end

local function add(target, ...)
	local args = {...}
	_union(target, {...})
end

local function _validate_opt(redundancy)
	for k, input in pairs(inmap) do
		local cbitem = __get_cbmap(k)
		if not cbitem then
			local ret = _unimplemented(k)
			local _ = (not ret) and os.exit(1)

			union(redundancy, input)
			__remove_inmap(k)
		end
	end
end

local function _callback(redundancy)
	for k, input in pairs(inmap) do
		local cbitem = __get_cbmap(k)
		local num = input:number()

		if num < cbitem.b then
			local ret = _lakeparams(k, cbitem.b, num)
			local _ = (not ret) and os.exit(1)
			union(redundancy, input)
		elseif num > cbitem.e then
			cbitem.f(input:unpack(1, cbitem.e))
			add(redundancy, input:unpack(cbitem.e + 1))
		else
			cbitem.f(input:unpack())
		end
	end
end

local function callback()
	local blank = inmap[""] or initem:new()
	inmap[""] = nil
	local redundancy = initem:new()

	_validate_opt(redundancy)
	_callback(redundancy)

	if REDUNDANCY then
		union(blank, redundancy)
	end

	_default(blank:unpack())
end

---------- run server ------------------
local function run(args)
	local _args = convert_input(args)
	set_inmap(_args)
	callback()
end

--======== return package ====================================================
return {
	run = run,
	default = default,
	callback = set_cbmap,
	usage_default = usage_default,
	usage_callback = usage_callback,
}
