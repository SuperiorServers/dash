do
	local q = {{},{},{},{}}
	local q1, q2, q3, q4 = q[1], q[2], q[3], q[4]
	local drawpoly = surface.DrawPoly
	function surface.DrawQuad(x1, y1, x2, y2, x3, y3, x4, y4)
		q1.x, q1.y = x1, y1
		q2.x, q2.y = x2, y2
		q3.x, q3.y = x3, y3
		q4.x, q4.y = x4, y4
		drawpoly(q)
	end

	local quv = {{},{},{},{}}
	local quv1, quv2, quv3, quv4 = quv[1], quv[2], quv[3], quv[4]
	local math_min, math_max = math.min, math.max
	function surface.DrawQuadUV(x1, y1, x2, y2, x3, y3, x4, y4)
		local xmin, ymin = math_max, math_max
		local xmax, ymax = math_min, math_min

		xmin = x1
		if x2 < xmin then xmin = x2 end
		if x3 < xmin then xmin = x3 end
		if x4 < xmin then xmin = x4 end

		ymin = y1
		if y2 < ymin then ymin = y2 end
		if y3 < ymin then ymin = y3 end
		if y4 < ymin then ymin = y4 end

		xmax = x1
		if x2 > xmax then xmax = x2 end
		if x3 > xmax then xmax = x3 end
		if x4 > xmax then xmax = x4 end

		ymax = y1
		if y2 > ymax then ymax = y2 end
		if y3 > ymax then ymax = y3 end
		if y4 > ymax then ymax = y4 end

		local dy = ymax - ymin
		local dx = xmax - xmin

		quv1.u, quv1.v = (x1-xmin)/dx, (y1-ymin)/dy
		quv2.u, quv2.v = (x2-xmin)/dx, (y2-ymin)/dy
		quv3.u, quv3.v = (x3-xmin)/dx, (y3-ymin)/dy
		quv4.u, quv4.v = (x4-xmin)/dx, (y4-ymin)/dy

		quv1.x, quv1.y = x1, y1
		quv2.x, quv2.y = x2, y2
		quv3.x, quv3.y = x3, y3
		quv4.x, quv4.y = x4, y4

		drawpoly(quv)
	end

	local drawline = surface.DrawLine
 	function surface.DrawOutlinedQuad(x1, y1, x2, y2, x3, y3, x4, y4)
 		drawline(x1,y1, x2,y2)
 		drawline(x2,y2, x3,y3)
 		drawline(x3,y3, x4,y4)
 		drawline(x4,y4, x1,y1)
	end
end

do
	local cos, sin = math.cos, math.sin
	local ang2rad = 3.141592653589/180
	local drawquad = surface.DrawQuad
	function surface.DrawArc(_x, _y, r1, r2, aStart, aFinish, steps)
		aStart, aFinish = aStart*ang2rad, aFinish*ang2rad
		local step = ((aFinish - aStart) / steps)
		local c = steps

		local a, c1, s1, c2, s2

		c2, s2 = cos(aStart), sin(aStart)
		for _a = 0, steps - 1 do
			a = _a*step + aStart
			c1, s1 = c2, s2
			c2, s2 = cos(a+step), sin(a+step)

			drawquad( _x+c1*r1, _y+s1*r1,
						 _x+c1*r2, _y+s1*r2,
						 _x+c2*r2, _y+s2*r2,
						 _x+c2*r1, _y+s2*r1 )
			c = c - 1
			if c < 0 then break end
		end
	end
end

-- Begin the moonshit
-- DRAW QUAD
do
	local cos, sin = math.cos, math.sin
	local ang2rad = 3.141592653589/180
	local drawline = surface.DrawLine
	function surface.DrawArcOutline(_x, _y, r1, r2, aStart, aFinish, steps)
		aStart, aFinish = aStart*ang2rad, aFinish*ang2rad
		local step = ((aFinish - aStart) / steps)
		local c = steps

		local a, c1, s1, c2, s2

		c2, s2 = cos(aStart), sin(aStart)
		drawline(_x+c2*r1, _y+s2*r1, _x+c2*r2, _y+s2*r2)
		for _a = 0, steps - 1 do
			a = _a*step + aStart
			c1, s1 = c2, s2
			c2, s2 = cos(a+step), sin(a+step)


			drawline( _x+c1*r2, _y+s1*r2,
												_x+c2*r2, _y+s2*r2 )
			drawline( _x+c1*r1, _y+s1*r1,
												_x+c2*r1, _y+s2*r1 )
			c = c - 1
			if c < 0 then break end
		end
		drawline(_x+c2*r1, _y+s2*r1, _x+c2*r2, _y+s2*r2)
	end
end

-- GetTextSize caching
do
	local SetFont 		= surface.SetFont
	local GetTextSize 	= surface.GetTextSize

	local font = 'TargetID'
	local cache = setmetatable({}, {
		__mode = 'k'
	})

	timer.Create('surface.ClearFontCache', 1800, 0, function()
		for i = 1, #cache do
			cache[i] = nil
		end
	end)

	function surface.SetFont(_font)
		font = _font
		return SetFont(_font)
	end

	function surface.GetTextSize(text)
		if (not cache[font]) then
			cache[font] = {}
		end
		if (not cache[font][text]) then
			local w, h = GetTextSize(text)
			cache[font][text] = {
				w = w,
				h = h
			}
			return w, h
		end
		return cache[font][text].w, cache[font][text].h
	end
end