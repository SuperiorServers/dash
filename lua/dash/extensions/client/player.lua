local pl
local _LocalPlayer = LocalPlayer
function LocalPlayer()
	pl = _LocalPlayer()
	if IsValid(pl) then
		LocalPlayer = function()
			return pl
		end
	end
	return pl
end