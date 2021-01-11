require 'tmysql4'

if (not tmysql.Version) or (tmysql.Version < 4.1) then
	error 'tmysql version is too old! Install 4.1 or later.'
end

mysql = setmetatable({
	GetTable = setmetatable({}, {
		__call = function(self)
			return self
		end
	}),

	QueryCount = 0
}, {
	__call = function(self, ...)
		return self.Connect(...)
	end
})

local DATABASE = {
	__tostring = function(self)
		return self.Username .. ":" .. self.Database .. '@' .. self.Hostname .. ':' ..  self.Port
	end
}
DATABASE.__concat 	= DATABASE.__tostring
DATABASE.__index 	= DATABASE

local STATEMENT = {
	__tostring = function(self)
		return self.Query
	end,
	__call = function(self, ...)
		return self:Run(...)
	end
}
STATEMENT.__concat 	= STATEMENT.__tostring
STATEMENT.__index 	= STATEMENT

_R.MySQLDatabase 	= DATABASE
_R.MySQLStatement 	= STATEMENT

local tostring 		= tostring
local SysTime 		= SysTime
local pairs 		= pairs
local select 		= select
local isfunction 	= isfunction
local string_format = string.format
local string_gsub 	= string.gsub
local string_rep	= string.rep

local color_prefix, color_text = Color(185,0,255), Color(250,250,250)

local query_queue	= {}

function mysql.Connect(hostname, username, password, database, port, optional_socketpath, optional_clientflags, optional_connectcallback)
	local db_obj = setmetatable({
		Hostname = hostname,
		Username = username,
		Password = password,
		Database = database,
		Port 	 = port,
	}, DATABASE)

	local cached = mysql.GetTable[tostring(db_obj)]
	if cached and cached.Handle:IsValid() then
		cached:Log('Recycled connection.')
		return cached
	end

	db_obj.Handle, db_obj.Error = tmysql.Connect(hostname, username, password, database, port, optional_socketpath, optional_clientflags, optional_connectcallback)

	--db_obj.Handle:Query('show tables', PrintTable)

	if db_obj.Error then
		db_obj:Log(db_obj.Error)
	elseif (db_obj.Handle == false) then
		db_obj:Log('Connection failed with unknown error!')
	else
		mysql.GetTable[tostring(db_obj)] = db_obj

		db_obj:Log('Connected successfully.')
	end

	hook.Add('Think', db_obj.Handle, function()
		db_obj.Handle:Poll()
	end)

	--self:SetOption(MYSQL_SET_CLIENT_IP, GetConVarString('ip'))
	--self:Connect()

	return db_obj
end


function DATABASE:Connect()
	return self.Handle:Connect()
end

function DATABASE:Disconnect()
	return self.Handle:Disconnect()
end

function DATABASE:Poll()
	self.Handle:Poll()
end

function DATABASE:Escape(value)
	return (value ~= nil) and self.Handle:Escape(tostring(value))
end

function DATABASE:Log(message)
	MsgC(color_prefix, '[MySQL] ', color_text, tostring(self) .. ' => '.. tostring(message) .. '\n')
end

local quote = '"'
local retry_errors = {
	[2013] = true, -- Lost connection to MySQL server during query
	[2006] = true, -- MySQL server has gone away
	[1243] = true, -- Unknown prepared statement handler (module should re-prepare and not pass this error, but better safe than sorry)
	[1053] = true, -- Server shutdown in progress (hopefully the server is only restarting)
}

local function getQueryID()
	mysql.QueryCount = mysql.QueryCount + 1
	return mysql.QueryCount - 1
end

local function handlequery(id, db, query, results, cback, tries)
	if (results[1].error ~= nil) then
		db:Log("[" .. results[1].errorid .. "] " .. results[1].error)
		db:Log(query)
		if retry_errors[results[1].errorid] then
			if (tries < 5) then
				db:Log("Will retry again")
				query_queue[id] = {
					Id		= id,
					Db 		= db,
					Query 	= query,
					Trys 	= tries + 1,
					Cback 	= cback
				}
			else
				db:Log("Maximum retries attempted - giving up")
			end
		end
	else
		query_queue[id] = nil
		if (cback) then
			cback(results[1].data, results[1].lastid, results[1].affected, results[1].time)
		end
	end
end

local function handlestatement(id, db, stmt, values, varcount, results, cback, tries)
	if (results[1].error ~= nil) then
		db:Log("[" .. results[1].errorid .. "] " .. results[1].error)
		db:Log(stmt.Query)
		if retry_errors[results[1].errorid] then
			if (tries < 5) then
				db:Log("Will retry again")
				query_queue[id] = {
					Id		= id,
					Db 		= db,
					Stmt 	= stmt,
					Trys 	= tries + 1,
					Cback 	= cback,
					Values	= values,
					VarCount= varcount
				}
			else
				db:Log("Maximum retries attempted - giving up")
			end
		end
	else
		query_queue[id] = nil
	 	if (cback) then
			cback(results[1].data, results[1].lastid, results[1].affected, results[1].time)
		end
	end
end

local function runQuery(id, db, query, cback, tries)
	db.Handle:Query(query, function(results)
		handlequery(id, db, query, results, cback, (tries or 0))
	end)
end

local function runStatement(id, db, stmt, values, varcount, cback, tries)
	values[varcount + 1] = function(results)
		handlestatement(id, db, stmt, values, varcount, results, cback, (tries or 0))
	end

	stmt.Statement:Run(unpack(values, 1, varcount + 2))
end

function DATABASE:Query(query, ...)
	local args = {...}
	local count = 0
	query = query:gsub('?', function()
		count = count + 1
		return (args[count] ~= nil) and (quote .. self:Escape(args[count]) .. quote) or 'NULL'
	end)

	runQuery(getQueryID(), self, query, args[count + 1])
end

function DATABASE:QuerySync(query, ...)
	local data, lastid, affected, time
	local start = SysTime() + 0.3
	if (... == nil) then
		self:Query(query, function(_data, _lastid, _affected, _time)
			data, lastid, affected, time = _data, _lastid, _affected, _time
		end)
	else
		self:Query(query, ..., function(_data, _lastid, _affected, _time)
			data, lastid, affected, time = _data, _lastid, _affected, _time
		end)
	end

	while (not data) and (start >= SysTime()) do
		self:Poll()
	end
	return data, lastid, affected, time
end

function DATABASE:Prepare(query)
	local dbhandle 		= self.Handle
	local db 			= self
	local values		= {}

	if (tmysql.Version >= 4.3) then -- Support native prepared statements
		local statement, err = dbhandle:Prepare(query)

		if (statement == nil) then
			self:Log("Error while preparing statement")
			self:Log(err)
			return
		end

		local varcount = statement:GetArgCount()

		return setmetatable({
			Handle = self.Handle,
			Query = query,
			Count = varcount,
			Statement = statement,
			Run = function(self, ...)
				local cback = select(varcount + 1, ...)
				for i = 1, varcount do
					local value = select(i, ...)
					values[i] = value
				end

				runStatement(getQueryID(), db, self, values, varcount, cback)
			end,
		}, STATEMENT)
	else -- Fake news
		local _, varcount 	= string_gsub(query, '?', '?')
		query = string.Replace(query, '?', '%s')
		return setmetatable({
			Handle = self.Handle,
			Query = query,
			Count = varcount,
			Values = values,
			Run = function(self, ...)
				local cback = select(varcount + 1, ...)
				for i = 1, varcount do
					local value = select(i, ...)
					values[i] = (value ~= nil) and (quote .. db:Escape(value) .. quote) or 'NULL'
				end
				local query = string_format(query, unpack(values))

				runQuery(getQueryID(), db, query, cback)
			end,
		}, STATEMENT)
	end
end


function DATABASE:SetCharacterSet(charset)
	self.Handle:SetCharacterSet(charset)
end

function DATABASE:SetOption(opt, value)
	self.Handle:SetOption(opt, value)
end


function DATABASE:GetServerInfo()
	return self.Handle:GetServerInfo()
end

function DATABASE:GetHostInfo()
	return self.Handle:GetHostInfo()
end

function DATABASE:GetServerVersion()
	return self.Handle:GetServerVersion()
end

--[[function STATEMENT:Run(...)

end]]

function STATEMENT:RunSync(...)
	local data, lastid, affected, time
	local start = SysTime() + 0.3

	if (... == nil) then
		self:Run(..., function(_data, _lastid, _affected, _time)
			data, lastid, affected, time = _data, _lastid, _affected, _time
		end)
	else
		self:Run(function(_data, _lastid, _affected, _time)
			data, lastid, affected, time = _data, _lastid, _affected, _time
		end)
	end

	while (not data) and (start >= SysTime()) do
		self.Handle:Poll()
	end
	return data, lastid, affected, time
end

function STATEMENT:GetQuery()
	return self.Query
end

function STATEMENT:GetCount()
	return self.Count
end

function STATEMENT:GetDatabase()
	return self.Handle
end


timer.Create('mysql.QueryQueue', 5, 0, function()
	for k, v in pairs(query_queue) do
		if (v.Stmt) then
			runStatement(v.Id, v.Db, v.Stmt, v.Values, v.VarCount, v.Cback, v.Trys)
		else
			runQuery(v.Id, v.Db, v.Query, v.Cback, v.Trys)
		end
	end

	table.Empty(query_queue)
end)