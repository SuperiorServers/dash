require 'hash'

local luaAES = dash.IncludeSH 'dash/submodules/lua_aes/AES.lua'

aes = {
	Encrypt = function(key, data)
		return luaAES.ECB_256(luaAES.encrypt, tonumber(hash.SHA256('0x' .. key)), data)
	end,
	Decrypt = function(key, data)
		return luaAES.ECB_256(luaAES.decrypt, tonumber(hash.SHA256('0x' .. key)), data)
	end
}