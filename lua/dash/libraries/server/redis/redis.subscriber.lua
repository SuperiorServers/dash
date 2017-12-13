local REDIS_SUBSCRIBER = FindMetaTable 'redis_subscriber'

local color_prefix, color_text = Color(225,0,0), Color(250,250,250)

local subscribers =	setmetatable({}, {__mode = 'v'})
local subscribercount = 0

function redis.GetSubscribers()
	for i = 1, subscribercount do
		if subscribers[i] == nil then
			table.remove(subscribers, i)
			i = i - 1
			subscribercount = subscribercount - 1
		end
	end

	return subscribers
end

function redis.ConnectSubscriber(hostname, port, autopoll, autocommit) -- no auth like clients, iptables or localhost it I suppose.
	for k, v in ipairs(redis.GetSubscribers()) do
		if (v.Hostname == hostname) and (v.Port == port) and (v.AutoPoll == autopoll) and (v.AutoCommit == autocommit) then
			v:Log('Recycled connection.')
			return v
		end
	end

	local self, err = redis.CreateSubscriber()

	if (not self) then
		error(err)
	end

	self.Hostname = hostname
	self.Port = port
	self.AutoPoll = autopoll
	self.AutoCommit = autocommit
	self.PendingCommands = 0
	self.Subscriptions = {}
	self.PSubscriptions = {}

	if (not self:TryConnect(hostname, port)) then
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

	table.insert(subscribers, self)
	subscribercount = subscribercount + 1

	return self
end


-- Internal
function REDIS_SUBSCRIBER:OnMessage(channel, message) -- No point in doing our own hook system
	hook.Call('RedisSubscriberMessage', nil, self, channel, message)
end

function REDIS_SUBSCRIBER:OnDisconnected()
	if (not hook.Call('RedisSubscriberDisconnected', nil, self)) then
		timer.Create('RedisSubscriberRetryConnect', 1, 0, function()
			if (not IsValid(self)) or self:TryConnect(self.Hostname, self.Port) then
				timer.Destroy('RedisSubscriberRetryConnect')
			end
		end)
	end
end

function REDIS_SUBSCRIBER:TryConnect(ip, port)
	local succ, err = self:Connect(ip, port)

	if (not succ) then
		self:Log(err)
		return false
	end

	self.PendingCommands = self.PendingCommands or 0

	self:Log('Connected successfully.')

	hook.Call('RedisSubscriberConnected', nil, self)

	for k, v in pairs(self.Subscriptions) do
		self:Subscribe(v.Channel, v.Callback, v.OnMessage)
	end

	for k, v in pairs(self.PSubscriptions) do
		self:PSubscribe(v.Channel, v.Callback, v.OnMessage)
	end

	return true
end

function REDIS_SUBSCRIBER:Log(message)
	MsgC(color_prefix, '[Redis-Subscriber] ', color_text, self.Hostname .. ':' .. self.Port .. ' => ', tostring(message) .. '\n')
end

local commit = REDIS_SUBSCRIBER.Commit
function REDIS_SUBSCRIBER:Commit()
	self.PendingCommands = 0
	return commit(self)
end

local subscribe = REDIS_SUBSCRIBER.Subscribe
function REDIS_SUBSCRIBER:Subscribe(channel, callback, onmessage)
	if onmessage then
		hook.Add('RedisSubscriberMessage', channel, function(db, _channel, message)
			if (db == self) and (_channel == channel) then
				return onmessage(self, message)
			end
		end)
	end
	self.Subscriptions[channel] = {
		Channel = channel,
		Callback = callback,
		OnMessage = onmessage
	}
	self.PendingCommands = self.PendingCommands + 1
	return subscribe(self, channel, callback)
end

local unsubscribe = REDIS_SUBSCRIBER.Unsubscribe
function REDIS_SUBSCRIBER:Unsubscribe(channel, callback)
	hook.Remove('RedisSubscriberMessage', channel)
	self.Subscriptions[channel] = nil
	self.PendingCommands = self.PendingCommands + 1
	return unsubscribe(self, channel, callback)
end

local psubscribe = REDIS_SUBSCRIBER.PSubscribe
function REDIS_SUBSCRIBER:PSubscribe(channel, callback, onmessage)
	if onmessage then
		hook.Add('RedisPSubscriberMessage', channel, function(db, _channel, message)
			if (db == self) and (_channel == channel) then
				return onmessage(self, message)
			end
		end)
	end
	self.PSubscriptions[channel] = {
		Channel = channel,
		Callback = callback,
		OnMessage = onmessage
	}
	self.PendingCommands = self.PendingCommands + 1
	return psubscribe(self, channel, callback)
end

local punsubscribe = REDIS_SUBSCRIBER.PUnsubscribe
function REDIS_SUBSCRIBER:PUnsubscribe(channel, callback)
	hook.Remove('RedisPSubscriberMessage', channel)
	self.PSubscriptions[channel] = nil
	self.PendingCommands = self.PendingCommands + 1
	return punsubscribe(self, channel, callback)
end
