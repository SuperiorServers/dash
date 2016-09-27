-- PrintTable, Modified from https://github.com/meepdarknessmeep/gmodutil
local function GetTextSize(x)
	return x:len(), 1
end

local function PrintType(x)
	if IsColor(x) then return 'Color' end
	if isplayer(x) then return 'Player' end
	if isentity(x) then return 'Entity' end
	return type(x)
end

local function FixTabs(x, width)
	local curw = GetTextSize(x)
	local ret = ''
	while(curw < width) do -- not using string.rep since linux
		x 		= x..' '
		ret 	= ret..' '
		curw 	= GetTextSize(x)
	end
	return ret
end

local typecol = {
	boolean         = Color(0x98, 0x81, 0xF5),
	['function']    = Color(0x00, 0xC0, 0xB6),
	number          = Color(0xF9, 0xD0, 0x8B),
	string          = Color(0xF9, 0x8D, 0x81),
	table           = Color(040, 175, 140),
	func            = Color(0x82, 0xAF, 0xF9),
	etc             = Color(0xF0, 0xF0, 0xF0),
	unk             = Color(255, 255, 255),
	com             = Color(0x00, 0xB0, 0x00),
}

local replacements = {
	['\n']	= '\\n',
	['\r']	= '\\r',
	['\v']	= '\\v',
	['\f']	= '\\f',
	['\x00']= '\\x00',
	['\\']	= '\\\\',
	['\'']	= '\\\'',
}

local ConversionLookupTable = {
	string = function(obj, iscom)
		return {typecol.string, '\''..obj:gsub('.', replacements)..'\''} -- took from string.lua
	end,
	Vector = function(obj, iscom)
		return {typecol.func, 'Vector', typecol.etc, '(', typecol.number, tostring(obj.x), typecol.etc, ', ',
			typecol.number, tostring(obj.y), typecol.etc, ', ', typecol.number, tostring(obj.z), typecol.etc, ')'}
	end,
	Angle = function(obj, iscom)
		return {typecol.func, 'Angle', typecol.etc, '(', typecol.number, tostring(obj.p), typecol.etc, ', ',
			typecol.number, tostring(obj.y), typecol.etc, ', ', typecol.number, tostring(obj.r), typecol.etc, ')'}
	end,
	Color = function(obj, iscom)
		return {typecol.func, 'Color', typecol.etc, '(', typecol.number, tostring(obj.r), typecol.etc, ', ', typecol.number,
			tostring(obj.g), typecol.etc, ', ', typecol.number, tostring(obj.b), typecol.etc, ', ', typecol.number, 
				tostring(obj.a), typecol.etc, ')'}, true
	end,
	Player = function(obj, iscom)
		return {typecol.func, 'Player', typecol.etc, '[', typecol.number, tostring(obj:UserID()), typecol.etc,
			']', typecol.com, (iscom and '['..(obj:IsValid() and obj.Nick and obj:Nick() or 'missing_nick') or '') .. ']'}, true
	end,
}

local function DebugFixToStringColored(obj, iscom)
	local type = PrintType(obj)
	if(ConversionLookupTable[type]) then
		return ConversionLookupTable[type](obj, iscom)
	end
	if(not typecol[type]) then
		return {typecol.unk, '('..type..') '..tostring(obj)}
	else
		return {typecol[type], tostring(obj)}
	end
end

local function DebugFixToString(obj, iscom)
	local ret = ''
	local rets, osc = DebugFixToStringColored(obj, iscom)
	for i = 2, #rets, 2 do
		ret = ret.. rets[i]
	end
	return ret
end

function PrintTable(tbl, spaces, done)
	local buffer = {}
	local rbuf = {}
	local maxwidth = 0
	local spaces = spaces or 0
	local done = done or {}
	done[tbl] = true
	for key,val in pairs(tbl) do
		rbuf[#rbuf + 1]  = key
		buffer[#buffer + 1] = '['..DebugFixToString(key)..'] '
		maxwidth = math.max(GetTextSize(buffer[#buffer]), maxwidth)
	end
	local str = string.rep(' ', spaces)
	if(spaces == 0) then MsgN('\n') end
	MsgC(typecol.etc, '{\n')
	local tabbed = str..string.rep(' ', 4)
	
	for i = 1, #buffer do
		local overridesc = false
		local key = rbuf[i]
		local value = tbl[key]
		MsgC(typecol.etc, tabbed..'[')
		MsgC(unpack((DebugFixToStringColored(key))))
		MsgC(typecol.etc, '] '..FixTabs(buffer[i], maxwidth), typecol.etc, '= ')
		if(type(value) == 'table' and not IsColor(value) and not done[value]) then
			PrintTable(tbl[key], spaces + 4, done)
		else
			local args, osc = DebugFixToStringColored(value, true)
			overridesc = osc
			MsgC(unpack(args))
		end
		if(not overridesc) then
			MsgC(typecol.etc, ',')
		end
		MsgN''
	end
	MsgC(typecol.etc, str..'}')
	if(spaces == 0) then
		MsgN''
	end
end


local col_white = Color(255,255,255)
local incr = SERVER and 72 or 0
local fileColors = {}
local fileAbbrev = {}

local function concat(...)
	if (... == nil) then
		return '	nil'
	else
		local str = ''
		local i = 1
		for k, v in pairs({...}) do
			if (i ~= k) then
				str = str .. '	nil'
				i = i + 1
			end
			str = str .. '	' .. tostring(v)
			i = i + 1
		end
		return str
	end
end

local oprint = print
function print(...)
	local info = debug.getinfo(2)
	if (not info) then 
		oprint(...)
		return
	end
	
	local fname = info.short_src
	if fileAbbrev[fname] then
		fname = fileAbbrev[fname]
	else
		local oldfname = fname
		fname = string.Explode('/', fname)
		fname = fname[#fname]
		fileAbbrev[oldfname] = fname
	end
	
	if (not fileColors[fname]) then
		incr = incr + 1
		fileColors[fname] = HSVToColor(incr * 100 % 255, 1, 1)
	end
	
	MsgC(fileColors[fname], fname .. ':' .. info.linedefined, col_white, concat(...) .. '\n')
end