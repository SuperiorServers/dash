local name = GetConVar('sv_skyname'):GetString()
local areas = {'lf', 'ft', 'rt', 'bk', 'dn', 'up'}
local maerials = {
	Material('skybox/'.. name .. 'lf'),
	Material('skybox/'.. name .. 'ft'),
	Material('skybox/'.. name .. 'rt'),
	Material('skybox/'.. name .. 'bk'),
	Material('skybox/'.. name .. 'dn'),
	Material('skybox/'.. name .. 'up'),
}
	 
function util.SetSkybox(skybox) -- Thanks someone from some fp post I cant find
	for i = 1, 6 do
		maerials[i]:SetTexture('$basetexture', Material('skybox/' .. skybox .. areas[i]):GetTexture('$basetexture'))
	end
end	