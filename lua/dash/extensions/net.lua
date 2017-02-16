setmetatable(net, {
	__call = function(self, name, func)
		return self.Receive(name, func)
	end
})

local IsValid 	= IsValid
local Entity 	= Entity
local Color 	= Color
local WriteUInt = net.WriteUInt
local ReadUInt 	= net.ReadUInt
local Start 	= net.Start
local Send 		= (SERVER) and net.Send or net.SendToServer
local hook_Call = hook.Call

local Incoming = net.Incoming
function net.Incoming(len, pl)
	hook_Call('IncomingNetMessage', nil, len, pl)
	return Incoming(len, pl)
end

local ReadData = net.ReadData
function net.ReadData(len)
	return ReadData(math.Clamp(len, 0, 65533)) --Clamp the length to the maximum size of a net message (65533 bytes)
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

function net.Ping(msg, recipients)
	Start(msg)
	Send(recipients)
end

