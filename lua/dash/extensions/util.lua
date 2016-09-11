-- PrintTable
-- Modified from https://github.com/meepdarknessmeep/gmodutil
local function GetTextSize(x)
	return x:len(), 1
end

local function PrintType(x)
	if(IsColor(x)) then return 'Color' end
	if(TypeID(x) == TYPE_ENTITY) then 
		if(x:IsPlayer()) then return 'Player' end
		return 'Entity'
	end
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

if (CLIENT) then
	local name = GetConVar('sv_skyname'):GetString()
	local areas = {'lf', 'ft', 'rt', 'bk', 'dn', 'up'}
	local maerials = {
	    Material('skybox/'.. name .. 'lf'),
	    Material('skybox/'.. name .. 'ft'),
	    Material('skybox/'.. name .. 'rt'),
	    Material('skybox/'.. name .. 'bk'),
	    Material('skybox/'.. name .. 'dn'),
	    Material('skybox/'.. name .. 'up'),
	}
	 
	function util.SetSkybox(skybox) -- Thanks someone from some fp post I cant find
	    for i = 1, 6 do
	        maerials[i]:SetTexture('$basetexture', Material('skybox/' .. skybox .. areas[i]):GetTexture('$basetexture'))
	    end
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

function dprint(...)
	local info = debug.getinfo(2)
	if (not info) then 
		print(...)
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


--[[---------------------------------------------------------
   Name: Tracer( vecStart, vecEnd, pEntity, iAttachment, flVelocity, bWhiz, pCustomTracerName, iParticleID )
   Desc: Create a tracer effect
-----------------------------------------------------------]]
-- Tracer flags
TRACER_FLAG_WHIZ = 0x0001
TRACER_FLAG_USEATTACHMENT = 0x0002

TRACER_DONT_USE_ATTACHMENT = -1

function util.Tracer( vecStart, vecEnd, pEntity, iAttachment, flVelocity, bWhiz, pCustomTracerName, iParticleID )
	local data = EffectData()
	data:SetStart( vecStart )
	data:SetOrigin( vecEnd )
	data:SetEntity( pEntity )
	data:SetScale( flVelocity )
	
	if ( iParticleID ~= nil ) then
		data:SetHitBox( iParticleID )
	end

	local fFlags = data:GetFlags()

	-- Flags
	if ( bWhiz ) then
		fFlags = bit.bor( fFlags, TRACER_FLAG_WHIZ )
	end

	if ( iAttachment ~= TRACER_DONT_USE_ATTACHMENT ) then
		fFlags = bit.bor( fFlags, TRACER_FLAG_USEATTACHMENT )
		data:SetAttachment( iAttachment )
	end

	data:SetFlags( fFlags )

	-- Fire it off
	if ( pCustomTracerName ) then
		util.Effect( pCustomTracerName, data )
	else
		util.Effect( "Tracer", data )
	end
end

--[[---------------------------------------------------------
	Linear interpolates between two colors
-----------------------------------------------------------]]
function LerpColor( fraction, from, to )
	return Color( Lerp( fraction, from.r, to.r ), Lerp( fraction, from.g, to.g ), Lerp( fraction, from.b, to.b ), Lerp( fraction, from.a, to.a ) )
end

--[[---------------------------------------------------------
	Find an empty Vector
-----------------------------------------------------------]]
local Vector 				= Vector
local ents_FindInSphere 	= ents.FindInSphere
local util_PointContents 	= util.PointContents

local badpoints = {
	[CONTENTS_SOLID] 		= true,
	[CONTENTS_MOVEABLE] 	= true,
	[CONTENTS_LADDER]		= true,
	[CONTENTS_PLAYERCLIP] 	= true,
	[CONTENTS_MONSTERCLIP] 	= true,
}

local function isempty(pos, area)
	if badpoints[util_PointContents(pos)] then
		return false
	end
	local entities = ents_FindInSphere(pos, area)
	for i = 1, #entities do
		if (entities[i]:GetClass() == 'prop_physics') or (entities[i]:IsPlayer() and entities[i]:Alive()) then
			return false
		end
	end
	return true
end

function util.FindEmptyPos(pos, area, steps)
	pos = Vector(pos.x, pos.y, pos.z)
	area = area or 35

	if isempty(pos, area) then
		return pos
	end

	for i = 1, (steps or 6) do
		local step = (i * 50)
		if isempty(Vector(pos.x + step, pos.y, pos.z), area) then
			pos.x = pos.x + step
			return pos
		elseif isempty(Vector(pos.x, pos.y + step, pos.z), area) then
			pos.y = pos.y + step
			return pos
		elseif isempty(Vector(pos.x, pos.y, pos.z + step), area) then
			pos.z = pos.z + step
			return pos
		end
	end
	
	return pos
end

function resource.AddDir(dir, recursive)
	local files, folders = file.Find(dir .. '*', 'GAME')

	for k, v in ipairs(files) do
		resource.AddFile(dir .. v)
	end
	if (recursive == true) then
		for k, v in ipairs(folders) do
			resource.AddDir(dir .. v, recursive)
		end
	end
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function util.Base64Decode(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

function util.IsSpaceEmpty( vMin, vMax, Filter, iMask )
	local vHalfDims = (vMax - vMin) / 2
	local vCenter = vMin + vHalfDims
	
	local tr = util.TraceHull({
		start = vCenter,
		endpos = vCenter,
		mins = -vHalfDims,
		maxs = vHalfDims,
		mask = iMask or MASK_SOLID,
		filter = Filter
	})
	
	return tr.Fraction == 1 and not tr.AllSolid and not tr.StartSolid
end

function util.SeedFileLineHash( iSeed, sName, iAdditionalSeed /*=0*/ )
	return tonumber( util.CRC(( "%i%i%s" ):format( iSeed, iAdditionalSeed or 0, sName )))
end
