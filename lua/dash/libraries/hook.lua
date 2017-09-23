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
local name_to_index	 = {}
local index_to_name	 = {}

function hook.GetTable() -- This function is now slow
	local ret = {}

	for id, collection in pairs(name_to_index) do
		ret[id] = {}

		for name, index in pairs(collection) do
			ret[id][name] = hook_callbacks[id][index]
		end
	end

	return ret
end

function hook.Exists(name, id)
	return (name_to_index[name] ~= nil) and (name_to_index[name][id] ~= nil)
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
		local namemap = name_to_index[name]
		local indexmap = index_to_name[name]
		local index = namemap[id]

		if (index ~= nil) then
			for i = index, #indexmap do
				local nexti = i + 1

				callbacks[i] = callbacks[nexti]
				callbacks[nexti] = nil

				local indexmapval = indexmap[i]
				if (indexmapval ~= nil) then
					namemap[indexmapval] = nil
				end

				indexmapval = indexmap[nexti]
				indexmap[nexti] = nil

				if (indexmapval ~= nil) then
					namemap[indexmapval] = i
				end

				indexmap[i] = indexmapval
			end
		end

		name_to_index[name][id] = nil
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
		name_to_index[name] = {}
		index_to_name[name] = {}
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
	name_to_index[name][id] = index
	index_to_name[name][index] = id
end