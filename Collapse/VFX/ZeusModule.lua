--[[
    ZeusModule - Client VFX handler for the Zeus lightning move.
    
    Originally written by a third party for a different game — adapted to work within this game's systems. 
    Key changes made:
    - Fixed asset replication by moving Assets folder to ReplicatedStorage
    - Replaced PlayerCFrame (player position) with mouse target position
      so VFX spawns at the aimed location rather than on the caster
    - Fixed SetPrimaryPartCFrame failures by setting PrimaryPart at runtime
    - Replaced Weld with WeldConstraint for internal sub-part attachment
    - Inlined the screen burst effect (previously a separate module)
    - Added missing enable loops for Storm.MainWind and Storm.SecondLayer
    - Guarded optional Lighting/Atmosphere properties that may not exist
    
    The move has three visual phases:
    1. WindUp (~0-3.4s) — ground charge particles
    2. Storm (~3.4-6.9s) — lightning storm overhead  
    3. Blast (~6.9-11s) — explosion and afterwind meshes

	Reminder: Originally, this wasn't my code. It was an emitter script given to me, to play out the VFX and meshes, but I had to reconfigure, and--
	readd the broken meshes, particles, modules, myself.
]]

local Sequence = {}

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

local Assets = script.Parent.Parent.Particles.ZEUSParticles.Assets
-- local Animations = Assets.Animations
local Sounds = Assets.Sounds
local VFX = Assets.VFX
local Modules = Assets.Modules

local EF_Settings = {
	EffectFolderDirectory = workspace.IgnoredInstances,
	EffectFolderName = "MS_VFX"
}

local ZephsUtilsFolder = Modules.ZephsUtils

local ZephsCameraEffects = require(ZephsUtilsFolder.ZephsCamEffects)
local AllModules = require(ZephsUtilsFolder.AllModules)
local ShakeCamera = require(Modules.ShakeCamera)
local Assistance = require(Modules.Assistance)
local OriginalFov = CurrentCamera.FieldOfView

local TWEEN_0_5  = TweenInfo.new(0.5)
local TWEEN_1   = TweenInfo.new(1)
local TWEEN_1_5 = TweenInfo.new(1.5)
local TWEEN_2   = TweenInfo.new(2)

Sequence.RunStompFx = function(p1, p2, p3, p4)
	if not p3.Character or not p3.Character:FindFirstChild("Torso") then return end
	local isNearEffect = (p3.Character.Torso.Position - p2.Position).Magnitude <= 200

	local Folder = Instance.new("Folder", EF_Settings.EffectFolderDirectory)
	Folder.Name = EF_Settings.EffectFolderName
	Debris:AddItem(Folder, 20)
	
	local fxcc = nil
	local PlayerCFrame = CFrame.new(p2.Position)

	local SFX = Sounds.SFX:Clone()
	SFX.Parent = Folder
	SFX.PlayOnRemove = true
	SFX:Destroy()

	task.wait(0.3)

	if isNearEffect then
		ShakeCamera.ShakeCamera(0.7, 5, .2, 4)
	end

	task.delay(.15, function()
		local Start = VFX.Start:Clone()
		Start.Parent = Folder
		Start.CFrame = PlayerCFrame * CFrame.new(0, -2, 0)
		for _, v in ipairs(Start:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
	end)

	if isNearEffect then
		ShakeCamera.ShakeCamera(1, 50, .2, 1.3)
		ZephsCameraEffects.ZephImpactFrames(1)
		ZephsCameraEffects.Flash(1.2)
	end

	local WindUp = VFX.WindUp:Clone()
	WindUp.PrimaryPart = WindUp.LongSpecs
	WindUp:SetPrimaryPartCFrame(PlayerCFrame * CFrame.new(0, -2.7, 0))
	WindUp.Parent = Folder

	for _, v in ipairs(WindUp.Charge.Ground:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end

	for _, v in ipairs(WindUp.LongSpecs:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end

	local Storm = VFX.Storm:Clone()
	Storm:SetPrimaryPartCFrame(PlayerCFrame)
	Storm.Parent = Folder

	task.wait(3)

	task.spawn(function()
		if isNearEffect then
			ZephsCameraEffects.FOV(80, .5)
			ShakeCamera.ShakeCamera(4, 65, .2, 1.5)
			ZephsCameraEffects.ZephImpactFrames(2)
			AllModules.blurScreenEffect(12, 1.7)
			task.wait(1.2)
			ZephsCameraEffects.FOV(OriginalFov, .8)
			ShakeCamera.ShakeCamera(2, 65, 1.5, 3)
		end			
	end)

	for _, v in ipairs(WindUp.Charge.Emit:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
	
	task.spawn(function()
		local WindUpMesh = VFX.WindUpEmitWind:Clone()
		WindUpMesh.PrimaryPart = WindUpMesh:FindFirstChildWhichIsA("BasePart", true)
		WindUpMesh:SetPrimaryPartCFrame(PlayerCFrame * CFrame.new(0, 3, 0))
		WindUpMesh.Parent = Folder

		TweenService:Create(WindUpMesh.Wind, TWEEN_2, {Size = WindUpMesh.Wind.Size * 2.5, Orientation = WindUpMesh.Wind.Orientation + Vector3.new(0, 360, 0)}):Play()
		TweenService:Create(WindUpMesh.Wind, TWEEN_1_5, {Transparency = 1}):Play()
		TweenService:Create(WindUpMesh.Wind2, TWEEN_2, {Size = WindUpMesh.Wind2.Size * 3.5, Orientation = WindUpMesh.Wind2.Orientation + Vector3.new(0, 360, 0)}):Play()
		TweenService:Create(WindUpMesh.Wind2, TWEEN_1_5, {Transparency = 1}):Play()
	end)

	for i, v in ipairs(WindUp.Soon:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Parent = WindUp.Charge
		end
	end

	local Charge = VFX.Charge:Clone()
	for _, v in ipairs(Charge:GetDescendants()) do
		if v:IsA("ParticleEmitter") and v.Name ~= "Charging" then
			v.Enabled = true
		end
	end
	Charge.CFrame = PlayerCFrame * CFrame.new(0, -2.5, 0)
	Charge.Parent = Folder

	task.delay(0.3, function()
		WindUp:Destroy()
	end)

	task.wait(2)

	for _, v in ipairs(Storm.Storm.MainFX:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end
	
	for _, v in ipairs(Storm.Storm.MainWind:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end

	for _, v in ipairs(Storm.Storm.SecondLayer:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end

	ZephsCameraEffects.FOV(OriginalFov, .7)
	ZephsCameraEffects.Flash(2)
	ShakeCamera.ShakeCamera(3, 45, .2, 1.1)

	task.wait(1.1)

	if isNearEffect then
		task.spawn(function()
			local ScreenBurst = VFX.ScreenBurst:Clone()
			ScreenBurst.Parent = Folder
			for _, v in ipairs(ScreenBurst:GetDescendants()) do
				if v:IsA("ParticleEmitter") then
					v:Emit(v:GetAttribute("EmitCount") or 10)
				end
			end
			local d = 5
			local Lock = RunService.RenderStepped:Connect(function()
				ScreenBurst.CFrame = workspace.CurrentCamera.CFrame + (workspace.CurrentCamera.CFrame.LookVector * 0.7)
			end)
			task.delay(d, function()
				Lock:Disconnect()
				if ScreenBurst then
					ScreenBurst:Destroy()
				end
			end)
		end)
	end

	task.wait(0.4)

	task.spawn(function()
		if isNearEffect then
			ShakeCamera.ShakeCamera(2, 75, .2, 5)
			ZephsCameraEffects.ZephImpactFrames(3)
			ZephsCameraEffects.Flash(2)
			ZephsCameraEffects.FOV(85, .6)
			AllModules.blurScreenEffect(12, 1)
		end		
	end)

	local Blast = VFX.Blast:Clone()
	Blast.Parent = Folder
	Blast:SetPrimaryPartCFrame(PlayerCFrame * CFrame.new(0,-2.5,0))

	task.wait(0.1)

	task.spawn(function()
		local WM = VFX.AfterChargeWind:Clone()
		WM:SetPrimaryPartCFrame(PlayerCFrame * CFrame.new(0, 3, 0))
		WM.Parent = Folder

		task.spawn(Assistance, WM)

		TweenService:Create(WM.Endish, TWEEN_1_5, {Orientation = WM.Endish.Orientation + Vector3.new(0, 500, 0)}):Play()
		TweenService:Create(WM.Endish.Mesh, TWEEN_1_5, {Scale = Vector3.new(WM.Endish.Mesh.Scale.X * 4.5, WM.Endish.Mesh.Scale.Y * 4.5, WM.Endish.Mesh.Scale.Z * 4.5)}):Play()
		TweenService:Create(WM.Endish.Decal, TWEEN_2, {Transparency = 1}):Play()

		TweenService:Create(WM.Startish, TWEEN_1, {Orientation = WM.Startish.Orientation + Vector3.new(0, 500, 0)}):Play()
		TweenService:Create(WM.Startish.Mesh, TWEEN_1, {Scale = WM.Startish.Mesh.Scale * 4}):Play()
		TweenService:Create(WM.Startish.Decal, TWEEN_0_5, {Transparency = 1}):Play()

		TweenService:Create(WM.WindMeshPart, TWEEN_2, {Orientation = WM.WindMeshPart.Orientation + Vector3.new(0, 700, 0)}):Play()
		TweenService:Create(WM.WindMeshPart.Mesh, TWEEN_2, {Scale = Vector3.new(WM.WindMeshPart.Mesh.Scale.X * 5, WM.WindMeshPart.Mesh.Scale.Y * 1.5, WM.WindMeshPart.Mesh.Scale.Z * 5)}):Play()
		TweenService:Create(WM.WindMeshPart.Decal, TWEEN_1_5, {Transparency = 1}):Play()
	end)
	
	for _, v in ipairs(Charge:GetDescendants()) do
		if v:IsA("ParticleEmitter") and v.Name == "Charging" then
			v.Enabled = true
		end
	end
	
	for _, v in ipairs(Blast:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			if v:GetAttribute("EmitDelay") then
				task.delay(v:GetAttribute("EmitDelay"), function()
					v:Emit(v:GetAttribute("EmitCount") or 0)
				end)
			else
				v:Emit(v:GetAttribute("EmitCount") or 0)
			end
		end
	end

	for _, v in ipairs(Storm.Charge:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end

	for _, v in ipairs(Storm.CounterShock:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end
	
	
	if isNearEffect then
		fxcc = VFX.fxcc:Clone()
		fxcc.Parent = game.Lighting
		Debris:AddItem(fxcc, 10)
		TweenService:Create(fxcc, TWEEN_0_5, {Brightness = -.08, Contrast = .1}):Play()
	end

	task.wait(1)

	for _, v in ipairs(Storm.Storm:GetDescendants()) do
		if v:IsDescendantOf(Storm.Storm.MainWind) or v:IsDescendantOf(Storm.Storm.SecondLayer) then
			if v:IsA("ParticleEmitter") then
				v.TimeScale = 1
				v.Enabled = false
			end
		end
	end

	task.wait(3)

	if isNearEffect then
		ZephsCameraEffects.FOV(OriginalFov, .7)
		ZephsCameraEffects.Flash(2)
		ShakeCamera.ShakeCamera(3, 45, .2, 1.1)
	end

	for _, v in ipairs(Folder:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Rate = v.Rate / 15
		end
	end

	task.wait(0.2)

	if isNearEffect and fxcc and fxcc.Parent then
		TweenService:Create(fxcc, TWEEN_1, {Brightness = 0, Saturation = 0, Contrast = 0}):Play()
	end

	for _, v in ipairs(Folder:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("PointLight") then
			v.Enabled = false
		end
	end

end

return Sequence
