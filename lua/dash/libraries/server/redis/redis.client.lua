local REDIS_CLIENT = FindMetaTable 'redis_client'

local color_prefix, color_text = Color(225,0,0), Color(250,250,250)

local clients =	setmetatable({}, {__mode = 'v'})
local clientcount = 0

function redis.GetClients()
	for i = 1, clientcount do
		if (clients[i] == nil) then
			table.remove(clients, i)
			i = i - 1
			clientcount = clientcount - 1
		end
	end

	return clients
end

function redis.ConnectClient(hostname, port, password, database, autopoll, autocommit)
	for k, v in ipairs(redis.GetSubscribers()) do
		if (v.Hostname == hostname) and (v.Port == port) and (v.Password == password) and (v.Database == database) and (v.AutoPoll == autopoll) and (v.AutoCommit == autocommit) then
			v:Log('Recycled connection.')
			return v
		end
	end

	local self, err = redis.CreateClient()

	if (not self) then
		error(err)
	end

	self.Hostname = hostname
	self.Port = port
	self.Password = password
	self.AutoPoll = autopoll
	self.AutoCommit = autocommit
	self.Database = database or 0
	self.PendingCommands = 0

	if (not self:TryConnect(hostname, port, password, database)) then
		return self
	end

	if (autopoll ~= false) or (autocommit ~= false) then
		hook.Add('Think', self, function()
			if (autocommit ~= false) and (self.PendingCommands > 0) then
				self:Commit()
			end
			if (autopoll ~= false) then
				self:Poll()
			end
		end)
	end

	table.insert(clients, self)
	clientcount = clientcount + 1

	return self
end


-- Internal
function REDIS_CLIENT:OnDisconnected()
	if (not hook.Call('RedisClientDisconnected', nil, self)) then
		timer.Create('RedisClientRetryConnect', 1, 0, function()
			if (not IsValid(self)) or self:TryConnect(self.Hostname, self.Port, self.Password, self.Database) then
				timer.Destroy('RedisClientRetryConnect')
			end
		end)
	end
end

function REDIS_CLIENT:Wait(func, ...)
	local dat
	func(self, ..., function(self, ...)
		dat = {...}
	end)

	self:Commit()

	self.IsWaiting = true
	local endwait = SysTime() + 1

	while self.IsWaiting and (endwait >= SysTime()) and (dat == nil) do
		self:Poll()
	end

	self:StopWait()

	return unpack(dat)
end

function REDIS_CLIENT:StopWait()
	self.IsWaiting = false
end

function REDIS_CLIENT:TryConnect(ip, port, password, database)
	local succ, err = self:Connect(ip, port)

	if (not succ) then
		self:Log(err)
		return false
	end

	if (password ~= nil) then
		local resp = self:Wait(self.Auth, password)
		if (resp ~= 'OK') then
			self:Log(resp)
			return false
		end
	end

	if (database ~= nil) then
		local resp = self:Wait(self.Select, database)
		if (resp ~= 'OK') then
			self:Log(resp)
			return false
		end
	end

	self:Log('Connected successfully.')

	hook.Call('RedisClientConnected', nil, self)

	return true
end

function REDIS_CLIENT:Log(message)
	MsgC(color_prefix, '[Redis-Client] ', color_text, 'db' .. self.Database .. '@' .. self.Hostname .. ':' .. self.Port .. ' => ', tostring(message) .. '\n')
end

local send = REDIS_CLIENT.Send
function REDIS_CLIENT:Send(tab, callback)
	self.PendingCommands = self.PendingCommands + 1
	return send(self, tab, callback)
end

local publish = REDIS_CLIENT.Publish
function REDIS_CLIENT:Publish(channel, value, callback)
	self.PendingCommands = self.PendingCommands + 1
	return publish(self, channel, value, callback)
end

local commit = REDIS_CLIENT.Commit
function REDIS_CLIENT:Commit()
	self.PendingCommands = 0
	return commit(self)
end


function REDIS_CLIENT:Auth(password, callback)
	return self:Send({'AUTH', password}, callback)
end

function REDIS_CLIENT:Select(database, callback)
	return self:Send({'SELECT', database}, callback)
end

function REDIS_CLIENT:State(callback)
	return self:Send({'CLUSTER', 'INFO'}, callback)
end

function REDIS_CLIENT:Save(callback)
	return self:Send('BGSAVE', callback)
end

function REDIS_CLIENT:LastSave(callback)
	return self:Send('LASTSAVE', callback)
end

-- Strings: https://redis.io/commands#string
function REDIS_CLIENT:Append(key, value, callback)
	return self:Send({'APPEND', key, value}, callback)
end

function REDIS_CLIENT:BitCount(key, value, starti, endi, callback)
	return self:Send({'BITCOUNT', key, starti, endi}, callback)
end

function REDIS_CLIENT:Set(key, value, callback)
	return self:Send({'SET', key, value}, callback)
end

function REDIS_CLIENT:SetEx(key, secs, value, callback)
	return self:Send({'SETEX', key, secs, value}, callback)
end

function REDIS_CLIENT:Get(key, callback)
	return self:Send({'GET', key}, callback)
end

function REDIS_CLIENT:Exists(key, callback)
	return self:Send({'EXISTS', key}, callback)
end

function REDIS_CLIENT:Expire(key, secs, callback)
	return self:Send({'EXPIRE', key, secs}, callback)
end

function REDIS_CLIENT:TTL(key, callback)
	return self:Send({'TTL', key}, callback)
end

function REDIS_CLIENT:Delete(key, callback)
	return self:Send({'DEL', key}, callback)
end

function REDIS_CLIENT:Publish(channel, message, callback)
	return self:Send({'PUBLISH', channel, message}, callback)
end


-- Config
function REDIS_CLIENT:GetConfig(param, callback)
	return self:Send({'CONFIG', 'GET', param}, callback)
end

function REDIS_CLIENT:SetConfig(param, value, callback)
	return self:Send({'CONFIG', 'SET', param, value}, callback)
end


-- Lists: https://redis.io/commands#list
function REDIS_CLIENT:BLPop(key, keys, timeout, callback)
	return self:Send({'BLPOP', key, unpack(keys), timeout}, callback)
end

function REDIS_CLIENT:BRPop(key, keys, timeout, callback)
	return self:Send({'BRPOP', key, unpack(keys), timeout}, callback)
end

function REDIS_CLIENT:BRPopLPush(source, destination, callback)
	return self:Send({'BRPOP', source, destination}, callback)
end

function REDIS_CLIENT:LIndex(key, callback)
	return self:Send({'LINDEX', key}, callback)
end

function REDIS_CLIENT:LInsert(key, value, callback)
	return self:Send({'LINSERT', key, value}, callback)
end

function REDIS_CLIENT:LLen(key, callback)
	return self:Send({'LLEN', key}, callback)
end

function REDIS_CLIENT:LPop(key, callback)
	return self:Send({'LPOP', key}, callback)
end

function REDIS_CLIENT:LPush(key, values, callback)
	return self:Send({'LPUSH', key, isstring(values) and values or unpack(values)}, callback)
end

function REDIS_CLIENT:LPushX(key, value, callback)
	return self:Send({'LPUSHX', key, value}, callback)
end

function REDIS_CLIENT:LRange(key, start, stop, callback)
	return self:Send({'LRANGE', key, start, stop}, callback)
end

function REDIS_CLIENT:LRem(key, count, value, callback)
	return self:Send({'LREM', key, count, value}, callback)
end

function REDIS_CLIENT:LSet(key, index, value, callback)
	return self:Send({'LSET', key, index, value}, callback)
end

function REDIS_CLIENT:LTrim(key, start, stop, callback)
	return self:Send({'LSET', key, start, stop}, callback)
end

function REDIS_CLIENT:LPop(key, callback)
	return self:Send({'LPOP', key}, callback)
end

function REDIS_CLIENT:RPopLPush(source, destination, callback)
	return self:Send({'RPOPLPUSH', source, destination}, callback)
end

function REDIS_CLIENT:RPush(key, values, callback)
	return self:Send({'RPUSH', key, isstring(values) and values or unpack(values)}, callback)
end

function REDIS_CLIENT:RPushX(key, value, callback)
	return self:Send({'PRUSHX', key, value}, callback)
end

--https://redis.io/commands#hash
function REDIS_CLIENT:HMGet(key, values, callback)
	return self:Send({'HMGET', key, isstring(values) and values or unpack(values)}, callback)
end