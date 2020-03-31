local chat_icons = {}

function chat.RegisterIcon(icon, func)
	table.insert(chat_icons, {icon = icon, func = func})
end

chatbox_config = {}
setmetatable(chatbox_config, {__index = _G})
local configFunc = CompileFile("config.lua")
setfenv(configFunc, chatbox_config)
configFunc()

include("vgui/ChatEntry.lua")
include("vgui/ScrollPanel.lua")
include("vgui/ChatMessage.lua")
include("vgui/Chatbox.lua")

surface.CreateFont("Chatbox_ChatFont", {
	font = chatbox_config['FontFamily'],
	weight = chatbox_config['FontWeight'],
	size = chatbox_config['FontSize']
})

surface.CreateFont("Chatbox_ChatFontTextArea", {
	font = chatbox_config['FontFamilyEditor'],
	weight = chatbox_config['FontWeightEditor'],
	size = chatbox_config['FontSizeEditor']
})

net.Receive("Chatbox_PlayerChat", function()
	local ply = net.ReadEntity()

	if IsValid(ply) then
		local team_chat = (net.ReadBit() == 1)
		local text = net.ReadString()
		local alive = (net.ReadBit() == 1)

		hook.Run("OnPlayerChat", ply, text, team_chat, not alive)
	end
end)

if not chat_OldAddText then
	chat_OldAddText = chat.AddText
end

function isCol(tab)
	return type(tab) == "table" and tab['r'] and tab['g'] and tab['b']
end

function chat.AddText(...)
	if not IsValid(CHATBOX) then
		CHATBOX = vgui.Create("Chatbox")
	end

	surface.SetFont("Chatbox_ChatFont")

	local pargs = {...}
	local ind, args, icon, cur_color = 1, {}, nil, color_white

	if not isCol(pargs[1]) then
		table.insert(args, color_white)
	end

	for k, v in pairs(pargs) do
		if type(v) == "IMaterial" then
			icon = v
			continue
		end

		if isCol(v) then
			table.insert(args, v)
			cur_color = v
			continue
		end

		if type(v) == "Player" then
			table.insert(args, team.GetColor(v:Team())) -- Don't set cur_color here, to keep the old color
			table.insert(args, v:Name())
			continue
		end

		if type(v) == "string" then
			if chatbox_config['EnableColors'] then
				for s in string.gmatch(v, "%s?[(%S)]+%s*") do
					if s[1] == " " and s[2] == "*" then
						table.insert(args, " ")
						s = s:sub(2)
					end

					if s[1] == "*" and (cur_color.r == 255 and cur_color.g == 255 and cur_color.b == 255) then
						local col = s:sub(2):lower():Trim()

						if chatbox_config['ChatColors'][col] then
							table.insert(args, chatbox_config['ChatColors'][col])

							if #s > #col + 1 then
								table.insert(args, s:sub(#col + 3))
							end

							continue
						end
					end

					table.insert(args, s)
					continue
				end
			else
				table.insert(args, v)
			end
		end
	end

	CHATBOX:AddLine({icon = icon, textdata = args})

	chat_OldAddText(unpack(args))
end

--[[function chat.GetChatBoxPos() -- Leaving this unmodified seems to work best
	if not IsValid(CHATBOX) then
		CHATBOX = vgui.Create("Chatbox")
	end

	local x, y = CHATBOX:GetPos()
	local w = CHATBOX:GetWide()

	return x + (w/2), y - 4
end]]

if IsValid(CHATBOX) then
	CHATBOX:Remove()
end

CHATBOX = nil

hook.Add("PlayerBindPress", "Chatbox_BindPress", function(ply, bind, pressed)
	if not IsValid(CHATBOX) then
		CHATBOX = vgui.Create("Chatbox")
	end

	if pressed and string.find(bind, "messagemode", nil, true) then
		if(GAMEMODE and GAMEMODE.Name == "Trouble in Terrorist Town") then -- It's a bit of a shame to have this here
			if(bind == "messagemode" and pressed and ply:IsSpec()) then
				if(GAMEMODE.round_state == ROUND_ACTIVE and DetectiveMode()) then
					LANG.Msg("spec_teamchat_hint")
					return true
				end
			end
		end

		if string.find(bind, "messagemode2", nil, true) then
			CHATBOX:SetTeam(true)
		else
			CHATBOX:SetTeam(false)
		end

		CHATBOX:Open()

		return true
	end
end)

hook.Add("HUDShouldDraw", "Chatbox_HUDShouldDraw", function(e)
	if e == "CHudChat" then
		return false
	end
end)

hook.Add("Chatbox_OpenChat", "Chatbox_EscapeClose", function()
	hook.Add("Think", "Chatbox_EscapeClose", function()
		if IsValid(CHATBOX) then
			for i = KEY_0, KEY_Z do
				if input.IsKeyDown(i) then
					if not CHATBOX.EntryBox:HasFocus() then
						CHATBOX.EntryBox:RequestFocus()
						break
					end
				end
			end

			if input.IsKeyDown(KEY_ENTER) then
				CHATBOX.EntryBox:RequestFocus()
			end

			if input.IsKeyDown(KEY_ESCAPE) then
				RunConsoleCommand("cancelselect")
				hook.Remove("Think", "Chatbox_EscapeClose")

				CHATBOX.EntryBox:SetText("")
				hook.Run("ChatTextChanged", "")
				CHATBOX:Close()
			end
		end
	end)
end)

hook.Add("Chatbox_CloseChat", "Chatbox_EscapeClose", function()
	hook.Remove("Think", "Chatbox_EscapeClose")
end)

hook.Add("StartChat", "Chatbox_StartChat", function(_, a)
	if not a then
		return true
	end
end)

hook.Add("ChatText", "Chatbox_ChatText", function(index, nick, text, messagetype)
	if not IsValid(CHATBOX) then
		CHATBOX = vgui.Create("Chatbox")
	end

	local args = {}

	if messagetype == "none" then
		for s in string.gmatch(text, "%S+") do
			if s == "cvar" then
				table.insert(args, Color(255, 255, 0))
			end
		end

		for s in string.gmatch(text, "%S?[(%S)]+[^.]?") do
			table.insert(args, s)
		end

		CHATBOX:AddLine({icon = Material("icon16/world.png"), textdata = args})
	end
end)

-- Bit of code from base
hook.Add("OnPlayerChat", "CHATBOX_OnPlayerChat", function(ply, text, team, dead)
	if chatbox_config['ChatIconsEnabled'] then
		if GAMEMODE.Folder == "gamemodes/terrortown" then -- Disgusting TTT 'fix'
			if IsValid(ply) and ply:IsActiveDetective() then
				local icon = nil

				for k, v in ipairs(chat_icons) do
					if IsValid(ply) and v['func'](ply) then
						icon = v['icon']
						break
					end
				end

				if icon then
					chat.AddText(Material(icon), Color(50, 200, 255), ply:Nick(), color_white, ": "..text)
					return true
				end
			end
		end

		local icon = nil

		for k, v in ipairs(chat_icons) do
			if IsValid(ply) and v['func'](ply) then
				icon = v['icon']
				break
			end
		end

		if icon then
			local res = {Material(icon)}

			if dead then
				table.insert(res, Color(255, 30, 40))
				table.insert(res, "*DEAD* ")
			end

			if team then
				table.insert(res, Color(30, 160, 40))
				table.insert(res, "(TEAM) ")
			end

			if IsValid(ply) then
				table.insert(res, ply)
			else
				table.insert(tab, color_white)
				table.insert(tab, "Console")
			end

			table.insert(res, color_white)
			table.insert(res, ": "..text)

			chat.AddText(unpack(res))

			return true
		end
	end
end)

concommand.Add("chatbox_demo", function()
	cblue = Color(100, 149, 237)
	chat.AddText(Material("icon16/star.png"), cblue, "Willox", color_white, ": Roar! I am an Admin!")
	chat.AddText(cblue, "Distressed Civilian", color_white, ": Oh no! Don't hurt me, please!")
	chat.AddText(Color(0, 255, 0), "-THE ROUND HAS BEGUN-")
	chat.AddText(cblue, "Distressed Civilian", color_white, ": Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi mollis mauris at lacus pellentesque convallis. Sed elementum metus sit amet.")
	chat.AddText(Material("icon16/star.png"), cblue, "Willox", color_white, ": Bacon ipsum dolor sit amet kevin chicken tenderloin prosciutto tongue, pork belly cow beef. Filet mignon meatball short ribs brisket venison tri-tip ham hock capicola swine. Doner hamburger sirloin boudin. Spare ribs ribeye strip steak cow kevin venison, sausage salami. Sirloin shank short ribs rump turkey jerky pork loin biltong.")
	chat.AddText(cblue, "Distressed Civilian", color_white, ": Precisely.")
end)