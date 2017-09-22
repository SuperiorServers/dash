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
	local info = hook_callbacks[name]

	if (info ~= nil) then
		for i = 1, #info do
			local v = info[i]
			if (v ~= nil) then
				local a, b, c, d, e, f = v(...)
				if (a ~= nil) then
					return a, b, c, d, e, f
				end
			end
		end
	end

	if (gm ~= nil) and gm[name] then
		return gm[name](gm, ...)
	end
end

local hook_Call = hook.Call
function hook.Run(name, ...)
	return hook_Call(name, GAMEMODE, ...)
end

function hook.Remove(name, id)
	local hook_callbacks = hook_callbacks[name]

	if (hook_callbacks ~= nil) then

		local namemap = name_to_index[name]
		local indexmap = index_to_name[name]
		local index = namemap[id]

		if (index ~= nil) then -- todo make this faster
			local count = #indexmap

			for i = index, count do
				local nexti = i + 1

				hook_callbacks[i] = hook_callbacks[nexti]
				hook_callbacks[nexti] = nil

				if (indexmap[i] ~= nil) then
					namemap[indexmap[i]] = nil
				end

				indexmap[i] = indexmap[nexti]
				indexmap[nexti] = nil

				if (indexmap[i] ~= nil) then
					namemap[indexmap[i]] = i
				end
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