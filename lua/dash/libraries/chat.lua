chat = chat or {}

local chats = {}

local CHAT = {}
CHAT.__index = CHAT

debug.getregistry().Chat = CHAT

local net_Start 	= net.Start
local net_Send 		= net.Send
local net_Broadcast = net.Broadcast
local ents_FindInSphere = ents.FindInSphere

function chat.Register(name)
	local t = {
		NetworkString = 'chat_' .. name,
		_Write = net.WriteType,
		_Read = net.ReadType,
		SendFunc = net.Broadcast,
	}

	chats[name] = t

	if (SERVER) then
		util.AddNetworkString(t.NetworkString)
	else
		net.Receive(t.NetworkString, function()
			if IsValid(LocalPlayer()) then
				local ret = {t.ReadFunc()}
				if (#ret > 0) then
					chat.AddText(unpack(ret))
				end
			end
		end)
	end

	return setmetatable(t, CHAT)
end

function chat.Send(name, ...)
	local chat_obj = chats[name]
	net_Start(chat_obj.NetworkString)
		chat_obj.WriteFunc(...)
	chat_obj.SendFunc(...)
end

function CHAT:Write(func)
	self.WriteFunc = func
	return self
end

function CHAT:Read(func)
	self.ReadFunc = func
	return self
end

function CHAT:Filter(func)
	self.SendFunc = function(...)
		net_Send(func(...))
	end
	return self
end

function CHAT:SetLocal(radius) -- first arg to chat.Send must be a player if this is used
	self.SendFunc = function(pl)
		net_Send(table.Filter(ents_FindInSphere(pl:EyePos(), radius), function(v)
			return v:IsPlayer()
		end))
	end
end