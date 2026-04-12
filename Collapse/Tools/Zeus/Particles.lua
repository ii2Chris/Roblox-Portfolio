["Zeus"] = function(hrp, mousePos)
		local Zeus = require(ReplicatedStorage.ReplicatedStorage_ACH_Package.Assets.AbilityModules.ZeusModule)

		local anchor = Instance.new("Part")
		anchor.Size = Vector3.new(1,1,1)
		anchor.Position = mousePos + Vector3.new(0, 2, 0)
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Massless = true
		anchor.Transparency = 1
		anchor.Parent = workspace
		game:GetService("Debris"):AddItem(anchor, 15)

		Zeus.RunStompFx(nil, anchor, game:GetService("Players").LocalPlayer, nil)
	end
