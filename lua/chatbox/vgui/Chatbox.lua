local PANEL = {}

AccessorFunc(PANEL, "b_Team", "Team", FORCE_BOOL)
AccessorFunc(PANEL, "b_Open", "Open", FORCE_BOOL)
AccessorFunc(PANEL, "b_Scoreboard", "Scoreboard", FORCE_BOOL)
AccessorFunc(PANEL, "b_ScrollDown", "ScrollDown", FORCE_BOOL)

local SHADOWCOL = Color(0, 0, 0, 230)
 
function PANEL:Init()
	self.XOff, self.YOff = 0, 0 -- Unused

	self.Lines = {}

	self.ChatPanelContainer = vgui.Create("Panel", self)
	self.ChatPanelContainer:Dock(FILL)
	self.ChatPanelContainer.Paint = function(s, w, h) end

	self.ChatPanel = vgui.Create("Chatbox_ScrollPanel", self.ChatPanelContainer)
	self.ChatPanel.Chatbox = self
	
	self.EntryPanel = vgui.Create("EditablePanel", self)
	self.EntryPanel:Dock(BOTTOM)
	self.EntryPanel:DockMargin(2, 0, 2, 2)
	surface.SetFont("Chatbox_ChatFontTextArea")
	local w, h = surface.GetTextSize("WMH")
	self.EntryPanel:SetTall(h + 16)
	self.EntryPanel.Paint = function(s, w, h)
		--surface.SetDrawColor(Color(10, 10, 10, 180))
		--surface.DrawRect(0, 0, w, h)
	end

	
	self.EntryBox = vgui.Create("Chatbox_ChatEntry", self.EntryPanel)
	self.EntryBox:SetFont("Chatbox_ChatFontTextArea")
	self.EntryBox.Chatbox = self
	
	self:SetOpen(false)

	self:SetSize(chatbox_config['Width'], chatbox_config['Height'])
	self:SetPos(self.XOff + chatbox_config['X'], self.YOff + ScrH() - chatbox_config['Y'] - self:GetTall())

	self:Close()


	hook.Add("HUDPaint", "Chatbox_HUDPaint", function()
		if IsValid(self) and not self:GetOpen() then
			self:PaintClosed(self:GetWide(), self:GetTall())
		end
	end)

	hook.Add("ScoreboardShow", "Chatbox_SBCheck", function()
		if IsValid(self) then
			self:SetScoreboard(true)
		end
	end)

	hook.Add("ScoreboardHide", "Chatbox_SBCheck", function()
		if IsValid(self) then
			self:SetScoreboard(false)
		end
	end)

	self:Open()
	self.FirstOpen = false
	self:SetOpen(false) -- Force to close after 1 render
	self:SetScoreboard(false)

	self:SetScrollDown(false)

	hook.Run("ChatboxInitialize")
end

function PANEL:PerformLayout()
	self:SetSize(chatbox_config['Width'], chatbox_config['Height'])
	self:SetPos(self.XOff + chatbox_config['X'], self.YOff + ScrH() - chatbox_config['Y'] - self:GetTall())
end

function PANEL:Open()
	self.FirstOpen = true
	self.EntryBox:SetText("")

	self:SetOpen(true)
	self:MakePopup()
	

	self:SetVisible(true)

	self.EntryBox:RequestFocus()

	--[[if self:GetTeam() then
		self.EntryLabel:SetText("Say (TEAM):")
	else
		self.EntryLabel:SetText("Say:")
	end

	self.EntryLabel:SizeToContents()]]
	self.ChatPanel.VBar:SetScroll(math.huge)

	timer.Simple(0, function()
		self.ChatPanel.VBar:SetScroll(math.huge)
	end)
	
	self:SetScrollDown(true)

	hook.Run("Chatbox_OpenChat")
	hook.Run("StartChat", self:GetTeam(), true)
end

function PANEL:Close()
	self:SetOpen(false)
	self:SetTeam(false)
	self:SetVisible(false)
	self.EntryBox:KillFocus()

	if self.FirstOpen then
		gui.EnableScreenClicker(false)
	end
	
	hook.Run("Chatbox_CloseChat")
	hook.Run("FinishChat")
end

local matBlurScreen = Material("pp/blurscreen")

local OUTLINECOL = Color(5, 5, 5, 150)
local INLINECOL = Color(5, 5, 5, 150)

function PANEL:Paint(w, h)
	if not self:GetOpen() then
		self:Close()
	end

	surface.SetMaterial(matBlurScreen)
	surface.SetDrawColor(color_white)
	matBlurScreen:SetFloat("$blur", 2)
	matBlurScreen:Recompute()
	render.UpdateScreenEffectTexture()
	local x, y = self:ScreenToLocal(0, 0)
	surface.DrawTexturedRect(x, y, ScrW(), ScrH())

	surface.SetDrawColor(INLINECOL)
	surface.DrawRect(0, 0, w, h)

	DisableClipping(true)
	surface.SetDrawColor(OUTLINECOL)
	surface.DrawOutlinedRect(-1, -1, w + 2, h + 2)
	DisableClipping(false)
end

function PANEL:PaintClosed(w, h)
	local lines = self.Lines
	local x, y = self.ChatPanel:LocalToScreen(0, 0)

	x = x + 2
	y = y + self.ChatPanel:GetTall()

	local linec = 0

	for i = #lines, 1, -1 do
		if linec >= chatbox_config['MaxLines'] then if lines[i].Alpha == 0 then break else lines[i].Alpha = 0 end end

		local line = lines[i]

		if line.Alpha == 0 then continue end
		--if(line.DeadTime <= RealTime()) then continue end


		if not IsValid(lines[i - 1]) or lines[i -1].Alpha == 0 or (linec + 1 == chatbox_config['MaxLines']) then
			if RealTime() >= line.DieTime then
				line.Alpha = math.Clamp(line.Alpha - (FrameTime() / chatbox_config['MessageFadeTime']) * 255, 0, 255)
			end
		end

		y = y - lines[i]:GetTall()

		if linec == 0 then
			lines[i]:Paint(lines[i]:GetWide(), lines[i]:GetTall() + 2, x, y, true)
		else
			lines[i]:Paint(lines[i]:GetWide(), lines[i]:GetTall(), x, y, true)
		end

		y = y - chatbox_config['MessageSpacing']

		linec = linec + 1
	end
end

function PANEL:AddLine(linedata)
	if chatbox_config['MessageSound'] then
		chat.PlaySound()
	end
	
	local scrolling = (self.ChatPanel.VBar.CanvasSize ~= self.ChatPanel.VBar:GetScroll())

	if not self.ChatPanel.VBar.Enabled then
		scrolling = false
	end

	local id = #self.Lines + 1

	self.Lines[id] = vgui.Create("Chatbox_ChatMessage", self.ChatPanel)
	self.Lines[id]:SetWide(self.ChatPanel:GetCanvas():GetWide() - 4) -- This is required for first time wrapping
	self.Lines[id]:Dock(TOP)
	self.Lines[id]:DockMargin(2, chatbox_config['MessageSpacing'] / 2, 2, chatbox_config['MessageSpacing'] / 2)
	self.Lines[id]:SetLineData(linedata)
	self.Lines[id].Player = linedata.player
	
	self.ChatPanel:AddItem(self.Lines[id])
	

	if id > 128 then
		self.Lines[1]:Remove()
		table.remove(self.Lines, 1)
	end

	if not scrolling then
		self:SetScrollDown(true)
	end
end

vgui.Register("Chatbox", PANEL, "EditablePanel")