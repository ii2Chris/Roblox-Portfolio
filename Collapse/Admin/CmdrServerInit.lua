local ServerScriptService = game:GetService("ServerScriptService")
local ServerModules = ServerScriptService.ServerScriptService_ACH_Package.ServerModules
local AdminCMDR     = ServerModules.AdminCMDR
local AdminSettings = require(ServerModules.AdminSettings)

local Cmdr = require(AdminCMDR.Cmdr)
Cmdr:RegisterDefaultCommands({"Admin", "Help", "Utility", "Debug"})
Cmdr:RegisterTypesIn(AdminCMDR.Types)
Cmdr:RegisterCommandsIn(AdminCMDR.Commands)

local isAdminRemote = Instance.new("RemoteFunction")
isAdminRemote.Name = "CmdrIsAdmin"
isAdminRemote.Parent = game:GetService("ReplicatedStorage"):WaitForChild("CmdrClient")
isAdminRemote.OnServerInvoke = function(player)
	return AdminSettings[player.Name] ~= nil
end

Cmdr:RegisterHook("BeforeRun", function(context)
	local playerName = context.Executor.Name
	local settings = AdminSettings[playerName]
	if not settings then return "You don't have permission to use admin commands." end
	if table.find(settings, "all") then return end
	local commandName = string.lower(context.Name)
	if not table.find(settings, commandName) then
		return 'No permission to use "' .. context.Name .. '".'
	end
end)
