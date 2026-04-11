--[[
    SteelRushParts - Client VFX handler for the Steel Rush move. This move is apart of a bigger 'particle' module, that handles all basic moves.
    
    Manages the wind VFX that surrounds the player during a rush.
    Previously updated the VFX position every frame via CFrame — 
    rewrote to use WeldConstraint instead, attaching the VFX model 
    to the HumanoidRootPart once at the start so the engine handles 
    tracking automatically.
    
    The Stepped loop only runs to track move duration and trigger footstep sounds.
    
    StopSteelRushParts can be called externally to cancel the effect early. Looking back at it, I could've wrote the fadeing within StopSteelRushParts and just call that, but it does its job.
]]


["StopSteelRushParts"] = function(HumanoidRootPart)
		if not HumanoidRootPart then return end
		SteelRushPartsCache[HumanoidRootPart] = nil
	end,
	["SteelRushParts"] = function(HumanoidRootPart,duration,dontSpawnParts,offset)
		offset = offset or CFrame.new()
		if not HumanoidRootPart then return end
		SteelRushPartsCache[HumanoidRootPart] = true

		local i = os.clock()
		local start = i
		local StompRate = RateHandler.new()

		local SteelRushWind = SteelRushWind:Clone()
		local SteelRushWindVFX = SteelRushWind["SteelRushWindVFX"]
		local Part = SteelRushWindVFX["Part"]
		local Dashwhite = SteelRushWindVFX["Dashwhite"]
		local BeamEmitter = SteelRushWindVFX["BeamEmitter"]
		local RunPart = SteelRushWindVFX["RunPart"]
		
		SteelRushWind.Parent = workspace
		SteelRushWindVFX.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, -7) * offset
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = SteelRushWindVFX
		weld.Part1 = HumanoidRootPart
		weld.Parent = SteelRushWindVFX
		
		local Wind = SteelRushWind["Wind"] --sound
		Wind:Play()
		
		--clean up parts
		local function fadeSubPart(subPart, fadeDuration, destroyDelay)
			for _, desc in ipairs(subPart:GetDescendants()) do
				if desc:IsA("ParticleEmitter") then
					EzTween.SimpleTween(desc, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, fadeDuration, {Rate = 0}):Play()
				end
			end
			task.delay(destroyDelay, function()
				subPart:Destroy()
			end)
		end
		
		-- hanles cleanup, footstomp sound
		local CONNECTION; CONNECTION = RunService.Stepped:Connect(function()
			local e = os.clock()
			local j = e - i
			i = e
			if (e - start) > duration or SteelRushPartsCache[HumanoidRootPart] == nil then
				SteelRushPartsCache[HumanoidRootPart] = nil
				CONNECTION:Disconnect()
				fadeSubPart(Part, 0.15, 0.25)
				fadeSubPart(Dashwhite, 0.5, 0.65)
				fadeSubPart(BeamEmitter, 0.4, 0.55)
				fadeSubPart(RunPart, 0.4, 0.55)
				EzTween.SimpleTween(Wind, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.8, {Volume = 0}):Play()
				task.delay(1, function()
					SteelRushWind:Destroy()
				end)
				return
			end
			if dontSpawnParts then return end
			if StompRate:GetAmount(j, 0.325) > 0 then
				SoundController.Play("FootStomp"..tostring(math.random(0,2)), 90, 110, 100, HumanoidRootPart)
			end
		end)
	end,
