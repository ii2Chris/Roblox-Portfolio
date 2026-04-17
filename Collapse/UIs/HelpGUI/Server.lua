--[[
  This should exist in wherver the use can chat, so if they say !help, ;help, or /help, the message can be send and create as a help gui
]]

-- help command, send to the HelpGUI which is enabled through showhelp cmdr command
		local lowerMsg = string.lower(message)
		local prefix = string.sub(lowerMsg, 1, 5)
		if prefix == "!help" or prefix == "/help" or prefix == ";help" then
			local renderedName = PlayerProfileReplica:GetRenderedName()
			local helpMessage = string.sub(message, 7)
			HelpNotify:FireAllClients(player.Name, renderedName, helpMessage)
		end
