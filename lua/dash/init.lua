dash = {
	Modules = {},
	LoadedModules = {},
	BadModules = {}
}

_R = debug.getregistry()

dash.IncludeSV = (SERVER) and include or function() end
dash.IncludeCL = (SERVER) and AddCSLuaFile or include
dash.IncludeSH = function(f) AddCSLuaFile(f) return include(f) end

function dash.LoadDir(...)
	local ret = {}
	for _, dir in ipairs({...}) do
		local files, folders = file.Find('dash/' .. dir .. '/*', 'LUA')
		for _, f in ipairs(files) do
			if (f:sub(f:len() - 2, f:len()) == 'lua') then
				ret[f:sub(1, f:len() - 4)] = 'dash/' .. dir .. '/' .. f
			end
		end
		for _, f in ipairs(folders) do
			if (f ~= 'client') and (f ~= 'server') then
				ret[f] = 'dash/' .. dir .. '/' .. f .. '/' .. f ..'.lua'
			end
		end
	end
	return ret
end


local preshared = dash.LoadDir('preload')
local preserver = (SERVER) and dash.LoadDir('preload/server') or {}
local preclient = dash.LoadDir('preload/client')

local modshared = dash.LoadDir('libraries', 'thirdparty')
local modserver = (SERVER) and dash.LoadDir('libraries/server', 'thirdparty/server') or {}
local modclient = dash.LoadDir('libraries/client', 'thirdparty/client')

for k, v in pairs(preshared) do
	dash.IncludeSH(v)
end

for k, v in pairs(preclient) do
	dash.IncludeCL(v)
end

if (SERVER) then
	for k, v in pairs(preserver) do
		dash.IncludeSV(v)
	end

	for k, v in pairs(modserver) do
		dash.Modules[k] = v
	end
end

for k, v in pairs(modshared) do
	if (SERVER) then
		AddCSLuaFile(v)
	end
	dash.Modules[k] = v
end

for k, v in pairs(modclient) do
	if (SERVER) then
		AddCSLuaFile(v)
	else
		dash.Modules[k] = v
	end
end

_require = require
function require(name)
	local lib = dash.Modules[name]
	if lib and (not dash.LoadedModules[name]) and (not dash.BadModules[name]) then
		dash.LoadedModules[name] = true
		return include(lib)
	elseif (not dash.LoadedModules[name]) and (not dash.BadModules[name]) then
		return _require(name)
	end
end