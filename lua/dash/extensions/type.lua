local getmetatable 	= getmetatable
local tonumber 		= tonumber
local isentity		= isentity

local ENTITY 	= FindMetaTable 'Entity'
local PLAYER 	= FindMetaTable 'Player'
local WEAPON 	= FindMetaTable 'Weapon'
local NPC 		= FindMetaTable 'NPC'
local VEHICLE 	= FindMetaTable 'Vehicle'

function isnumber(v)
	return (v ~= nil) and (v == tonumber(v))
end

function isbool(v)
	return (v == true) or (v == false)
end

function isplayer(v)
	return isentity(v) and v:IsPlayer()
end


function ENTITY:IsPlayer()
	return false
end

function PLAYER:IsPlayer()
	return true
end

function WEAPON:IsPlayer()
	return false
end

function NPC:IsPlayer()
	return false
end

function VEHICLE:IsPlayer()
	return false
end


function ENTITY:IsWeapon()
	return false
end

function PLAYER:IsWeapon()
	return false
end

function WEAPON:IsWeapon()
	return true
end

function NPC:IsWeapon()
	return false
end

function VEHICLE:IsWeapon()
	return false
end


function ENTITY:IsNPC()
	return false
end

function PLAYER:IsNPC()
	return false
end

function WEAPON:IsNPC()
	return false
end

function NPC:IsNPC()
	return true
end

function VEHICLE:IsNPC()
	return false
end


function ENTITY:IsVehicle()
	return false
end

function PLAYER:IsVehicle()
	return false
end

function WEAPON:IsVehicle()
	return false
end

function NPC:IsVehicle()
	return false
end

function VEHICLE:IsVehicle()
	return true
end

if (SERVER) then
	function ENTITY:IsNextbot()
		return false
	end

	function PLAYER:IsNextbot()
		return false
	end

	function WEAPON:IsNextbot()
		return false
	end

	function NPC:IsNextbot()
		return false
	end

	function VEHICLE:IsNextbot()
		return false
	end


	local NEXTBOT = FindMetaTable 'NextBot'
	
	function NEXTBOT:IsPlayer()
		return false
	end

	function NEXTBOT:IsWeapon()
		return false
	end

	function NEXTBOT:IsNPC()
		return false
	end

	function NEXTBOT:IsVehicle()
		return false
	end

	function NEXTBOT:IsNextbot()
		return true
	end
else
	function ENTITY:IsCSEnt()
		return false
	end

	function PLAYER:IsCSEnt()
		return false
	end

	function WEAPON:IsCSEnt()
		return false
	end

	function NPC:IsCSEnt()
		return false
	end

	function VEHICLE:IsCSEnt()
		return false
	end


	local CSENT = FindMetaTable 'CSEnt'
	
	function CSEnt:IsPlayer()
		return false
	end

	function CSEnt:IsWeapon()
		return false
	end

	function CSEnt:IsNPC()
		return false
	end

	function CSEnt:IsVehicle()
		return false
	end

	function CSEnt:IsCSEnt()
		return true
	end
end
