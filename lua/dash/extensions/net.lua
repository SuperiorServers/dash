setmetatable(net, {
	__call = function(self, name, func)
		return self.Receive(name, func)
	end
})

local hook_Call = hook.Call
local math_abs = math.abs
local math_min = math.min
local IsValid 	= IsValid
local Entity 	= Entity
local Color 	= Color
local WriteUInt = net.WriteUInt
local ReadUInt 	= net.ReadUInt
local Start 	= net.Start
local Send 		= (SERVER) and net.Send or net.SendToServer

local Incoming = net.Incoming
function net.Incoming(bitCount, pl)
	hook_Call('IncomingNetMessage', nil, bitCount, pl)
	return Incoming(bitCount, pl)
end

local ReadUInt = net.ReadUInt
function net.ReadUInt(bitCount)
	if (bitCount > 32) or (bitCount < 1) then
		error('Out of range bitCount! Got ' .. bitCount)
	end
	return ReadUInt(bitCount)
end

local ReadInt = net.ReadInt
function net.ReadInt(bitCount)
	if (bitCount > 32) or (bitCount < 1) then
		error('Out of range bitCount! Got ' .. bitCount)
	end
	return ReadInt(bitCount)
end

function net.WriteEntity(ent)
	if IsValid(ent) then
		WriteUInt(ent:EntIndex(), 12)
	else
		WriteUInt(0, 12)
	end
end

function net.ReadEntity()
	local i = ReadUInt(12)
	if (not i) then return end
	return Entity(i)
end

function net.WriteRGB(r, g, b)
	WriteUInt(r, 8)
	WriteUInt(g, 8)
	WriteUInt(b, 8)
end

function net.WriteRGBA(r, g, b, a)
	WriteUInt(r, 8)
	WriteUInt(g, 8)
	WriteUInt(b, 8)
	WriteUInt(a, 8)
end
local WriteRGBA = net.WriteRGBA

function net.WriteColor(c)
	WriteRGBA(c.r, c.g, c.b, c.a)
end

function net.ReadRGB()
	return ReadUInt(8), ReadUInt(8), ReadUInt(8)
end

function net.ReadRGBA()
	return ReadUInt(8), ReadUInt(8), ReadUInt(8), ReadUInt(8)
end
local ReadRGBA = net.ReadRGBA

function net.ReadColor()
	return Color(ReadRGBA())
end

function net.WriteNibble(i)
	WriteUInt(i, 4)
end

function net.ReadNibble()
	return ReadUInt(4)
end

function net.WriteByte(i)
	WriteUInt(i, 8)
end

function net.ReadByte()
	return ReadUInt(8)
end

function net.WriteShort(i)
	WriteUInt(i, 16)
end

function net.ReadShort()
	return ReadUInt(16)
end

function net.WriteLong(i)
	WriteUInt(i, 32)
end

function net.ReadLong()
	return ReadUInt(32)
end

function net.WritePlayer(pl)
	if IsValid(pl) then
		WriteUInt(pl:EntIndex(), 8)
	else
		WriteUInt(0, 8)
	end
end

function net.ReadPlayer()
	local i = ReadUInt(8)
	if (not i) then return end
	return Entity(i)
end

function net.Ping(msg, recipients)
	Start(msg)
	Send(recipients)
end

