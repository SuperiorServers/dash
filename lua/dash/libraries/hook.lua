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
local hook_mapping 	 = {}
local hook_counts 	 = {}
local hooks_remap 	 = false

function hook.GetTable() -- This function is now slow
	return table.Copy(hook_mapping)
end

function hook.Exists(name, id)
	return (hook_mapping[name] ~= nil) and (hook_mapping[name][id] ~= nil)
end

function hook.Call(name, gm, ...)
	local callbacks = hook_callbacks[name]

	if (callbacks ~= nil) then
		local count = hook_counts[name]
		local i = 0
		::start::
		i = i + 1
		local v = callbacks[i]
		if (v ~= nil) then
			local a, b, c, d, e, f = v(...)
			if (a ~= nil) then
				return a, b, c, d, e, f
			end
		end
		if (i < count) then goto start end
	end

	if (hooks_remap) then
		local count = 0
		hook_callbacks[name] = {}
		for i = 1, hook_counts[name] do
			if (callbacks[i] ~= nil) then
				count = count + 1
				hook_callbacks[name][count] = callbacks[i]
			end
		end
		hook_counts[name] = count
		hooks_remap = false
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

	if (not callbacks) then
		return
	end

	local callback = hook_mapping[name][id]

	if (not callback) then
		return
	end

	local count = #callbacks

	for i = 1, count do
		if (callbacks[i] == callback) then
			for newi = i, count do
				callbacks[newi] = callbacks[newi + 1]
			end
			hook_mapping[name][id] = nil
			hook_counts[name] = hook_counts[name] - 1
			return
		end
	end
end


local hook_Exists, hook_Remove = hook.Exists, hook.Remove
function hook.Add(name, id, callback)
	if isfunction(id) then
		callback = id
		id = debug_info(callback).short_src
	end

	if (not callback) then
		return
	end

	if (hook_callbacks[name] == nil) then
		hook_callbacks[name] = {}
		hook_mapping[name] = {}
	end

	if hook_Exists(name, id) then
		hook_Remove(name, id) -- properly simulate hook overwrite behavior
	end

	hook_counts[name] = (hook_counts[name] or 0) + 1
	local index = hook_counts[name]

	if (not isstring(id)) then
		local orig = callback
		callback = function(...)
			if IsValid(id) then
				return orig(id, ...)
			end
			hook_mapping[name][id] = nil
			hook_callbacks[name][index] = nil
			hooks_remap = true
		end
	end

	hook_callbacks[name][index] = callback
	hook_mapping[name][id] = callback
end
