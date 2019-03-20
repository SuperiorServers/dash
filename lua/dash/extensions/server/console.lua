if (not system.IsLinux()) then return end

local colorClearSequence = '\27[0m'

local function rgbToAnsi256(r, g, b) // https://stackoverflow.com/questions/15682537/ansi-color-specific-rgb-sequence-bash?answertab=votes#tab-top
	if (r == g) and (g == b) then
		if (r < 8) then
			return 16
		end

		if (r > 248) then
			return 231
		end

		return math.Round(((r - 8) / 247) * 24) + 232
	end

	return 16 + (36 * math.Round(r / 255 * 5)) + (6 * math.Round(g / 255 * 5)) + math.Round(b / 255 * 5)
end

function MsgC(...)
	local outText = colorClearSequence

	for k, v in ipairs({...}) do
		if istable(v) and v.r and v.g and v.b then
			outText = outText .. '\27[38;5;' .. rgbToAnsi256(v.r, v.g, v.b) .. 'm'
		else
			outText = outText .. v
		end
	end

	Msg(outText .. colorClearSequence)
end

local _ErrorNoHalt = ErrorNoHalt
function ErrorNoHalt(msg)
	Msg('\27[38;5;51m')
	_ErrorNoHalt(msg)
	Msg(colorClearSequence)
end