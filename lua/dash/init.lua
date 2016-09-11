dash = {
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
				ret[f] = 'dash/' .. dir  .. '/' .. f .. '/' .. f ..'.lua'
			end
		end
	end
	return ret
end

local modules = {
	preload = {
		Shared = dash.LoadDir('preload'),
		Server = (SERVER) and dash.LoadDir('preload/server') or {},
		Client = dash.LoadDir('preload/client'),
	},
	Shared = dash.LoadDir('libraries', 'thirdparty'),
	Server = (SERVER) and dash.LoadDir('libraries/server', 'thirdparty/server') or {},
	Client = dash.LoadDir('libraries/client', 'thirdparty/client'),
	Loaded = {}
}

for k, v in pairs(modules.preload.Shared) do
	dash.IncludeSH(v)
end

if (SERVER) then
	for k, v in pairs(modules.preload.Server) do
		dash.IncludeSV(v)
	end
	for k, v in pairs(modules.Shared) do
		AddCSLuaFile(v)
	end
	for k, v in pairs(modules.Client) do
		AddCSLuaFile(v)
	end
end

for k, v in pairs(modules.preload.Client) do
	dash.IncludeCL(v)
end

_require = require
function require(name)
	local lib = modules.Shared[name] or modules.Server[name] or modules.Client[name]
	if (lib ~= nil) and (not modules.Loaded[name]) and (not dash.BadModules[name]) then
		modules.Loaded[name] = true
		return include(lib)
	elseif (not modules.Loaded[name]) and (not dash.BadModules[name]) then
		return _require(name)
	end
end