local WEAPON, ENTITY = FindMetaTable 'Weapon', FindMetaTable 'Entity'
local GetTable = ENTITY.GetTable
local GetOwner = ENTITY.GetOwner

local ownerkey = 'Owner'
function WEAPON:__index(key)
	local value = WEAPON[key] or ENTITY[key] or GetTable(self)[key]

	if value ~= nil then return value end

	if (key == ownerkey) then return GetOwner(self) end
end