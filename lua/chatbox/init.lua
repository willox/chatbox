function ScreenScale()
	return 0
end

chat = chat or {}
chat.RegisterIcon = function() end

chatbox_config = {}
setmetatable(chatbox_config, {__index = _G})
local configFunc = CompileFile("config.lua")
setfenv(configFunc, chatbox_config)
configFunc()

AddCSLuaFile("config.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("vgui/ChatEntry.lua")
AddCSLuaFile("vgui/ScrollPanel.lua")
AddCSLuaFile("vgui/ChatMessage.lua")
AddCSLuaFile("vgui/Chatbox.lua")

util.AddNetworkString("Chatbox_PlayerChat") -- Emulating the `say` command completely

net.Receive("Chatbox_PlayerChat", function(_, ply)
	if IsValid(ply) then
		if not ply.LastChatMessage then
			ply.LastChatMessage = 0
		end

		if ply.LastChatMessage + 0.8 <= RealTime() then
			local team_chat = (net.ReadBit() == 1)
			local text = string.sub(net.ReadString(), 1, 512)

			local textret = hook.Run("PlayerSay", ply, text, team_chat)

			if textret == false or textret == "" then
				return
			end

			if isstring( textret ) then
				text = textret
			end

			local rec = {}

			for k, v in pairs(player.GetAll()) do
				if hook.Run("PlayerCanSeePlayersChat", text, team_chat, v, ply) then
					rec[#rec + 1] = v
				end
			end

			if chatbox_config['EnableColors'] and not chatbox_config['AllowedToUseColors'](ply) then
				local args = {}

				for s in string.gmatch(text, "%s?[(%S)]+%s*") do
					if s[1] == " " and s[2] == "*" then
						table.insert(args, " ")
						s = s:sub(2)
					end

					if s[1] == "*" then
						local col = s:sub(2):lower():Trim()

						if chatbox_config['ChatColors'][col] then
							if #s > #col + 1 then
								table.insert(args, s:sub(#col + 3))
							end

							continue
						end
					end

					table.insert(args, s)
					continue
				end

				text = table.concat(args)
			end

			net.Start("Chatbox_PlayerChat")
				net.WriteEntity(ply)
				net.WriteBit(team_chat)
				net.WriteString(text)
				net.WriteBit(ply:Alive())
			net.Send(rec)

			ply.LastTextMessage = RealTime()
		end
	end
end)

hook.Add("PlayerSay", "chatbox_PlayerSay", function(ply, text, team, hack)
	if hack ~= "awesome" then
		local newText = ""
		if chatbox_config['EnableColors'] and not chatbox_config['AllowedToUseColors'](ply) then
			local args = {}

			for s in string.gmatch(text, "%s?[(%S)]+%s*") do
				if s[1] == " " and s[2] == "*" then
					table.insert(args, " ")
					s = s:sub(2)
				end

				if s[1] == "*" then
					local col = s:sub(2):lower():Trim()

					if chatbox_config['ChatColors'][col] then
						if #s > #col + 1 then
							table.insert(args, s:sub(#col + 3))
						end

						continue
					end
				end

				table.insert(args, s)
				continue
			end

			newText = table.concat(args)
		end

		if text ~= newText and newText ~= "" then
			return hook.Run("PlayerSay", ply, newText, team, "awesome") or newText
		end
	end
end)