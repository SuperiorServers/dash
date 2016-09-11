if (SERVER) then
	local message 	= {}
	local pooled 	= {}

	util.AddNetworkString 'umsg.SendLua'
	util.AddNetworkString 'umsg.UnPooled'

	function SendUserMessage(name, recipients, ...)
		umsg.Start(name, recipients)
		for k, v in pairs({...}) do
			local t = type(v)
			if (t == 'string') then
				umsg.String(v)
			elseif IsEntity(v) then
				umsg.Entity(v)
			elseif (t == 'number') then
				umsg.Long(v)
			elseif (t == 'Vector') then
				umsg.Vector(v)
			elseif (t == 'Angle') then
				umsg.Angle(v)
			elseif (t == 'boolean') then
				umsg.Bool(v)
			else
				ErrorNoHalt('SendUserMessage: Couldn\'t send type ' .. t .. '\n')
			end
		end
		umsg.End()
	end

	function BroadcastLua(lua)
		net.Start 'umsg.SendLua'
			net.WriteString(lua)
		net.Broadcast()
	end

	debug.getregistry().Player.SendLua = function(self, lua)
		net.Start 'umsg.SendLua'
			net.WriteString(lua)
		net.Send(self)
	end	

	function umsg.PoolString(name)
		if (not pooled[name]) then
			util.AddNetworkString('umsg.' .. name)
			pooled[name] = true
		end
	end

	function umsg.Start(name, recipients)
		local t = type(recipients)

		if (t == 'CRecipientFilter') then
			message = recipients:GetPlayers()
		elseif (t == 'Player') or (t == 'table') then
			message = recipients
		else
			message = player.GetAll()
		end

		if pooled[name] then
			net.Start('umsg.' .. name)
		else
			umsg.PoolString(name)
			net.Start 'umsg.UnPooled'
			net.WriteString(name)
		end
	end

	function umsg.End()
		net.Send(message)
	end

	function umsg.Angle(value)
		net.WriteAngle(value)
	end

	function umsg.Bool(value)
		net.WriteBool(value)
	end

	function umsg.Char(value)
		net.WriteInt((isstring(value) and string.char(value) or value), 8)
	end

	function umsg.Entity(value)
		net.WriteEntity(value)
	end

	function umsg.Float(value)
		net.WriteFloat(value)
	end

	function umsg.Long(value)
		net.WriteInt(value, 32)
	end

	function umsg.Short(value)
		net.WriteInt(value, 16)
	end

	function umsg.String(value)
		net.WriteString(value)
	end

	function umsg.Vector(value)
		net.WriteVector(value)
	end

	function umsg.VectorNormal(value)
		net.WriteVector(value)
	end
else
	usermessage = {}
	local hooks = {}

	net.Receive('umsg.SendLua', function()
		RunString(net.ReadString())
	end)

	net.Receive('umsg.UnPooled', function(len, ...)
		usermessage.IncomingMessage(net.ReadString())
	end)

	function usermessage.Hook(name, callback, ...)
		if (SERVER) then
			umsg.PoolString(name)
			return
		end

		hooks[name] = {}
		hooks[name].Function = function()
			callback(usermessage, unpack(hooks[name].PreArgs))
		end
		hooks[name].PreArgs	= {...}

		net.Receive('umsg.' .. name, function(len)
			usermessage.IncomingMessage(name)
		end)
	end

	function usermessage.GetTable()
		return hooks
	end

	function usermessage.IncomingMessage(name)
		if hooks[name] then
			hooks[name].Function()
		else
			Msg('Warning: Unhandled usermessage \'' .. name .. '\'\n')
		end
	end

	function usermessage:ReadAngle()
		return net.ReadAngle()
	end

	function usermessage:ReadBool()
		return net.ReadBool()
	end

	function usermessage:ReadChar()
		return net.ReadInt(8)
	end

	function usermessage:ReadEntity()
		return net.ReadEntity()
	end

	function usermessage:ReadFloat()
		return net.ReadFloat()
	end

	function usermessage:ReadLong()
		return net.ReadInt(32)
	end

	function usermessage:ReadShort()
		return net.ReadInt(16)
	end

	function usermessage:ReadString()
		return net.ReadString()
	end

	function usermessage:ReadVector()
		return net.ReadVector()
	end

	function usermessage:ReadVectorNormal()
		local v = net.ReadVector()
		v:Normalize()
		return v
	end

	function usermessage:Reset()
		ErrorNoHalt('usermessage:Reset() is not supported!')
	end
end
