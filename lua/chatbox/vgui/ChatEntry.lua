local PANEL = {}

function PANEL:Init()
	self:Dock(FILL)
	self:DockMargin(5, 3, 5, 3)
	self:DockPadding(20, 0, 0, 0)
	self:SetHistoryEnabled(true)
	self:SetAllowNonAsciiCharacters(true)
end

local OUTLINECOL = Color(10, 10, 10, 235)
local INLINECOL = Color(5, 5, 5, 130)

function PANEL:Paint(w, h)
	surface.SetDrawColor(INLINECOL)
	surface.DrawRect(1, 1, w-2, h-2)

	local text = self:GetText()

	if text == "" then
		draw.SimpleText((self.Chatbox:GetTeam() and "SAY TEAM") or "SAY", self:GetFont(), 4, self:GetTall() / 2, Color(255, 255, 255, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	

	if chatbox_config['HideLanguageButton'] then
		self:SetAllowNonAsciiCharacters(false)
	end

		self:DrawTextEntryText(color_white, Color(235, 49, 49), color_white)
	
	if chatbox_config['HideLanguageButton'] then
		self:SetAllowNonAsciiCharacters(true)
	end
	--surface.SetDrawColor(OUTLINECOL)
	--surface.DrawOutlinedRect(0, 0, w, h)
end

function PANEL:OnEnter()
	if IsValid(self.Chatbox) then
		if self:GetText():Trim() ~= "" then
			self:AddHistory(self:GetText())

			net.Start("Chatbox_PlayerChat")
				net.WriteBit(self.Chatbox:GetTeam())
				net.WriteString(string.sub(self:GetText():Trim(), 1, 512))
			net.SendToServer()

			self:SetText("")
			hook.Run("ChatTextChanged", "")
		end

		self.Chatbox:Close()
	end
end

function PANEL:OnChange()
	if IsValid(self.Chatbox) then
		local msg = self:GetText()

		if #msg > 512 then
			self:SetText(string.sub(msg, 1, 512))
			self:SetCaretPos(512)
			surface.PlaySound("resource/warning.wav")
		end

		hook.Run("ChatTextChanged", self:GetText())
	end
end

function PANEL:OnKeyCodeTyped(code)
	if code == KEY_TAB and IsValid(self.Chatbox) then
		if not self.Chatbox:GetScoreboard() then
			local newtext = hook.Run("OnChatTab", self:GetText())

			self:SetText(newtext)
			self:SetCaretPos(#newtext)
		end

		self:RequestFocus()

		timer.Simple(0, function()
			if IsValid(self) then
				self:RequestFocus()
			end
		end)

		return false
	end

	return self.BaseClass.OnKeyCodeTyped(self, code)
end

function PANEL:Think()

	return self.BaseClass.Think(self, code)
end

vgui.Register("Chatbox_ChatEntry", PANEL, "DTextEntry")
