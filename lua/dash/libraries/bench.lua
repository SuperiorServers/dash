bench = {}

local SysTime 	= SysTime
local pairs 	= pairs
local tostring 	= tostring
local MsgC 		= MsgC

local col_white = Color(250,250,250)
local col_red 	= Color(255,0,0)
local col_green = Color(0,255,0)

local stack = {}
function bench.Push()
	stack[#stack + 1] = SysTime()
end

function bench.Pop()
	local ret = stack[#stack]
	stack[#stack] = nil
	return SysTime() - ret
end

function bench.Run(func, calls)
	bench.Push()
	for i = 1, (calls or 1000) do
		func()
	end
	return bench.Pop()
end

function bench.Compare(funcs, calls)
	local lowest = math.huge
	local results = {}
	for k, v in pairs(funcs) do
		local runtime = bench.Run(v, calls)
		results[k] = runtime
		if (runtime < lowest) then
			lowest = runtime
		end
	end
	for k, v in pairs(results) do
		if (v == lowest) then
			MsgC(col_green, tostring(k):upper() .. ': ', col_white, v .. '\n')
		else
			MsgC(col_red, tostring(k):upper() .. ': ', col_white, v .. '\n')
		end
	end
end