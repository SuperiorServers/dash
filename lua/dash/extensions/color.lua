local Color 	 	= Color
local tonumber 		= tonumber
local string_format = string.format
local string_match 	= string.match
local bit_band		= bit.band
local bit_rshift 	= bit.rshift

local COLOR = FindMetaTable 'Color'

/*
function Color(r, g, b, a)

end
*/

function COLOR:Copy()
	return Color(self.r, self.g, self.b, self.a)
end

function COLOR:Unpack()
	return self.r, self.g, self.b, self.a
end

function COLOR:ToHex()
	return string_format('#%02X%02X%02X', self.r, self.g, self.b)
end

function COLOR:ToInt()
	return ((self.a * 0x100 + self.r) * 0x100 + self.g) * 0x100 + self.b
end


/*
function pcolor.FromHex(hex)
	local r, g, b = string_match(hex, '#(..)(..)(..)')
	return Color(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end

function pcolor.DecodeRGBA(num)
	return Color(bit_band(rshift(num, 16), 0xFF), bit_band(rshift(num, 8), 0xFF), bit_band(num, 0xFF), bit_band(rshift(num, 24), 0xFF))
end