--[[
  Unfinished as of 4/11.
  Was currently working on understanding how tools work entirely, this was my first time ever making a move from scratch, and understanding server/client relationship.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFramework = require(ReplicatedStorage:WaitForChild("SharedFramework"))()
local ConnectionsRecord = require(SharedFramework.FetchModule("ConnectionsRecord"))
local HttpService = SharedFramework.FetchService("HttpService")
local InternalCooldown = require(SharedFramework.FetchModule("InternalCooldown"))
local DataStore = require(SharedFramework.FetchModule("DataStore"))
local GlobalTime = require(SharedFramework.FetchModule("GlobalTime"))
local RunService = SharedFramework.FetchService("RunService")
local Players = SharedFramework.FetchService("Players")
local PlayerGlobalStates = ReplicatedStorage:WaitForChild("PlayerGlobalStates")
local StateManager = require(SharedFramework.FetchModule("StateManager"))

local Object = {}
Object.__index = Object

function Object.NewTool(Player, Character, Humanoid, StateObject, Tool, CommunicationRemote)
	local self = setmetatable({}, Object)
	self.ObjectIdentifier = HttpService:GenerateGUID(false)
	CommunicationRemote.Name = self.ObjectIdentifier
	self.Handle = Tool:FindFirstChild("Handle")
	if not self.Handle then return false end
	self.Player = Player
	self.Character = Character
	self.Humanoid = Humanoid
	self.StateObject = StateObject
	self.Tool = Tool
	self.CommunicationRemote = CommunicationRemote
	self.CompleteBridge = CommunicationRemote:WaitForChild("CompleteBridge")
	self.Equipped = false
	self.CanUnequip = true
	self.LastUnequipTime = 0
	self.Cooldown = InternalCooldown.NewCooldown()
	self:SetUp()
	return self
end

function Object:GetUniqueName()
	return self.Tool.Name..self:GetIdentifier()
end

function Object:GetIdentifier()
	return self.ObjectIdentifier
end

function Object:SetUp()
	local ObjectIdentifier = self.ObjectIdentifier
	self.ActiveConnectionRecord = ConnectionsRecord.NewRecord()
	self.ActiveConnectionRecord:SetCleaner(function() end)
	self.ActiveConnectionRecord:AddConnection(self.CommunicationRemote.OnServerEvent:Connect(function(player, type, ...)
		if player ~= self.Player then
			player:Kick("[002]")
			return
		end
	end))
	self.ActiveConnectionRecord:AddConnection(self.Tool.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			if not self.StateObject:HasBeenPurged() then
				self.StateObject:DropToolObject(self:GetUniqueName())
			end
		end
	end))
	self.ActiveConnectionRecord:AddConnection(self.Tool.Equipped:Connect(function()
		if not self:EquipRequest() then
			local Player, Humanoid = self.Player, self.Humanoid
			if Player and Humanoid then
				pcall(function()
					task.defer(function()
						pcall(function()
							local _GL_OBJ_IGNORE_ = Player:GetAttribute("_GL_OBJ_IGNORE_")
							if _GL_OBJ_IGNORE_ and _GL_OBJ_IGNORE_ ~= ObjectIdentifier then return end
							Humanoid:UnequipTools()
						end)
					end)
				end)
			end
		end
	end))
	self.ActiveConnectionRecord:AddConnection(self.Tool.Unequipped:Connect(function()
		if not self:UnequipRequest() then
			local Player, Tool, Humanoid = self.Player, self.Tool, self.Humanoid
			if Player and Tool and Humanoid then
				pcall(function()
					task.defer(function()
						pcall(function()
							local _GL_OBJ_IGNORE_ = Player:GetAttribute("_GL_OBJ_IGNORE_")
							if _GL_OBJ_IGNORE_ and _GL_OBJ_IGNORE_ ~= ObjectIdentifier then return end
							Humanoid:EquipTool(Tool)
						end)
					end)
				end)
			end
		end
	end))
	self.ActiveConnectionRecord:AddConnection(self.Tool.Activated:Connect(function()
		self:Activated()
	end))
end

function Object:Equip()
	self.Equipped = true
end

function Object:Unequip()
	self.LastUnequipTime = os.clock()
	self.Equipped = false
end

function Object:EquipRequest()
	if self.Equipped then return true end
	local _GL_OBJ_LOCK_ = self.Player:GetAttribute("_GL_OBJ_LOCK_")
	if _GL_OBJ_LOCK_ and _GL_OBJ_LOCK_ ~= "" and _GL_OBJ_LOCK_ ~= self.ObjectIdentifier then return false end
	self.Player:SetAttribute("_GL_OBJ_LOCK_", self.ObjectIdentifier)
	self:Equip()
	self.Player:SetAttribute("_GL_OBJ_LOCK_", nil)
	return true
end

function Object:UnequipRequest()
	if not self.Equipped then return true end
	if not self.CanUnequip then return false end
	local _GL_OBJ_LOCK_ = self.Player:GetAttribute("_GL_OBJ_LOCK_")
	if _GL_OBJ_LOCK_ and _GL_OBJ_LOCK_ ~= "" and _GL_OBJ_LOCK_ ~= self.ObjectIdentifier then return false end
	self.Player:SetAttribute("_GL_OBJ_LOCK_", self.ObjectIdentifier)
	self:Unequip()
	self.Player:SetAttribute("_GL_OBJ_LOCK_", nil)
	return true
end

function Object:Activated()
	local Character = self.Character
	if not Character then return end
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	local Humanoid = self.Humanoid
	if not Humanoid then return end
	if not HumanoidRootPart then return end
	local Player = self.Player
	local StateObject = self.StateObject
	if not Player then return end
	if not StateObject then return end
	local CommunicationRemote = self.CommunicationRemote
	if not CommunicationRemote then return end
	
	

	if (StateObject:IsBlocking()) or (StateObject:IsStunned()) or (StateObject:IsInGlobalCooldown()) then return end
	if StateObject:GetInstanceCarriedBy() or StateObject:IsRagdolled() or StateObject:IsBeingGripped() then return end

	local clock = os.clock()
	if not self.Cooldown:IsCooldownFinish(clock) then return end

	local Cooldown = 15
	self.Cooldown:SetCooldown(clock, Cooldown)
	
	local MouseTarget = nil
	pcall(function()
		MouseTarget = self.CompleteBridge:InvokeClient(Player)
	end)
	if not MouseTarget then
		self.Cooldown:SetCooldown(clock, 0)
		return
	end
	if typeof(MouseTarget) ~= "Vector3" then
		self.Cooldown:SetCooldown(clock, 0)
		return
	end
	
	local distance = (MouseTarget - HumanoidRootPart.Position).Magnitude
	if distance > 500 then
		self.Cooldown:SetCooldown(clock, 0)
		return
	end

	local SyncCooldown = GlobalTime() + Cooldown
	CommunicationRemote:FireClient(self.Player, "Cooldown", SyncCooldown)
	CommunicationRemote:FireClient(self.Player, "Zeus", HumanoidRootPart, MouseTarget)

	StateObject:GlobalCooldownFor(4.38)
end

function Object:Deactivated()
end

function Object:DropTool()
end

function Object:Drop()
	local _GL_OBJ_IGNORE_ = self.Player:GetAttribute("_GL_OBJ_IGNORE_")
	if _GL_OBJ_IGNORE_ and _GL_OBJ_IGNORE_ == self.ObjectIdentifier then
		self.Player:SetAttribute("_GL_OBJ_IGNORE_", nil)
	end
	self.Equipped = false
	self.Tool:Destroy()
	self.ActiveConnectionRecord:CleanRecord()
	self.CommunicationRemote:Destroy()
end

return Object
