-- Message Area
	FontFamily = "Tahoma"
	FontWeight = 600
	FontSize = 18

-- Text Entry Area
	FontFamilyEditor = "Tahoma"
	FontWeightEditor = 600
	FontSizeEditor = 16
	HideLanguageButton = true -- Hides the button that shows what the current language input is (This can cause visual issues so defaults to hidden)

-- Chatbox Position & Size (From bottom left of screen)
	Width = ScreenScale(220)	-- Width of the chatbox
	Height = ScreenScale(100)	-- Height of the chatbox
	X = 10						-- X position of the chatbox
	Y = 140						-- Y position of the chatbox

-- Message Config
	MessageSpacing = 8			-- Spacing between each message
	LineSpacing = 2				-- Spacing between each line of text
	MaxLines = 10				-- Max amount of messages to show when chat is closed
	MessageDieTime = 10			-- Time for messages to appear when chat is closed
	MessageFadeTime = 0.5		-- Time to fade message away for
	MessageSound = false		-- Whether or not to click when a message is received

-- Color Settings
	EnableColors = true

	ChatColors = {
		red =		Color(255, 0, 0),
		green =		Color(0, 255, 0),
		blue =		Color(0, 0, 255),
		yellow =	Color(255, 255, 0),
		black =		Color(0, 0, 0),
		white =		Color(255, 255, 255),
		grey =		Color(115, 115, 115),
		gray =		Color(115, 115, 115),
		aqua =		Color(127, 255, 212),
		orange =	Color(205, 127, 50),
		purple =	Color(127, 0, 255),
		pink =		Color(247, 0, 119),
		brown =		Color(96, 57, 19)
	}

	AllowedToUseColors = function(ply)
		return true -- Allow everybody to use colors
	end

	--[[ EXAMPLES Color Allow
		-- Allow only admins to use chat colors
			AllowedToUseColors = function(ply)
				return ply:IsAdmin() -- Allow everybody to use colors
			end

		-- Allow admins and users in the ulx group 'vip to use colors
			AllowedToUseColors = function(ply)
				if ply:IsAdmin() then
					return true
				end

				if ply:IsUserGroup("vip") then
					return true
				end
			end
	]]


-- Player Chat Icons, checked in order they are placed here. These are pretty difficult to make work with every gamemode.
-- Confirmed working with: SANDBOX, TTT, chat-affecting mods are likely to intefere here.
	ChatIconsEnabled = true

	chat.RegisterIcon("icon16/star.png", function(ply)
		return ply:IsAdmin()
	end)

	--[[ EXAMPLES Chat Icons
		-- All available icon names can be found at: http://www.famfamfam.com/lab/icons/silk/previews/index_abc.png
		
		-- Heart for ULX users in "vip" usergroup
			chat.RegisterIcon("icon16/heart.png", function(ply)
				return ply:IsUserGroup("vip")
			end)

		-- Rosette for ULX users in "respected" usergroup
			chat.RegisterIcon("icon16/rosette.png", function(ply)
				return ply:IsUserGroup("respected")
			end)

		-- Speech Bubble for everybody
			chat.RegisterIcon("icon16/comment.png", function(ply)
				return true
			end)
	]]