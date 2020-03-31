local PANEL = {}

local BGCOL = Color(255, 255, 255, 10)
local GRIPCOL = Color(255, 255, 255, 150)

function PANEL:Init()
	self.VBar:SetWide(34)
	
	self.VBar.OnMouseWheeled = function(s, dlta)
		if(not s:IsVisible()) then return false end

		return s:AddScroll(dlta * -1)
	end
	
	self.VBar.Paint = function(s, w, h) 
		surface.SetDrawColor(BGCOL)
		--surface.DrawRect(20, 38, 4, h - 51)
		surface.DrawRect(17, 17, 4, h - (17*2)) 
	end
	
	self.VBar.BarScale = function(s)
		return 10 / s:GetTall()
	end
	
	self.VBar.btnGrip.Paint = function(s, w, h)
		surface.SetDrawColor(GRIPCOL)
		surface.DrawRect(4, 2, w-6, h-4)
	end
	
	self.VBar.btnUp.Paint = function(s, w, h) 

	end

	self.VBar.btnDown.Paint = function(s, w, h) 

	end
	
	self:Dock(FILL)
	self:DockMargin(2, 2, 2, 2)
end

function PANEL:PerformLayout()
	if(IsValid(self.Chatbox)) then
		self.BaseClass.PerformLayout(self)

		if(self.Chatbox:GetScrollDown()) then
			self.VBar:SetScroll(math.huge)
			self.Chatbox:SetScrollDown(false)
		end
	end
end


vgui.Register("Chatbox_ScrollPanel", PANEL, "DScrollPanel")
