local mat_Grad = surface.GetTextureID("gui/gradient")

local PANEL = {}

PANEL.LineData = nil
PANEL.Text = nil

function PANEL:Init()
	self.Lines = {}
	self.DieTime = RealTime() + chatbox_config['MessageDieTime']
	self.DeadTime = self.DieTime + chatbox_config['MessageFadeTime']
	self.Alpha = 255
	self:SetMouseInputEnabled(true)

end

function PANEL:LastColor(linedata)
	local col = color_white

	for k, v in pairs(linedata.textdata) do
		if(isCol(v)) then
			col = v
		end
	end

	return col
end


function PANEL:Wrap()
	self.Text = ""
	local linedata, maxwidth = self.LineData, self:GetWide() - 4

	surface.SetFont("Chatbox_ChatFont")

	local mw, mh = surface.GetTextSize("M")

	local linewidth = 0 -- incremential
	local leftmargin = (linedata.icon and 24 or 4)

	local packedlines = {
		{icon = linedata.icon, textdata = {}}
	}

	local linenumber = 1

	for k, v in pairs(linedata.textdata) do
		if(type(v) == "string") then
			self.Text = self.Text .. v
			local w, h = surface.GetTextSize(string.gsub(v, "&", "U"))
			local new = false

			linewidth = linewidth + w

			if(linewidth + leftmargin >= maxwidth) then
				if(w <= maxwidth) then
					linewidth = w
					linenumber = linenumber + 1

					table.insert(packedlines, {textdata = {self:LastColor(packedlines[linenumber -1])}})
					table.insert(packedlines[linenumber].textdata, v)
				else
					local curText =""

					for i = 1, #v do
						local char = v[i]
						local secW, secH = surface.GetTextSize(string.gsub(curText..char, "&", "U"))

						if(secW > maxwidth) then
							linenumber = linenumber + 1

							table.insert(packedlines, {textdata = {self:LastColor(packedlines[linenumber -1])}})
							table.insert(packedlines[linenumber].textdata, curText)

							curText = ""
						end

						curText = curText..char
					end

					if(curText ~= "") then
						linenumber = linenumber + 1
						table.insert(packedlines, {textdata = {self:LastColor(packedlines[linenumber -1])}})
						table.insert(packedlines[linenumber].textdata, curText)
					end
				end

				new = true
			else
				table.insert(packedlines[linenumber].textdata, v)
			end

		end

		if(isCol(v)) then
			table.insert(packedlines[linenumber].textdata, v)
		end

		if(new) then
			linewidth = 0
		end
	end

	return packedlines, (linenumber * (mh + chatbox_config['LineSpacing']))
end

function PANEL:SetLineData(data)
	self.LineData = data

	local wrapped, height = self:Wrap()

	for k, v in pairs(wrapped) do
		self.Lines[#self.Lines + 1] = v
	end


	if(not data.icon) then
		self:SetTall(height + 1)
	else
		self:SetTall(math.Max(height + 1, 20))
	end

end

function PANEL:PerformLayout()
	self.Lines = {}

	local data = self.LineData

	local wrapped, height = self:Wrap()

	for k, v in pairs(wrapped) do
		self.Lines[#self.Lines + 1] = v
	end

	if(not data.icon) then
		self:SetTall(height + 1)
	else
		self:SetTall(math.Max(height + 1, 20))
	end
end

function PANEL:Paint(sw, sh, xoff, yoff, alpha)
	xoff = xoff or 0
	yoff = yoff or 0

	surface.SetFont("Chatbox_ChatFont")

	local lineheight = 0 -- incremential
	local icon = self.LineData.icon

	if(alpha) then
		local bgcol = Color(5, 5, 5, math.Max(150 * (self.Alpha / 255), 0))

		surface.SetDrawColor(bgcol)
		surface.SetTexture(mat_Grad)
		surface.DrawTexturedRect(xoff-4, yoff - (chatbox_config['MessageSpacing'] / 2), sw + 4, sh + (chatbox_config['MessageSpacing']))
	end

	local leftmargin = (icon and 24 or 4)

	for num, data in ipairs(self.Lines) do
		local linewidth = 0 -- incremential
		local h = 0
		local num = num - 1
		local w = 0
		
		

		local shadowalpha = 230
		local colalpha = 255

		if(alpha) then
			colalpha = self.Alpha
			shadowalpha = math.Max(230 - (255 - self.Alpha), 0)
		end

		local col = Color(255, 255, 255, colalpha)

		for _, elem in pairs(data.textdata) do
			if(isCol(elem)) then
				col = Color(elem.r, elem.g, elem.b, colalpha)
			elseif(type("elem") == "string") then
				w, h2 = surface.GetTextSize(string.gsub(elem, "&", "U"))
				h = math.Max(h, h2)

				surface.SetTextColor(Color(0, 0, 0, shadowalpha))
				surface.SetTextPos(xoff + leftmargin + linewidth + 1, yoff + lineheight + 1 + (chatbox_config['LineSpacing']/2))
				surface.DrawText(elem)

				surface.SetTextColor(col)
				surface.SetTextPos(xoff + leftmargin + linewidth, yoff + lineheight + (chatbox_config['LineSpacing']/2))
				surface.DrawText(elem)

				linewidth = linewidth + w
				
			end
		end

		if(data.icon) then
			surface.SetDrawColor(Color(255, 255, 255, colalpha))
			surface.SetMaterial(data.icon)
			surface.DrawTexturedRect(xoff + 2, yoff + lineheight + (chatbox_config['LineSpacing']/2) + 1, 16, 16)
		end

		surface.SetTextColor(Color(255, 255, 255, colalpha))

		lineheight = lineheight + h + chatbox_config['LineSpacing']

		leftmargin = 4
	end
end

function PANEL:OnMouseReleased(c)
	if c == MOUSE_RIGHT then
		local menu = DermaMenu()
		menu:AddOption("Copy", function() if IsValid(self) then SetClipboardText(self.Text) end end)
		menu:Open()
	end
end

vgui.Register("Chatbox_ChatMessage", PANEL, "Panel")