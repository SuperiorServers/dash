require 'redis.core' --https://github.com/SuperiorServers/gm_redis

if (redis.VersionNum < 10100) then
	ErrorNoHalt("gmsv_redis is out of date! Download the latest official release at https://github.com/SuperiorServers/gm_redis\n")
end

include 'redis.client.lua'
include 'redis.subscriber.lua'