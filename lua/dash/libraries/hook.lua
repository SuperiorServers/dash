hook = setmetatable({}, {
	__call = function(self, ...)
		return self.Add(...)
	end
})

local debug_info 	= debug.getinfo
local isstring 		= isstring
local isfunction 	= isfunction
local IsValid 		= IsValid

local hook_callbacks = {}
local hook_mapping = {}

function hook.GetTable() -- This function is now slow
	return table.Copy(hook_mapping)
end

function hook.Exists(name, id)
	return (hook_mapping[name] ~= nil) and (hook_mapping[name][id] ~= nil)
end

function hook.Call(name, gm, ...)
	local callbacks = hook_callbacks[name]

	if (callbacks ~= nil) then
		for i = 1, #callbacks do
			local v = callbacks[i]
			if (v ~= nil) then
				local a, b, c, d, e, f = v(...)
				if (a ~= nil) then
					return a, b, c, d, e, f
				end
			end
		end
	end

	if (not gm) then
		return
	end

	local callback = gm[name]
	if (not callback) then
		return
	end

	return callback(gm, ...)
end

local hook_Call = hook.Call
function hook.Run(name, ...)
	return hook_Call(name, GAMEMODE, ...)
end

function hook.Remove(name, id)
	local callbacks = hook_callbacks[name]

	if (callbacks ~= nil) then
		local callback = hook_mapping[name][id]
		local count = #callbacks

		for i = 1, count do
			if (callbacks[i] == callback) then
				for newi = i, count do
					callbacks[newi] = callbacks[newi + 1]
				end
				hook_mapping[name][id] = nil
				break
			end
		end
	end
end


local hook_Exists, hook_Remove = hook.Exists, hook.Remove
function hook.Add(name, id, callback)
	if isfunction(id) then
		callback = id
		id = debug_info(callback).short_src
	end

	if (hook_callbacks[name] == nil) then
		hook_callbacks[name] = {}
		hook_mapping[name] = {}
	end

	if hook_Exists(name, id) then
		hook_Remove(name, id) -- properly simulate hook overwrite behavior
	end

	if (not isstring(id)) then
		local orig = callback
		callback = function(...)
			if IsValid(id) then
				return orig(id, ...)
			else
				hook_Remove(name, id)
			end
		end
	end

	local index = #hook_callbacks[name] + 1
	hook_callbacks[name][index] = callback
	hook_mapping[name][id] = callback
end