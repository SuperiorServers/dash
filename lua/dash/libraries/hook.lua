hook = setmetatable({}, {
	__call = function(self, ...)
		return self.Add(...)
	end
})

local hook 			= hook
local table_remove 	= table.remove
local debug_info 	= debug.getinfo
local isstring 			= isstring
local isfunction = isfunction
local ipairs 		= ipairs
local IsValid 		= IsValid

local hooks 		= {}
local mappings 		= {}

function hook.GetTable()
	return table.Copy(mappings)
end

function hook.Call(name, gm, ...) 
	if hooks[name] ~= nil then
		for k, v in ipairs(hooks[name]) do
			local a, b, c, d, e = v(...)
			if a ~= nil then
				return a, b, c, d, e
			end
		end
	end
	if gm ~= nil and gm[name] then
		return gm[name](gm, ...)
	end
end

local hook_Call = hook.Call
function hook.Run(name, ...)
	return hook_Call(name, GAMEMODE, ...)
end

function hook.Remove(name, id)
	local collection = hooks[name]
	if collection ~= nil then
		local func = mappings[name][id]
		if func ~= nil then
			for k,v in ipairs(collection) do
				if func == v then
					table_remove(collection, k)
					break 
				end
			end
		end
		mappings[name][id] = nil
	end
end

local hook_Remove = hook.Remove
function hook.Add(name, id, func) 
	if isfunction(id) then
		func = id
		id = debug_info(func).short_src
	end
	hook_Remove(name, id) -- properly simulate hook overwrite behavior

	if not isstring(id) then
		local orig = func
		func = function(...)
			if IsValid(id) then
				return orig(id, ...)
			else
				hook_Remove(name, id)
			end
		end
	end

	local collection = hooks[name]
	
	if collection == nil then
		collection = {}
		hooks[name] = collection
		mappings[name] = {}
	end

	local mapping = mappings[name]

	collection[#collection+1] = func
	mapping[id] = func
end
