--[[
@func:	typecheck
--------------------
@desc:	
	asser the input type
@param:	
_value:
_type:	same as type output
_head
@return:
	null
--]]
local function typecheck(_value, _type, _head, lv)
	--[[
	-- check the input _type, I think that code should not be emploied
	-- We should judge by ourself
	if type(_type) ~= "string" then
		error("typecheck got _type expect string", 2)
	end
	--]]

	local head = _head and tostring(_head) .. ":" or ""
	

	if(type(_value) ~= _type) then
		error(string.format("%s expect %s, got %s",
		head, _type, type(_value)), tonumber(lv) or 2)
	end
end


--[[
@func:	unpack
--------------------
@desc:	
	a unpack function to adapt to LUA_VERSION < VERSION(5.3.x)
@param:	
pattern:
@return:
	return ...
--]]
local unpack = table.unpack or function (_table, from, to)
	typecheck(_table, "table", "unpack")

	local from = tonumber(from) or 1
	local to = tonumber(to) or #_table
	local j = from - 1

	local function upk(t)
		j = j + 1
		if #t <= 0 then
			return
		elseif j > to then
			return
		end
		return _table[j], upk(t)
	end
	return upk(_table)
end

--[[
@func:	shift
--------------------
@desc:	
	imtate bash-shift
@param:	
t:	table
times:	the shift times
@usage:	
	local a, b, c = shift(table, 3)
@return:
	return shift values(muilt-value, not in table)
--]]
local function shift(_table, times)
	typecheck(_table, "table", "shift")
	local times = tonumber(times) or 1
	local j = 0

	--[[ 
	tips:
	if you want to a function call it self(recursive), 
	you shoud define with below format
		local function xxx().............(type1)
	rather than
		local _shift = function(_t)......(type2)
	the type1 is syntactic candy, that equal to following format
		local xxx; xxx = function(xxx){...}
	--]]
	local function _shift(_t)
		j = j + 1
		if #_t <= 0 then
			return
		elseif j > times then
			return
		end
		return table.remove(_t, 1), _shift(_t)
	end

	return _shift(_table)
end

--[[
@func:	split
--------------------
@desc:	
	split with sep pattern
@param:	
string:
sep
@usage:
u1:
	local table = split("a:v:c", ":")
u2:
	string.split = utils.split
	local table = ("a:v:c"):split(":")
@return:
	arr
	nil, error
--]]
local function split(str, delimiter)
	if str == nil or str == "" or delimiter == nil then
		return nil, "error input"
	end
	local result = {}

	for match in (str..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end

	return result
end

--[[
@func:	readonly
--------------------
@desc:	
	generate a readonly table
@param:	
t:	table
@return:
	readonly-table
	nil, err
--]]
local function readonly(t)
    local proxy = {}
    local mt = {
        __index = t,
        __newindex = function (t, k, v)
            error("attemp to update a read-only table", 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy
end



return {
	split = split,
	shift = shift,
	unpack = unpack,
	readonly = readonly,
	typecheck = typecheck,
}

