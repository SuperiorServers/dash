local debug_info 	= debug.getinfo
local isstring 		= isstring
local isfunction 	= isfunction
local IsValid 		= IsValid

local hook_callbacks = {}
local hook_index 	 = {}
local hook_id		 = {}

local function GetTable() -- This function is now slow
	local ret = {}
	for name, callbacks in pairs(hook_callbacks) do
		ret[name] = {}
		for index, callback in pairs(callbacks) do
			ret[name][hook_id[name][index]] = callback
		end
	end
	return ret
end

local function Exists(name, id)
	return (hook_index[name] ~= nil) and (hook_index[name][id] ~= nil)
end

local function Call(name, gm, ...)
	local callbacks = hook_callbacks[name]

	if (callbacks ~= nil) then

		local i = 0

		::runhook::
		i = i + 1
		local v = callbacks[i]
		if (v ~= nil) then
			local a, b, c, d, e, f = v(...)
			if (a ~= nil) then
				return a, b, c, d, e, f
			end
			goto runhook
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

local function Run(name, ...)
	return Call(name, GAMEMODE, ...)
end

local function Remove(name, id)
	local callbacks = hook_callbacks[name]

	if (not callbacks) then
		return
	end

	local indexes = hook_index[name]
	local index = indexes[id]

	if (not index) then
		return
	end

	local count = #callbacks
	if (count == index) then
		callbacks[index] = nil
		indexes[id] = nil
		hook_id[name][index] = nil
	else
		local ids = hook_id[name]

		callbacks[index] = callbacks[count]
		callbacks[count] = nil

		local lastid = ids[count]

		indexes[id] = nil
		indexes[lastid] = index

		ids[index] = lastid
		ids[count] = nil
	end
end

local function Add(name, id, callback)
	if isfunction(id) then
		callback = id
		id = debug_info(callback).short_src
	end

	if (not callback) then
		return
	end

	if (hook_callbacks[name] == nil) then
		hook_callbacks[name] = {}
		hook_index[name] 	 = {}
		hook_id[name] 	 = {}
	end

	if Exists(name, id) then
		Remove(name, id) -- properly simulate hook overwrite behavior
	end

	local callbacks = hook_callbacks[name]
	local indexes = hook_index[name]

	if (not isstring(id)) then
		local orig = callback
		callback = function(...)
			if IsValid(id) then
				return orig(id, ...)
			end

			local index = indexes[id]
			Remove(name, id)

			local nextcallback = callbacks[index]
			if (nextcallback ~= nil) then
				return nextcallback(...)
			end
		end
	end

	local index = #callbacks + 1
	callbacks[index] = callback
	indexes[id] = index
	hook_id[name][index] = id
end


hook = setmetatable({
	Remove = Remove,
	GetTable = GetTable,
	Exists = Exists,
	Add = Add,
	Call = Call,
	Run = Run
}, {
	__call = function(self, ...)
		return self.Add(...)
	end
})