require 'hash'
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

debug.getregistry().Cvar = CVAR

local data_directory = 'cvar'
local staged_cvars = {}
local function load()
	if (not file.IsDir(data_directory, 'DATA')) then
		file.CreateDir(data_directory)
	else
		local files, _ = file.Find(data_directory .. '/*.dat', 'DATA')
		for k, v in ipairs(files) do
			local file_dir = data_directory .. '/' .. v
			local success, var = pcall(pon.decode, util.Decompress(file.Read(file_dir, 'DATA')))
			if success and isstring(var.Name) and (tostring(var.ID) == v:sub(0, -5)) and istable(var.Metadata) then
				staged_cvars[var.Name] = setmetatable(var, CVAR)
			else
				file.Delete(file_dir)
			end
		end
	end
end


function cvar.Register(name)
	if (not cvar.GetTable[name]) then
		cvar.GetTable[name] = staged_cvars[name] or setmetatable({
			Name = name,
			ID = hash.MD5(name),
			Metadata = {}
		}, CVAR)
		staged_cvars[name] = nil
	end
	return cvar.GetTable[name]
end

function cvar.Get(name)
	if (not cvar.GetTable[name]) or (staged_cvars[name]) then
		cvar.Register(name)
	end
	return cvar.GetTable[name]
end

function cvar.SetValue(name, value)
	cvar.Get(name):SetValue(value)
end

function cvar.GetValue(name)
	return (cvar.GetTable[name] ~= nil) and cvar.GetTable[name]:GetValue()
end


function CVAR:ConCommand(func)
	concommand.Add(self.Name, function(p, c, a) func(self, p, a) end)
	return self
end

function CVAR:SetDefault(value, enforce)
	self.DefaultValue = value
	if (self.Value == nil) then
		self.Value = value
	end
	if enforce then
		self:SetType(TypeID(value))
	end
	return self
end

function CVAR:SetValue(value)
	if self:Validate(value) then
		hook.Call('cvar.' ..  self.Name, nil, self.Value, value)
		self.Value = value
		self:Save()
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

function CVAR:Validate(value)
	return true
end

function CVAR:SetType(typeid)
	self.Validate = isfunction(typeid) and typeid or function(self, value)
		return (TypeID(value) == typeid)
	end
	if (not self:Validate(self.Value)) then
		self:Reset()
	end
	return self
end

function CVAR:Reset()
	self:SetValue(self.DefaultValue)
end

function CVAR:Save()
	file.Write(data_directory .. '/' .. self.ID .. '.dat', util.Compress(pon.encode({
		Name = self.Name,
		ID = self.ID,
		Value = self.Value,
		Metadata = self.Metadata,
	})))
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


load()