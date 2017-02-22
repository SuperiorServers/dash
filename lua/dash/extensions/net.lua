setmetatable(net, {
	__call = function(self, name, func)
		return self.Receive(name, func)
	end
})


local IsValid   = IsValid
local Entity    = Entity
local WriteUInt = net.WriteUInt
local ReadUInt  = net.ReadUInt


local Incoming = net.Incoming
local hook_Call = hook.Call
function net.Incoming(bitCount, pl)
	hook_Call('IncomingNetMessage', nil, bitCount, pl)
	return Incoming(bitCount, pl)
end


local ReadData = net.ReadData
local math_abs = math.abs
local math_min = math.min
function net.ReadData(bitCount)
	return ReadData(math_min(math_abs(bitCount), 65533))
end

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

function net.WriteColor(c)
	WriteUInt(c.r, 8)
	WriteUInt(c.g, 8)
	WriteUInt(c.b, 8)
	WriteUInt(c.a, 8)
end

local Color = Color
function net.ReadColor()
	return Color(ReadUInt(8), ReadUInt(8), ReadUInt(8), ReadUInt(8))
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
		WriteUInt(pl:EntIndex(), 7)
	else
		WriteUInt(0, 7)
	end
end

function net.ReadPlayer()
	local i = ReadUInt(7)
	if (not i) then return end
	return Entity(i)
end

local Start = net.Start
local Send  = (SERVER) and net.Send or net.SendToServer
function net.Ping(msg, recipients)
	Start(msg)
	Send(recipients)
end
