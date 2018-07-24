require 'hash'

texture = {}

local TEXTURE = {
	__tostring = function(self)
		return self.Name
	end
}
TEXTURE.__index = TEXTURE
TEXTURE.__concat = TEXTURE.__tostring

debug.getregistry().Texture = TEXTURE

local textures 	= {}
local proxyurl 	= 'https://YOUR_SITE.COM/?url=%s&width=%i&height=%i&format=%s'

if (not file.IsDir('texture', 'DATA')) then
	file.CreateDir 'texture'
else
	local files = file.Find('texture/*', 'DATA')
	if (#files > 1000) then
		for k, v in ipairs(files) do
			file.Delete('texture/' .. v)
		end
	end
end

function texture.Create(name)
	local ret = setmetatable({
		Name 	= name,
		URL 	= '',
		Width 	= 1000,
		Height 	= 1000,
		Busy 	= false,
		Cache 	= true,
		Proxy 	= true,
		Format 	= 'jpg',
	}, TEXTURE)
	textures[name] = ret
	return ret
end

function texture.Get(name)
	if textures[name] then
		return textures[name]:GetMaterial()
	end
end

function texture.Delete(name)
	textures[name] = nil
end

function texture.SetProxy(url)
	proxyurl = url
end

function TEXTURE:SetSize(w, h)
	self.Width, self.Height = w, h
	return self
end

function TEXTURE:SetFormat(format) -- valid formats are whatever your webserver proxy can handle.
	self.Format = format
	return self
end

function TEXTURE:EnableCache(enable)
	self.Cache = enable
	return self
end

function TEXTURE:EnableProxy(enable)
	self.Proxy = enable
	return self
end


function TEXTURE:GetName()
	return self.Name
end

function TEXTURE:GetUID(reaccount)
	if (not self.UID) or reaccount then
		self.UID = hash.MD5(self.Name .. self.URL .. self.Width .. self.Height .. self.Format)
	end
	return self.UID
end

function TEXTURE:GetSize()
	return self.Width, self.Height
end

function TEXTURE:GetFormat()
	return self.Format
end

function TEXTURE:GetURL()
	return self.URL
end

function TEXTURE:GetFile()
	return self.File
end

function TEXTURE:GetMaterial()
	return self.IMaterial
end

function TEXTURE:GetError()
	return self.Error
end

function TEXTURE:IsBusy()
	return (self.Busy == true)
end

function TEXTURE:Download(url, onsuccess, onfailure)
	if (self.Name == nil) then
		self.Name = 'Web Material: ' .. url
	end
	self.URL = url
	self.File = 'texture/' .. self:GetUID() .. '.png'

	if self.Cache and file.Exists(self.File, 'DATA') then
		self.IMaterial = Material('data/' .. self.File, 'smooth')
		if onsuccess then
			onsuccess(self, self.IMaterial)
		end
	else
		self.Busy = true

		http.Fetch(self.Proxy and string.format(proxyurl, url:URLEncode(), self.Width, self.Height, self.Format) or url, function(body, len, headers, code)
			if (self.Cache) then
				file.Write(self.File, body)
				self.IMaterial = Material('data/' .. self.File, 'smooth')
			else
				local tempfile = 'texture/tmp_' .. os.time() .. '_' .. self:GetUID() .. '.png'
				file.Write(tempfile, body)

				self.IMaterial = Material('data/' .. tempfile, 'smooth')

				timer.Simple(1, function()
					file.Delete(tempfile)
				end)
			end

			if onsuccess then
				onsuccess(self, self.IMaterial)
			end

			self.Busy = false
		end, function(error)

			self.Error = error

			if onfailure then
				onfailure(self, self.Error)
			end

			self.Busy = false
		end)
	end
	return self
end

function TEXTURE:RenderManual(func, callback)
	local cachefile = 'texture/' .. self:GetUID() .. '-render.png'

	if self.Cache and file.Exists(cachefile, 'DATA') then
		self.File = cachefile
		self.IMaterial = Material('data/' .. self.File, 'smooth')

		if callback then
			callback(self, self.IMaterial)
		end
	else
		local w, h = self.Width, self.Height

		local hookId = 'texture.PostRender' .. self:GetUID()
		hook.Add('PostRender', hookId, function()
			hook.Remove('PostRender', hookId)

			local drawRT = GetRenderTarget(self:GetName(), w, h, true)

			render.PushRenderTarget(drawRT, 0, 0, w, h)
				render.OverrideAlphaWriteEnable(true, true)
				surface.DisableClipping(true)
				render.ClearDepth()
				render.Clear(0, 0, 0, 0)

					cam.Start2D()
						func(self, w, h)
					cam.End2D()

					if self.Cache then
						self.File = 'texture/' .. self:GetUID() .. '-render.png'
						file.Write(self.File, render.Capture({
							format = 'png',
							quality = 100,
							x = 0,
							y = 0,
							h = h,
							w = w
						}))
					end

				surface.DisableClipping(false)
				render.OverrideAlphaWriteEnable(false)
			render.PopRenderTarget()

			if self.Cache then
				self.IMaterial = Material('data/' .. self.File)
			end

			if callback then
				callback(self, self.IMaterial)
			end
		end)
	end
	return self
end

function TEXTURE:Render(func, callback)
	return self:RenderManual(function(self, w, h)
		cam.Start2D()
			func(self, w, h)
		cam.End2D()
	end, callback)
end

/*
Basic usage

local logo = texture.Create('example')
	:SetSize(570, 460)
	:SetFormat('png')
	:Download('https://i.imgur.com/TZcJ1CK.png', print, print)
	:Render(function(self, w, h)
		draw.Box(0, 0, w, h, Color(0,255,0))

		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(self:GetMaterial())
		surface.DrawTexturedRect(0, 0, w, h)

		draw.SimpleText('hello!!!!', 'CloseCaption_BoldItalic', 100, 100, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end)

hook.Add('HUDPaint', 'awdawd', function()
	if logo:GetMaterial() then
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(logo:GetMaterial())
		surface.DrawTexturedRect(35, 35, 570, 460)
	end
end)
*/