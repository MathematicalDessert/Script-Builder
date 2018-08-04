-- Licensed under the MIT license
-- Copyright (C) 2015 DigiTechs

local setmetatable = setmetatable
local getmetatable = getmetatable
local ipairs = ipairs
local assert = assert
local type = type
local format = string.format
local sort = table.sort

local _M = { }

local function new(tab)
	return setmetatable(tab, {__index=_M})
end

local function DefaultSortDescending(one, two)
	return two < one
end

local function DefaultCheck(one, two)
	if type(one) == "table" and type(two) == "table" then
		local contentmatches = true
		for i, v in next, one do
			if two[i] ~= v then
				contentmatches = false
			end
		end
		return contentmatches
	else
		return one == two
	end
end

local function checktype(obj, typ, paramid)
	if type(typ) == "table" then
		local matchtype = false
		for i = 1, #typ do
			if type(obj) == typ[i] then
				matchtype = true
				break
			end
		end
		if not matchtype then
			error(
				paramid and format("parameter #%s must be of type %s!", paramid, typ[1]) or 
				format("parameter `%s` must be of type %s", tostring(obj), typ[1]),
				3
			)
		end
	else
		if type(obj)~=typ then
			error( 
				paramid and format("parameter #%s must be of type %s!", paramid, typ) or 
				format("parameter `%s` must be of type %s", tostring(obj), typ),
				3
			)
		end
	end
end
--module("lunq")

local function Zip(t1, t2, f)
	checktype(t1, "table", 1)
	checktype(t2, "table", 2)
	checktype(f, "function", 3)
	local ret = { }
	if #t2 >= #t1 then
		for i, v in ipairs(t2) do
			ret[#ret+1] = f(v, t1[i])
		end
	end
	return new(ret)
end

local function Where(t1, f)
	checktype(t1, "table", 1)
	checktype(f, "function", 2)
	local ret = { }
	for i, v in ipairs(t1) do
		if f(v, i) then
			ret[#ret+1] = v
		end
	end
	return new(ret)
end

local function Union(t1, t2, f)
	checktype(t1, "table", 1)
	checktype(t2, "table", 2)
	checktype(f, {"function", "nil"}, 3)
	local ret = { }
	for i, v in ipairs(t1) do
		for ii, vv in ipairs(t2) do
			if type(f) == "nil" then
				if DefaultCheck(v, vv) then
					ret[#ret+1] = v
				end
			elseif f(v, vv) then
				ret[#ret+1] = v
			end
		end
	end
	return new(ret)
end

local function TakeWhile(t1, f)
	checktype(t1, "table", 1)
	checktype(f, "function", 2)
	local ret = { }
	for i, v in ipairs(t1) do
		if f(v, i) then
			ret[#ret+1] = v
		else
			break
		end
	end
	return new(ret)
end
local function Take(t1, n)
	checktype(t1, "table", 1)
	checktype(n, "number", 2)
	local ret = { }
	for i, v in ipairs(t1) do
		if i <= n then
			ret[#ret+1] = v
		else
			break
		end
	end
	return new(ret)
end

local function Sum(t1, f)
	checktype(t1, "table", 1)
	checktype(f, "function", 2)
	local ret = 0
	for i, v in ipairs(t1) do
		local result = f(v)
		if result then
			ret = ret + result
		end
	end
	return ret
end

local function Skip(t1, n)
	checktype(t1, "table", 1)
	checktype(n, "number", 2)
	local ret = { }
	for i, v in ipairs(t1) do
		if i >= n then
			ret[#ret+1] = v
		end
	end
	return new(ret)
end
local function SkipWhile(t1, f)
	checktype(t1, "table", 1)
	checktype(f, "function", 2)
	for i, v in ipairs(t1) do
		if not f(v, i) then
			return Skip(t1, i)
		end
	end
end

local function SingleOrDefault(t1, f)
	checktype(t1, "table", 1)
	checktype(f, {"function", "nil"}, 2)
	local ret = { }
	if type(f) == "nil" then
		if #t1 == 1 then return t1[1] end
		if #t1 > 1 then
			error("the source sequence in parameter #1 has more than one element!", 2)
		end
	else
		for i, v in ipairs(t1) do
			if f(v) then
				ret[#ret+1] = v
			end
		end
		if #ret == 1 then
			return ret[1]
		--elseif #ret == 0 then
			--error("no element satisfies the condition in parameter #2!", 2)
		elseif #ret > 1 then
			error("more than one element satisfies the condition in parameter #2!", 2)
		elseif #t1 == 0 then
			error("the source sequence in parameter #1 was empty!", 2)
		end
	end
end
local function Single(t1, f)
	checktype(t1, "table", 1)
	checktype(f, {"function", "nil"}, 2)
	local ret = { }
	if type(f) == "nil" then
		if #t1 == 1 then return t1[1] end
		if #t1 > 1 then
			error("the source sequence in parameter #1 was empty!", 2)
		else
			error("the source sequence in parameter #1 was empty!", 2)
		end
	else
		for i, v in ipairs(t1) do
			if f(v) then
				ret[#ret+1] = v
			end
		end
		if #ret == 1 then
			return ret[1]
		elseif #ret == 0 then
			error("no element satisfies the condition in parameter #2!", 2)
		elseif #ret > 1 then
			error("more than one element satisfies the condition in parameter #2!", 2)
		elseif #t1 == 0 then
			error("the source sequence in parameter #1 was empty!", 2)
		end
	end
end

local function SequenceEqual(t1, t2, f)
	checktype(t1, "table", 1)
	checktype(t2, "table", 2)
	checktype(f, {"function", "nil"}, 3)
	local equal = false
	if t1 == t2 then return true end
	if type(f) == "nil" then
		for i, v in ipairs(t1) do
			if DefaultCheck(v, t2[i]) then
				equal = true
			else
				equal = false
			end
		end
	else
		for i, v in ipairs(t1) do
			if f(v, t2[i]) then
				equal = true
			else
				equal = false
			end
		end
	end
	return equal
end

local function SelectMany(t1, f1, f2)
	checktype(t1, "table", 1)
	checktype(f1, "function", 2)
	checktype(f2, {"function", "nil"}, 3)
	if type(f2) =="nil" then
		local ret = { }
		for i, v in ipairs(t1) do
			local result = f1(v)
			if result then
				if type(result) == "table" then
					for j = 1, #result do
						ret[#ret+1] = result[j]
					end
				else
					ret[#ret+1] = result
				end
			end
		end
		return new(ret)
	else
		local ret1 = { }
		for i, v in ipairs(t1) do
			local result = f1(v, i)
			if result then
				ret1[#ret1+1] = result
			end
		end
		local ret2 = { }
		for i, v in ipairs(t1) do
			local result = f2(v)
			if result then
				ret2[#ret2+1] = result
			end
		end
		return new(ret2)
	end
end

local function Select(t1, f)
	checktype(t1, "table", 1)
	checktype(f, "function", 2)
	local ret = { }
	for i, v in ipairs(t1) do
		ret[#ret+1] = f(v, i)
	end
	return new(ret)
end

local function Reverse(t1)
	checktype(t1, "table", 1)
	local ret = { }
	for i, v in ipairs(t1) do
		ret[#ret+1] = v
	end
	return new(ret)
end

local function OrderByDescending(t1, f1, f2)
	checktype(t1, "table", 1)
	checktype(f1, "function", 2)
	checktype(f2, {"function", "nil"}, 3)
	local tosort = Where(t1, f1)
	if type(f2) == "nil" then
		sort(tosort)
	else
		sort(tosort, f2)
	end
	return Reverse(tosort)
end
local function OrderBy(t1, f1, f2)
	checktype(t1, "table", 1)
	checktype(f1, "function", 2)
	checktype(f2, {"function", "nil"}, 3)
	local tosort = OrderByDescending(t1, f1, f2)
	return Reverse(tosort)
end

local function Min(t1, f)
	checktype(t1, "table", 1)
	checktype(f, "function", 2)
	return OrderBy(t1, f)[1]
end
local function Max(t1, f)
	checktype(t1, "table", 1)
	checktype(f, "function", 2)
	return OrderByDescending(t1, f)[1]
end

local function LastOrDefault(t1, f)
	checktype(t1, "table", 1)
	checktype(f, {"function", "nil"}, 2)
	for i = #t1, 1, -1 do
		local v = t1[i]
		if type(f)=="nil" or f(v) then
			return v
		end
	end
end
local function Last(t1, f)
	checktype(t1, "table", 1)
	checktype(f, {"function", "nil"}, 2)
	local ret = { }
	if type(f) == "nil" then
		if #t1 > 0 then return t1[#t1] end
		error("the source sequence in parameter #1 was empty!", 2)
	else
		for i = #t1, 1, -1 do
			if f(t1[i]) then
				ret[#ret+1] = t1[i]
			end
		end
		if #ret == 1 then
			return ret[#ret]
		elseif #t1 == 0 then
			error("the source sequence in parameter #1 was empty!", 2)
		end
	end
end

local function Foreach(t1, f)
	checktype(t1, "table", 1)
	checktype(f, "function", 2)
	for i, v in ipairs(t1) do
		f(v)
	end
end

local function FirstOrDefault(t1, f)
	checktype(t1, "table", 1)
	checktype(f, {"function", "nil"}, 2)
	for i, v in ipairs(t1) do
		if type(f)=="nil" or f(v) then
			return t1[i]
		end
	end
end
local function First(t1, f)
	checktype(t1, "table", 1)
	checktype(f, {"function", "nil"}, 2)
	local ret = { }
	if type(f) == "nil" then
		if #t1 > 0 then return t1[1] end
		error("the source sequence in parameter #1 was empty!", 2)
	else
		for i, v in ipairs(t1) do
			if f(v) then
				ret[#ret+1] = v
			end
		end
		if #ret == 1 then
			return ret[1]
		elseif #t1 == 0 then
			error("the source sequence in parameter #1 was empty!", 2)
		end
	end
end

local function Distinct(t1)
	checktype(t1, "table", 1)
	local ret1 = { }
	local ret = { }
	for i, v in ipairs(t1) do
		if not ret1[tostring(v)] then
			ret1[tostring(v)] = true
			ret[#ret+1] = v
		end
	end
	return new(ret)
end

local function Contains(t1, value)
	checktype(t1, "table", 1)
	local val = false
	for i, v in ipairs(t1) do
		if v == value then
			val = true
			break
		end
	end
	return val
end

local function Concat(t1, t2)
	checktype(t1, "table", 1)
	checktype(t2, "table", 2)
	local ret = { }
	for i, v in ipairs(t1) do
		ret[#ret+1] = v
	end
	for i, v in ipairs(t2) do
		ret[#ret+1] = v
	end
	return new(ret)
end

local function Average(t1, f)
	checktype(t1, "table", 1)
	checktype(f, {"function", nil}, 2)
	local ret, num = 0, 0
	for i, v in ipairs(t1) do
		ret = ret + (f and f(v)) or v
		num = num + 1
	end
	return ret / num
end

local function Any(t1, f)
	checktype(t1, "table", 1)
	checktype(f, {"function", "nil"}, 2)
	local ret = false
	if type(f) == "nil" then
		ret = #t1 > 0
	else
		ret = #(Where(t1, f)) > 0
	end
	return ret
end

local function Aggregate(t1, f)
	checktype(t1, "table", 1)
	checktype(f, "function", 2)
end

_M = {
	Zip = Zip,
	Where = Where,
	Union = Union,
	TakeWhile = TakeWhile,
	Take = Take,
	Sum = Sum,
	SkipWhile = SkipWhile,
	Skip = Skip,
	SingleOrDefault = SingleOrDefault,
	Single = Single,
	SequenceEqual = SequenceEqual,
	SelectMany = SelectMany,
	Select = Select,
	Reverse = Reverse,
	OrderByDescending = OrderByDescending,
	OrderBy = OrderBy,
	Min = Min,
	Max = Max,
	LastOrDefault = LastOrDefault,
	Last = Last,
	Foreach = Foreach,
	FirstOrDefault = FirstOrDefault,
	First = First,
	Distinct = Distinct,
	Contains = Contains,
	Concat = Concat,
	Any = Any,
	new = new
}

return _M
