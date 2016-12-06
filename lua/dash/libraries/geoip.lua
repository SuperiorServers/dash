geoip 			= {}

local geoip 		= geoip
local http_fetch 	= http.Fetch
local json_to_table 	= util.JSONToTable
local timer_simple 	= timer.simple

local result_cache	 = {}

function geoip.Get(ip, cback, failure, attempts)
	if result_cache[ip] then
		cback(result_cache[ip])
	else
		http_fetch('http://geoip.nekudo.com/api/' .. ip, function(b)
			if (b == '404 page not found') then
				error('GeoIP: Failed to lookup ip: ' .. ip)
			else
				local res = json_to_table(b)
				result_cache[ip] = res
				cback(res)
			end
		end, function()
			attempts = attempts or 0
			if (attempts <= 5) then
				timer_simple(5, function()
					geoip.Get(ip, cback, failure, attempts + 1)
				end)
			else
				failure()
			end
		end)
	end
end
