--[[
  Unfinished as of 4/11.
  Was currently working on understanding how tools work entirely, this was my first time ever making a move from scratch, and understanding server/client relationship.
]]

task.defer(function()
	script.Parent = nil
	game:GetService("Debris"):AddItem(script, 0)
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerGlobalStates = ReplicatedStorage:WaitForChild("PlayerGlobalStates")
local SharedFramework = require(ReplicatedStorage:WaitForChild("SharedFramework"))()
local LocalPlayer = SharedFramework.GetSharedData("LocalPlayer")
local Mouse = LocalPlayer:GetMouse()
local SharedState = PlayerGlobalStates:WaitForChild(LocalPlayer.Name)
local ConnectionsRecord = require(SharedFramework.FetchModule("ConnectionsRecord"))
local UserInputService = SharedFramework.FetchService("UserInputService")
local RunService = SharedFramework.FetchService("RunService")
local CharacterProxy = SharedFramework.GetSharedData("CharacterProxy")
local GlobalTime = require(SharedFramework.FetchModule("GlobalTime"))

local Tool = script.Parent
local ToolName = Tool.Name
local Identifier = script:WaitForChild("Identifier")
local CommunicationRemote = SharedState:WaitForChild(Identifier.Value)
local CompleteBridge = CommunicationRemote:WaitForChild("CompleteBridge")
local ToolConnectionRecord = ConnectionsRecord.NewRecord()

local CONNECTION = nil

CommunicationRemote.Name = ""
CommunicationRemote.Parent = nil

local function FireRemote(...)
	CommunicationRemote.Parent = SharedState
	CommunicationRemote:FireServer(...)
	CommunicationRemote.Parent = nil
end

local function Drop()
	if CONNECTION then
		CONNECTION:Disconnect()
		CONNECTION = nil
	end
	CommunicationRemote:Destroy()
end

local function OnEquipped()
end
local function Unequipped()
end
local function Activated()
end
local function Deactivated()
end

CompleteBridge.OnClientInvoke = function()
	return Mouse.Hit.Position
end
ToolConnectionRecord:AddConnection(Tool.Equipped:Connect(OnEquipped))
ToolConnectionRecord:AddConnection(Tool.Unequipped:Connect(Unequipped))
ToolConnectionRecord:AddConnection(Tool.Activated:Connect(Activated))
ToolConnectionRecord:AddConnection(Tool.Deactivated:Connect(Deactivated))
ToolConnectionRecord:AddConnection(UserInputService.InputBegan:Connect(function(k,e)
	if e then return end
	local Target = Mouse.Target
	if k.KeyCode == Enum.KeyCode.Backspace then
		FireRemote(-1)
	end
end))
ToolConnectionRecord:AddConnection(Tool.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		ToolConnectionRecord:CleanRecord()
		Drop()
	end
end))
ToolConnectionRecord:AddConnection(CommunicationRemote.OnClientEvent:Connect(function(type,...)
	if type == "Cooldown" then
		if CONNECTION then
			CONNECTION:Disconnect()
			CONNECTION= nil
		end
		
		local args = {...}
		local syncCD = args[1]
		local syncNOW = GlobalTime()
		if syncNOW > syncCD then
			return
		end
		local durationLEFT = syncCD - syncNOW
		local localTIME = os.clock() + durationLEFT
		CONNECTION = RunService.Stepped:Connect(function()
			if Tool.Parent == nil then
				CONNECTION:Disconnect()
				Tool.Name = ToolName
				CONNECTION = nil
				return
			end
			local NOW = os.clock()
			if NOW >= localTIME then
				CONNECTION:Disconnect()
				Tool.Name = ToolName
				CONNECTION = nil
				return
			end
			local ELAPSED = localTIME - NOW
			Tool.Name = ToolName.." ["..string.format("%.1f", ELAPSED).."s]"
		end)
	end
	if type == "BeginAim" then
		--[[
		if not CONNECTION then
			local HRP = CharacterProxy.HumanoidRootPart
			CONNECTION = RunService.Heartbeat:Connect(function()
				if not HRP then
					HRP = CharacterProxy.HumanoidRootPart
				end
				if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter and HRP then
					local POS = Mouse.Hit.p
					HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(
						POS.X,
						HRP.Position.Y,
						POS.Z
						))
				end
			end)
		end
		--]]
	elseif type == "StopAim" then
		--[[
		if CONNECTION then
			CONNECTION:Disconnect()
			CONNECTION = nil
		end
		--]]
	end
end))

return {}
