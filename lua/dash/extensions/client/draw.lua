local surface_SetDrawColor 	= surface.SetDrawColor
local surface_SetMaterial 	= surface.SetMaterial
local surface_DrawRect 		= surface.DrawRect
local surface_DrawTexturedRect = surface.DrawTexturedRect
local render_UpdateScreenEffectTexture = render.UpdateScreenEffectTexture
local render_SetScissorRect = render.SetScissorRect
local ScrW = ScrW
local ScrH = ScrH
local SysTime = SysTime
local FrameTime = FrameTime
local Vector = Vector
local Matrix = Matrix

local function DrawRect(x, y, w, h, t)
	if not t then t = 1 end
	surface_DrawRect(x, y, w, t)
	surface_DrawRect(x, y + (h - t), w, t)
	surface_DrawRect(x, y, t, h)
	surface_DrawRect(x + (w - t), y, t, h)
end

function draw.Box(x, y, w, h, col)
	surface_SetDrawColor(col)
	surface_DrawRect(x, y, w, h)
end

function draw.Outline(x, y, w, h, col, thickness)
	surface_SetDrawColor(col)
	DrawRect(x, y, w, h, thickness)
end

function draw.OutlinedBox(x, y, w, h, col, bordercol, thickness)
	surface_SetDrawColor(col)
	surface_DrawRect(x + 1, y + 1, w - 2, h - 2)

	surface_SetDrawColor(bordercol)
	DrawRect(x, y, w, h, thickness)
end

local blurboxes = {}
local blur = Material 'pp/blurscreen'
function draw.BlurResample(amount)
	surface_SetDrawColor(255, 255, 255)
	surface_SetMaterial(blur)
	for i = 1, 3 do
		blur:SetFloat('$blur', (i / 3) * (amount or 8))
		blur:Recompute()
		render_UpdateScreenEffectTexture()

		for k, v in ipairs(blurboxes) do
			render_SetScissorRect(v.x, v.y, v.x + v.w, v.y + v.h, true)
				surface_DrawTexturedRect(0, 0, ScrW(), ScrH())
			render_SetScissorRect(0, 0, 0, 0, false)
			blurboxes[k] = nil
		end

	end
end

function draw.BlurBox(x, y, w, h)
	blurboxes[#blurboxes + 1] = {
		x = x,
		y = y,
		w = w,
		h = h
	}
end

function draw.BlurPanel(panel)
	draw.BlurBox(panel:GetBounds())
end
draw.Blur = draw.BlurPanel -- Backward support

function draw.TextRotated(text, x, y, color, font, ang)
	--render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	--render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	surface.SetFont(font)
	surface.SetTextColor(color)
	local textWidth, textHeight = surface.GetTextSize(text)
	local rad = -math.rad(ang)
	local halvedPi = math.pi / 2
	local m = Matrix()
	m:SetAngles(Angle(0, ang, 0))
	m:SetTranslation(Vector(x, y, 0))
	cam.PushModelMatrix(m)
		surface.SetTextPos(0, 0)
		surface.DrawText(text)
	cam.PopModelMatrix()
	--render.PopFilterMag()
	--render.PopFilterMin()
end