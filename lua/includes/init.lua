-- Init
if (SERVER) then
	AddCSLuaFile()
	AddCSLuaFile 'dash/init.lua'
end
include 'dash/init.lua'

dash.IncludeSH '_init.lua'

-- Extensions
for k, v in pairs(dash.LoadDir('extensions')) do
	dash.IncludeSH(v)
end
for k, v in pairs(dash.LoadDir('extensions/server')) do
	dash.IncludeSV(v)
end
for k, v in pairs(dash.LoadDir('extensions/client')) do
	dash.IncludeCL(v)
end