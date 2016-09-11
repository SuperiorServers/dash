--- Trace
function util.ClearTrace()
	-- To prevent people from screwing up vector_origin
	local vNewOrigin = Vector( 0, 0, 0 )
	
	return { Entity = NULL,
		Fraction = 1,
		FractionLeftSolid = 0,
		Hit = false,
		HitBox = 0,
		HitGroup = 0,
		HitNoDraw = false,
		HitNonWorld = false,
		HitNormal = vNewOrigin,
		HitPos = vNewOrigin,
		HitSky = false,
		HitTexture = "**empty**",
		HitWorld = false,
		MatType = 0,
		Normal = vNewOrigin,
		PhysicsBone = 0,
		StartPos = vNewOrigin,
		SurfaceProps = 0,
		StartSolid = false,
		AllSolid = false
	}
end

--- GameMovement
function util.TracePlayerBBox( tbl, pPlayer )
	tbl.mins, tbl.maxs = pPlayer:Crouching() and pPlayer:GetHullDuck() or pPlayer:GetHull()
	tbl.filter = tbl.filter or pPlayer
	
	return util.TraceRay( tbl )
end

function util.TracePlayerBBoxForGround( tbl, tr )
	tbl.output = nil
	local flFraction = tr.Fraction
	local vEndPos = tr.HitPos
	local vOldMaxs = tbl.maxs
	
	// Check the -x, -y quadrant
	local flTemp = vOldMaxs.x
	local Temp2 = vOldMaxs.y
	tbl.maxs = Vector( flTemp > 0 and 0 or flTemp, Temp2 > 0 and 0 or Temp2, vOldMaxs.z )
	local trTemp = util.TraceRay( tbl )

	if ( trTemp.HitNormal >= 0.7 and trTemp.Entity ~= NULL ) then
		trTemp.Fraction = flFraction
		trTemp.HitPos = vEndPos
		table.CopyFromTo( trTemp, tr )
		
		return tr
	end
	
	-- Re-use vector
	local Temp2 = tbl.maxs
	local vOldMins = tbl.mins
	flTemp = vOldMins.x
	Temp2.x = flTemp < 0 and 0 or flTemp
	flTemp = vOldMins.y
	Temp2.y = flTemp < 0 and 0 or flTemp
	Temp2.z = vOldMins.z
	tbl.mins = Temp2
	tbl.maxs = vOldMaxs
	tbl.output = trTemp
	util.TraceRay( tbl )

	if ( trTemp.HitNormal >= 0.7 and trTemp.Entity ~= NULL ) then
		trTemp.Fraction = flFraction
		trTemp.HitPos = vEndPos
		table.CopyFromTo( trTemp, tr )
		
		return tr
	end
	
	tbl.mins.x = vOldMins.x
	flTemp = vOldMaxs.x
	tbl.maxs = Vector( flTemp > 0 and 0 or flTemp, vOldMaxs.y, vOldMaxs.z)
	util.TraceRay( tbl )

	if ( trTemp.HitNormal >= 0.7 and trTemp.Entity ~= NULL ) then
		trTemp.Fraction = flFraction
		trTemp.HitPos = vEndPos
		table.CopyFromTo( trTemp, tr )
		
		return tr
	end
	
	flTemp = vOldMins.x
	mins.x = flTemp < 0 and 0 or flTemp
	mins.y = vOldMins.y
	maxs.x = vOldMaxs.x
	flTemp = vOldMaxs.y
	maxs.y = flTemp > 0 and 0 or flTemp
	util.TraceRay( tbl )
	
	if ( trTemp.HitNormal >= 0.7 and trTemp.Entity ~= NULL ) then
		trTemp.Fraction = flFraction
		trTemp.HitPos = vEndPos
		table.CopyFromTo( trTemp, tr )
		
		return tr
	end
	
	return tr
end

--- Util
-- https://github.com/Facepunch/garrysmod-requests/issues/664
function util.ClipRayToEntity( tbl, pEnt )
	return util.TraceEntity( tbl, pEnt )
end

function util.ClipTraceToPlayers( tbl, tr, flMaxRange --[[= 60]] )
	flMaxRange = (flMaxRange or 60) ^ 2
	tbl.output = nil
	local vAbsStart = tbl.start
	local vAbsEnd = tbl.endpos
	local Filter = tbl.filter
	local flSmallestFraction = tr.Fraction
	local tPlayers = player.GetAll()
	local trOutput
	
	for i = 1, #tPlayers do
		local pPlayer = tPlayers[i]
		
		if ( not pPlayer:Alive() or pPlayer:IsDormant() ) then
			continue
		end
		
		-- Don't bother to trace if the player is in the filter
		if ( isentity( Filter )) then
			if ( Filter == pPlayer ) then
				continue
			end
		elseif ( istable( Filter )) then
			local bFound = false
			
			for i = 1, #Filter do
				if ( Filter[i] == pPlayer ) then
					bFound = true
					
					break
				end
			end
			
			if ( bFound ) then
				continue
			end
		end
		
		local flRange = pPlayer:WorldSpaceCenter():DistanceSqrToRay( vAbsStart, vAbsEnd )
		
		if ( flRange < 0 or flRange > flMaxRange ) then
			continue
		end
		
		local trTemp = util.ClipRayToEntity( tbl, pPlayer )
		local flFrac = trTemp.Fraction
		
		if ( flFrac < flSmallestFraction ) then
			// we shortened the ray - save off the trace
			trOutput = trTemp
			flSmallestFraction = flFrac
		end
	end
	
	if ( trOutput ) then
		table.CopyFromTo( trOutput, tr )
	end
	
	return tr
end

function util.TraceRay( tbl )
	if ( tbl.mins ) then
		return util.TraceHull( tbl )
	end
	
	return util.TraceLine( tbl )
end

--- CS:S/DoD:S melee
function util.FindHullIntersection( tbl, tr )
	local iDist = 1e12
	tbl.output = nil
	local vSrc = tbl.start
	local vHullEnd = vSrc + (tr.HitPos - vSrc) * 2
	tbl.endpos = vHullEnd
	local tBounds = { tbl.mins, tbl.maxs }
	local trTemp = util.TraceLine( tbl )
	
	if ( trTemp.Fraction ~= 1 ) then
		table.CopyFromTo( trTemp, tr )
		
		return tr
	end
	
	local trOutput
	
	for i = 1, 2 do
		for j = 1, 2 do
			for k = 1, 2 do
				tbl.endpos = Vector( vHullEnd.x + tBounds[i].x, 
					vHullEnd.y + tBounds[j].y,
					vHullEnd.z + tBounds[k].z )
				
				local trTemp = util.TraceLine( tbl )
				
				if ( trTemp.Fraction ~= 1 ) then
					local iHitDistSqr = (trTemp.HitPos - vSrc):LengthSqr()
					
					if ( iHitDistSqr < iDist ) then
						trOutput = trTemp
						iDist = iHitDistSqr
					end
				end
			end
		end
	end
	
	if ( trOutput ) then
		table.CopyFromTo( trOutput, tr )
	end
	
	return tr
end
