geoip 				= {}

local geoip 		= geoip
local http_fetch 	= http.Fetch
local json_to_table = util.JSONToTable

local failures		 = 0
local result_cache	 = {}


function geoip.Get(ip, cback, failure)
	if result_cache[ip] then
		cback(result_cache[ip])
	else
		http_fetch('http://geoip.nekudo.com/api/' .. ip, function(b)
			if (b == '404 page not found') then
				error('GeoIP: Failed to lookup ip: ' .. ip)
			else
				local res = json_to_table(b)
				failures = 0
				result_cache[ip] = res
				cback(res)
			end
		end, function()
			if (failures <= 5) then 
				timer.Simple(5, function()
					failures = failures + 1
					geoip.Get(ip, cback, failure)
				end)
			else
				failure()
			end
		end)
	end
end
