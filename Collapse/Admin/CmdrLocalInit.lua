local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CmdrClient = ReplicatedStorage:WaitForChild("CmdrClient")
local isAdminRemote = CmdrClient:WaitForChild("CmdrIsAdmin")

local isAdmin = isAdminRemote:InvokeServer()
if not isAdmin then
	local cmdrGui = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Cmdr", 5)
	if cmdrGui then cmdrGui:Destroy() end
	return
end

-- for testing purposes, comment above out and uncomment this
--local isAdmin = isAdminRemote:InvokeServer()

local Cmdr = require(CmdrClient)

-- Client-side BeforeRun hook is required so Cmdr doesn't block ClientRun commands
-- in live games when no hook is registered. Admin check already done above.
Cmdr.Registry:RegisterHook("BeforeRun", function(context) end)

Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
