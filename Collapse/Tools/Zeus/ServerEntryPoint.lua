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
local HitboxHelper = require(SharedFramework.FetchModule("HitboxHelper"))
local ReplicatedStorage_ACH_Package = ReplicatedStorage:WaitForChild("ReplicatedStorage_ACH_Package")
local Assets = ReplicatedStorage_ACH_Package:WaitForChild("Assets")
local Remotes = ReplicatedStorage_ACH_Package:WaitForChild("Remotes")
local ClientParticle = Remotes:WaitForChild("ClientParticle")
local ServerClientHitbox = require(SharedFramework.FetchModule("ServerClientHitbox"))

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

	local Cooldown = 25
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
	ClientParticle:FireAllClients("Zeus", HumanoidRootPart, MouseTarget)

	StateObject:GlobalCooldownFor(4.38)
	
	local PlayerProfile = DataStore.GetProfile(self.Player)
	local Damage = 15 + math.min(PlayerProfile:GetPsyche(), 300) * 0.16
	local PillarDamage = 25 + math.min(PlayerProfile:GetPsyche(), 300) * 0.16
	
	local FlatHitbox1 = HitboxHelper.NewHelper(HitboxHelper.Enum.HitboxType.Space,  {
		Anchored = true,
		Size = Vector3.new(180, 10, 180),
		CFrame = CFrame.new(MouseTarget)	
	})
	FlatHitbox1.Parent = SharedFramework.GetSharedData("IgnoredInstances")
	game:GetService("Debris"):AddItem(FlatHitbox1, 3.4)
	
	local manualRelease
	manualRelease = ServerClientHitbox.SpawnServerClientHitbox(
		self.Player, 
		HumanoidRootPart, 
		50, 
		FlatHitbox1, 
		Vector3.new(), 
		Vector3.new(1, 1, 1),
		{
			SharedFramework.GetSharedData("IgnoredInstances"),
			Character,
		},
		1/10,
		3.4,
		180,
		180,
		true,
		function (InstanceHit, TargetHumanoid, TargetHumanoidRootPart)
			local TargetCharacter = TargetHumanoid.Parent
			if not TargetCharacter then return end
			local EnemeyStateObject = StateManager[TargetCharacter]
			if not EnemeyStateObject then return end
			if not EnemeyStateObject:MatchingHitFilter(self.StateObject) then return end
			if EnemeyStateObject:IsInIFrame(os.clock()) then return end
			if not EnemeyStateObject:CanBeHurtBy(self.Humanoid) then return end
			
			EnemeyStateObject:UniquePushSpeedReduction(0.4, 3.4, "ZeusPhase1")
		end,
		function()
			FlatHitbox1:Destroy()
		end,
		ServerClientHitbox.PingFallbackHelper("default"),
		function(InstanceHit, TargetHumanoid, TargetHumanoidPart)
			return true
		end,
		1
	)
	
	task.wait(3.4)
	
	local FlatHitbox2 = HitboxHelper.NewHelper(HitboxHelper.Enum.HitboxType.Space,  {
		Anchored = true,
		Size = Vector3.new(240, 10, 240),
		CFrame = CFrame.new(MouseTarget)	
	})
	FlatHitbox2.Parent = SharedFramework.GetSharedData("IgnoredInstances")
	game:GetService("Debris"):AddItem(FlatHitbox2, 8.6)

	local manualRelease2
	manualRelease = ServerClientHitbox.SpawnServerClientHitbox(
		self.Player, 
		HumanoidRootPart, 
		50, 
		FlatHitbox2, 
		Vector3.new(), 
		Vector3.new(1, 1, 1),
		{
			SharedFramework.GetSharedData("IgnoredInstances"),
			Character,
		},
		1/10,
		7.6,
		180,
		180,
		true,
		function (InstanceHit, TargetHumanoid, TargetHumanoidRootPart)
			local TargetCharacter = TargetHumanoid.Parent
			if not TargetCharacter then return end
			local EnemeyStateObject = StateManager[TargetCharacter]
			if not EnemeyStateObject then return end
			if not EnemeyStateObject:MatchingHitFilter(self.StateObject) then return end
			if EnemeyStateObject:IsInIFrame(os.clock()) then return end
			if not EnemeyStateObject:CanBeHurtBy(self.Humanoid) then return end
			
			EnemeyStateObject:UniquePushSpeedReduction(0, 3.4, "ZeusPhase2")
			TargetHumanoid:TakeDamage(Damage * 0.1)
			EnemeyStateObject:FlagHurtBy(self.Player, PlayerProfile, self.StateObject, Character, Humanoid, HumanoidRootPart, Damage * 0.1, true)
		end,
		function()
			FlatHitbox2:Destroy()
		end,
		ServerClientHitbox.PingFallbackHelper("default"),
		function(InstanceHit, TargetHumanoid, TargetHumanoidPart)
			return true
		end,
		1
	)
	
	task.wait(3.5)
	
	local CylinderHitbox = HitboxHelper.NewHelper(HitboxHelper.Enum.HitboxType.Space,  {
		Anchored = true,
		Size = Vector3.new(90, 320, 90),
		CFrame = CFrame.new(MouseTarget)	
	})
	CylinderHitbox.Parent = SharedFramework.GetSharedData("IgnoredInstances")
	game:GetService("Debris"):AddItem(CylinderHitbox, 4.1)
	
	local manualRelease2
	manualRelease = ServerClientHitbox.SpawnServerClientHitbox(
		self.Player, 
		HumanoidRootPart, 
		50, 
		CylinderHitbox, 
		Vector3.new(), 
		Vector3.new(1, 1, 1),
		{
			SharedFramework.GetSharedData("IgnoredInstances"),
			Character,
		},
		1/10,
		4.1,
		180,
		180,
		true,
		function (InstanceHit, TargetHumanoid, TargetHumanoidRootPart)
			local TargetCharacter = TargetHumanoid.Parent
			if not TargetCharacter then return end
			local EnemeyStateObject = StateManager[TargetCharacter]
			if not EnemeyStateObject then return end
			if not EnemeyStateObject:MatchingHitFilter(self.StateObject) then return end
			if EnemeyStateObject:IsInIFrame(os.clock()) then return end
			if not EnemeyStateObject:CanBeHurtBy(self.Humanoid) then return end

			EnemeyStateObject:UniquePushSpeedReduction(0, 3.4, "ZeusPhase3")
			TargetHumanoid:TakeDamage(PillarDamage * 0.4)
			EnemeyStateObject:FlagHurtBy(self.Player, PlayerProfile, self.StateObject, Character, Humanoid, HumanoidRootPart, Damage * 0.1, true)
		end,
		function()
			CylinderHitbox:Destroy()
		end,
		ServerClientHitbox.PingFallbackHelper("default"),
		function(InstanceHit, TargetHumanoid, TargetHumanoidPart)
			return true
		end,
		1
	)
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
