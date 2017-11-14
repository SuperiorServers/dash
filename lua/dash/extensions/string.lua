function string.Random(chars)
	local str = ''
	for i = 1, (chars or 10) do
		str = str .. string.char(math.random(97, 122))
	end
	return str
end

function string:StartsWith(str)
	return (self:sub(1, str:len()) == str)
end

function string:Apostrophe()
	local len = self:len()
	return (self:sub(len, len):lower() == 's') and '\'' or '\'s'
end

function string:AOrAn()
	return self:match('^h?[AaEeIiOoUu]') and 'an' or 'a'
end

function string:IsSteamID32(str)
	return self:match('^STEAM_%d:%d:%d+$')
end

function string:IsSteamID64()
	return (self:len() == 17) and (self:sub(1, 4) == '7656')
end

function string:HtmlSafe()
    return self:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
end

local formathex = '%%%02X'
function string:URLEncode()
	return string.gsub(string.gsub(string.gsub(self, '\n', '\r\n'), '([^%w ])', function(c)
		return string.format(formathex, string.byte(c))
	end), ' ', '+')
end

function string:URLDecode()
	return self:gsub('+', ' '):gsub('%%(%x%x)', function(hex)
		return string.char(tonumber(hex, 16))
	end)
end

function string.ExplodeQuotes(str) -- Re-do this one of these days
	str = ' ' .. str .. ' '
	local res = {}
	local ind = 1
	while true do
		local sInd, start = str:find('[^%s]', ind)
		if not sInd then break end
		ind = sInd + 1
		local quoted = str:sub(sInd, sInd):match('["\']') and true or false
		local fInd, finish = str:find(quoted and '["\']' or '[%s]', ind)
		if not fInd then break end
		ind = fInd + 1
		local str = str:sub(quoted and sInd + 1 or sInd, fInd - 1)
		res[#res + 1] = str
	end
	return res
end

function string:StripPort()
	local p = self:find(':')
	return (not p) and ip or self:sub(1, p - 1)
end

function string.FromNumbericIP(ip)
	ip = tonumber(ip)
	return bit.rshift(bit.band(ip, 0xFF000000), 24) .. '.' .. bit.rshift(bit.band(ip, 0x00FF0000), 16) .. '.' .. bit.rshift(bit.band(ip, 0x0000FF00), 8) .. '.' .. bit.band(ip, 0x000000FF)
end

-- Stolen from maestro
local TIME_SECOND 	= 1
local TIME_MINUTE 	= TIME_SECOND * 60
local TIME_HOUR 	= TIME_MINUTE * 60
local TIME_DAY 		= TIME_HOUR * 24
local TIME_WEEK 	= TIME_DAY * 7
local TIME_MONTH 	= TIME_DAY * (365.2425/12)
local TIME_YEAR 	= TIME_DAY * 365.2425

local function plural(a, n)
	return (n == 1) and a or  a .. 's'
end

function string.FormatTime(num, limit)
	local ret = {}
	while (not limit) or (limit ~= 0) do
		local templimit = limit or 0

		if (num >= TIME_YEAR) or (templimit <= -7) then
			local c = math.floor(num / TIME_YEAR)
			ret[#ret + 1] = c .. ' ' .. plural('year', c)
			num = num - TIME_YEAR * c
		elseif (num >= TIME_MONTH) or (templimit <= -6) then
			local c = math.floor(num / TIME_MONTH)
			ret[#ret + 1] = c .. ' ' .. plural('month', c)
			num = num - TIME_MONTH * c
		elseif (num >= TIME_WEEK) or (templimit <= -5) then
			local c = math.floor(num / TIME_WEEK)
			ret[#ret + 1] = c .. ' ' .. plural('week', c)
			num = num - TIME_WEEK * c
		elseif (num >= TIME_DAY) or (templimit <= -4)then
			local c = math.floor(num / TIME_DAY)
			ret[#ret + 1] = c .. ' ' .. plural('day', c)
			num = num - TIME_DAY * c
		elseif (num >= TIME_HOUR) or (templimit <= -3) then
			local c = math.floor(num / TIME_HOUR)
			ret[#ret + 1] = c .. ' ' .. plural('hour', c)
			num = num - TIME_HOUR * c
		elseif (num >= TIME_MINUTE) or (templimit <= -2) then
			local c = math.floor(num / TIME_MINUTE)
			ret[#ret + 1] = c .. ' ' .. plural('minute', c)
			num = num - TIME_MINUTE * c
		elseif num >= TIME_SECOND or (templimit <= -1) then
			local c = math.floor(num / TIME_SECOND)
			ret[#ret + 1] = c .. ' ' .. plural('second', c)
			num = num - TIME_SECOND * c
		else
			break
		end

		if limit then
			if limit > 0 then
				limit = limit - 1
			else
				limit = limit + 1
			end
		end
	end

	local str = ''
	for i = 1, #ret do
		if i == 1 then
			str = str .. ret[i]
		elseif i == #ret then
			str = str .. ' and ' .. ret[i]
		else
			str = str .. ', ' .. ret[i]
		end
	end

	return str
end

-- Faster implementation
local totable = string.ToTable
local string_sub = string.sub
local string_find = string.find
local string_len = string.len
function string.Explode(separator, str, withpattern)
	if (separator == '') then return totable(str) end

	if withpattern == nil then
		withpattern = false
	end

	local ret = {}
	local current_pos = 1

	for i = 1, string_len(str) do
		local start_pos, end_pos = string_find(str, separator, current_pos, not withpattern)
		if not start_pos then break end
		ret[i] = string_sub(str, current_pos, start_pos - 1)
		current_pos = end_pos + 1
	end

	ret[#ret + 1] = string_sub(str, current_pos)

	return ret
end

function string:MaxCharacters(num, withellipses)
	if (#self <= num) then return self end

	local str = self:sub(1, num)

	return withellipses and (str .. '...') or str
end