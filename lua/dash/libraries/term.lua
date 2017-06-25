term = setmetatable({},{
	__call = function(self, ...)
		return self.Add(...)
	end
})

local staging 	= {}
local terms 	= {}
local mapping 	= {}
local varcount 	= {}
local bitcount 	= 10
local issorted  = false

local function addterm(name, message)
	local _, reps 	= message:gsub('#', '#') -- replace with %s later
	local i 		= #terms + 1
	mapping[name] 	= i
	terms[i] 		= message
	varcount[i]		= reps
end

local function sort()
	for k, v in SortedPairsByMemberValue(staging, 'Name', false) do
		addterm(v.Name, v.Message)
	end
	issorted = true
end
hook.Add('InitPostEntity', 'term.sort.InitPostEntity', sort)

function term.Add(name, message)
	local name = tostring(name)
	staging[mapping[name] or (#staging + 1)] = {
		Name 	= name,
		Message = message,
	}
	if issorted and (not mapping[name]) then
		timer.Create('terms.Sort', 0, 1, function() -- Do this only once the next frame incase we refresh a lot of terms at once
			table.Empty(terms)
			table.Empty(mapping)
			table.Empty(varcount)
			sort()
		end)
	end
end

function term.Exists(id)
	return (terms[id] ~= nil) or (mapping[tostring(id)] ~= nil)
end

function term.Get(name)
	return mapping[tostring(name)]
end

function term.GetString(id)
	return terms[id]
end

function net.WriteTerm(id, ...)
	net.WriteUInt(id, bitcount)
	for i = 1, varcount[id] do
		local v = select(i, ...)
		if isplayer(v) then
			net.WriteUInt(0, 2)
			net.WritePlayer(v)
		elseif isentity(v) then
			net.WriteUInt(1, 2)
			net.WriteEntity(v)
		elseif isnumber(v) then
			net.WriteUInt(2, 2)
			net.WriteUInt(v, 32)
		else
			net.WriteUInt(3, 2)
			net.WriteString(tostring(v))
		end
	end
end

function net.ReadTerm()
	return terms[net.ReadUInt(bitcount)]:gsub('#', function()
		local t = net.ReadUInt(2)
		if (t == 0) then
			local v = net.ReadPlayer()
			return IsValid(v) and v:Name() or 'Unknown'
		elseif (t == 1) then
			local v = net.ReadEntity()
			return IsValid(v) and (v.PrintName or v:GetClass()) or 'Unknown Entity'
		elseif (t == 2) then
			return tostring(net.ReadUInt(32))
		end
		return net.ReadString()
	end)
end