local WEAPON, ENTITY = FindMetaTable 'Weapon', FindMetaTable 'Entity'
local GetTable = ENTITY.GetTable
local GetOwner = ENTITY.GetOwner

local garryisaretard = 'Owner'
function WEAPON:__index(key)
	local value = WEAPON[key] or ENTITY[key] or GetTable(self)[key]

	if value then return value end

	if (key == garryisaretard) then return GetOwner(self) end
end