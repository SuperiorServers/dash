-- Always wear a wrapper

require("tmysql4")

mysqloo = {
	VERSION = "8.2 tmysql4",
	MYSQL_VERSION = MYSQL_VERSION,
	MYSQL_INFO = MYSQL_INFO,

	DATABASE_CONNECTED = 0,
	DATABASE_CONNECTING = 1,
	DATABASE_NOT_CONNECTED = 2,
	DATABASE_INTERNAL_ERROR = 3,

	QUERY_NOT_RUNNING = 0,
	QUERY_RUNNING = 1,
	QUERY_READING_DATA = 2,
	QUERY_COMPLETE = 3,
	QUERY_ABORTED = 4,

	OPTION_NUMERIC_FIELDS = 1,
	OPTION_NAMED_FIELDS = 2,
	OPTION_INTERPRET_DATA = 4,
	OPTION_CACHE = 8,

	CLIENT_MULTI_STATEMENTS = CLIENT_MULTI_STATEMENTS,
	CLIENT_MULTI_RESULTS = CLIENT_MULTI_RESULTS,
	CLIENT_INTERACTIVE = CLIENT_INTERACTIVE,
}

local gofuckurself = {}
gofuckurself.__index = gofuckurself

local seriouslyeatadick = {}
seriouslyeatadick.__index = seriouslyeatadick

function mysqloo.connect(host, username, password, database, port, sockt, flags)
	return setmetatable({
		db = tmysql.Create(host, username, password, database, port, sockt, flags),
		internalerror = false,
	},gofuckurself)
end

function gofuckurself:connect()
	if self.db:IsConnected() then return end -- prevent retardation
	
	local success, err = self.db:Connect()

	if not success then
		self.internalerror = true
		self:onConnectionFailed(err)
		return
	end

	self:onConnected()
end

function gofuckurself:onConnected()
	-- Blank function that gets overwritten
end

function gofuckurself:onConnectionFailed(err)
	-- Blank function that gets overwritten
end

function gofuckurself:query(query)
	return setmetatable({
		db = self.db,
		query = query,
		running = false,
		complete = false,
		error = "",
		lastid = 0,
		affected = 0,
		data = {},
		abort = false,
		option = mysqloo.OPTION_NAMED_FIELDS,
	},seriouslyeatadick)
end

function gofuckurself:setCharset(str)
	self.db:SetCharacterSet(str) -- Look at me, adding fuctionality to mysqloo WHAT A NICE GUY I AM
end

function gofuckurself:escape(str)
	return self.db:Escape(str)
end

function gofuckurself:abortAllQueries()
	-- rofl go fuck urself
end

function gofuckurself:status()
	if self.db:IsConnected() then
		return mysqloo.DATABASE_CONNECTED
	elseif self.internalerror then
		return mysqloo.DATABASE_INTERNAL_ERROR
	else
		return mysqloo.DATABASE_NOT_CONNECTED
	end
	-- ya fuk u im not supporting the other bullshit
end

function gofuckurself:wait()
	-- ya seriously, if you think im going to support this you can FUCK RIGHT OFF
end

function gofuckurself:serverVersion()
	return self.db:GetServerVersion()
end

function gofuckurself:serverInfo()
	return self.db:GetServerInfo()
end

function gofuckurself:hostInfo()
	return self.db:GetHostInfo()
end

function seriouslyeatadick:start()
	self.running = true
	self.db:Query(self.query, function(results)
		if self.abort then return end -- yeah, deal with it

		self.doingdata = true

		results = results[1] -- xd skip all other data sets BECAUSE WHY NOT
		self.error = results.error
		self.lastid = results.lastid
		self.affected = results.affected
		self.data = results.data
		if results.status then
			for k,v in pairs(self.data) do
				self:onData(v)
			end
			self:onSuccess(self.data)
		else
			self:onError(self.error, self.query)
		end

		self.doingdata = false
		self.complete = true
	end, nil, (self.option == mysqloo.OPTION_NUMERIC_FIELDS))
end

function seriouslyeatadick:onSuccess(data)
	-- Blank function that gets overwritten
end

function seriouslyeatadick:onData(data)
	-- Blank function that gets overwritten
end

function seriouslyeatadick:onError(err)
	-- Blank function that gets overwritten
end

function seriouslyeatadick:isRunning()
	return self.running
end

function seriouslyeatadick:getData()
	return self.data
end

function seriouslyeatadick:abort()
	self.abort = true
end

function seriouslyeatadick:lastInsert()
	return self.lastid
end

function seriouslyeatadick:affectedRows()
	return self.affected
end

function seriouslyeatadick:status() -- OH BOY
	if self.doingdata then
		return mysqloo.QUERY_READING_DATA
	elseif self.abort then
		return mysqloo.QUERY_ABORTED
	elseif self.complete then
		return mysqloo.QUERY_COMPLETE
	elseif self.running then
		return mysqloo.QUERY_RUNNING
	else
		return mysqloo.QUERY_NOT_RUNNING
	end
end

function seriouslyeatadick:setOption(option)
	self.option = option
end

function seriouslyeatadick:wait()
	ErrorNoHalt('query:wait() is not supported. stop using mysqloo you prick')
end

function seriouslyeatadick:error()
	return self.error
end