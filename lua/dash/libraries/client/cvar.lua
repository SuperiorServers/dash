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

local cvar_mt 	= {}
cvar_mt.__index = cvar_mt

debug.getregistry().cvar = cvar_mt

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
			local c = setmetatable(decode(file.Read('cvar/' .. v, 'DATA')), cvar_mt)
			cvar.GetTable[c.Name] = c
		end
	end
end

function cvar_mt:Save()
	file.Write('cvar/' .. self.ID .. '.dat', encode(self))
	return self
end

function cvar_mt:SetValue(value)
	hook.Call('cvar.' ..  self.Name, nil, self.Value, value)
	self.Value = value
	self:Save()
	return self
end

function cvar_mt:SetDefault(value)
	self.DefaultValue = value
	if (self.Value == nil) then
		self.Value = value
	end
	return self
end

function cvar_mt:AddMetadata(key, value)
	self.Metadata[key] = value
	return self
end

function cvar_mt:AddCallback(callback)
	hook.Add('cvar.' .. self.Name, callback)
	return self
end

function cvar_mt:GetName()
	return self.Name
end

function cvar_mt:GetValue()
	return self.Value
end

function cvar_mt:GetMetadata(key)
	return self.Metadata[key]
end

function cvar_mt:Reset()
	local default = self.DefaultValue
	if (default ~= nil) then
		self:SetValue(default)
		return true
	end
	return false
end

function cvar_mt:ConCommand(func)
	concommand.Add(self.Name, function(p, c, a) func(self, p, a) end)

	return self
end

function cvar.Register(name)
	if (not cvar.GetTable[name]) then
		cvar.GetTable[name] = setmetatable({
			Name = name,
			ID 	= util.CRC(name),
			Metadata = {}
		}, cvar_mt)
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