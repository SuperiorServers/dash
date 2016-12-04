require 'pon'

cvar = setmetatable({
	GetTable = setmetatable({}, {
		__call = function(self)
			return self
		end
	})
}, {
	__call = function(self, ...)
		return self.Register(...)
	end
})

local CVAR 	= {}
CVAR.__index = CVAR

debug.getregistry().cvar = CVAR

local function encode(data)
	return util.Compress(pon.encode(data))
end

local function decode(data)
	return pon.decode(util.Decompress(data))
end

local function load()
	if (not file.IsDir('cvar', 'DATA')) then
		file.CreateDir('cvar')
	else
		local files, _ = file.Find('cvar/*.dat', 'DATA')
		for k, v in ipairs(files) do
			local c = setmetatable(decode(file.Read('cvar/' .. v, 'DATA')), CVAR)
			cvar.GetTable[c.Name] = c
		end
	end
end

function CVAR:Save()
	file.Write('cvar/' .. self.ID .. '.dat', encode(self))
	return self
end

function CVAR:SetValue(value)
	hook.Call('cvar.' ..  self.Name, nil, self.Value, value)
	self.Value = value
	self:Save()
	return self
end

function CVAR:SetDefault(value)
	self.DefaultValue = value
	if (self.Value == nil) then
		self.Value = value
	end
	return self
end

function CVAR:AddMetadata(key, value)
	self.Metadata[key] = value
	return self
end

function CVAR:AddCallback(callback)
	hook.Add('cvar.' .. self.Name, callback)
	return self
end

function CVAR:GetName()
	return self.Name
end

function CVAR:GetValue()
	return self.Value
end

function CVAR:GetMetadata(key)
	return self.Metadata[key]
end

function CVAR:Reset()
	local default = self.DefaultValue
	if (default ~= nil) then
		self:SetValue(default)
		return true
	end
	return false
end

function CVAR:ConCommand(func)
	concommand.Add(self.Name, function(p, c, a) func(self, p, a) end)

	return self
end

function cvar.Register(name)
	if (not cvar.GetTable[name]) then
		cvar.GetTable[name] = setmetatable({
			Name = name,
			ID 	= util.CRC(name),
			Metadata = {}
		}, CVAR)
	end
	return cvar.GetTable[name]
end

function cvar.Get(name)
	if (not cvar.GetTable[name]) then
		cvar.Register(name)
	end
	return cvar.GetTable[name]
end

function cvar.SetValue(name, value)
	cvar.Get(name):SetValue(value)
end

function cvar.GetValue(name)
	return (cvar.GetTable[name] ~= nil) and cvar.GetTable[name].Value
end

load()