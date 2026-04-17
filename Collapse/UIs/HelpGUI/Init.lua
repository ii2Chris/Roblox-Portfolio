--[[
  !! If you don't already have a script that handles server->client UI, then you'd need to create a client script in order for the UIs to appear for the player!
]]


local TweenService = game:GetService("TweenService")
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("ReplicatedStorage_ACH_Package"):WaitForChild("Remotes")
local HelpNotify = Remotes:WaitForChild("HelpNotification")
local HelpAction  = Remotes:WaitForChild("HelpAction")
local HelpToggle = Remotes:WaitForChild("HelpToggle")

local Screen       = script.Parent
local Container    = Screen:WaitForChild("Container")
local CardTemplate = Container:WaitForChild("CardTemplate")

local CARD_W    = CardTemplate.Size.X.Offset
local CARD_H    = CardTemplate.Size.Y.Offset
local TWEEN_IN  = TweenInfo.new(0.3,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.2,  Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local TWEEN_COL = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local admintoggle = false
local currentWatch = nil

-- change time depending on how long ago message was sent, color changes as well :]
local function formatTimestamp(elapsed)
	local mins = math.floor(elapsed / 60)
	if mins < 1 then
		return '<font color="rgb(180,180,180)">just now</font>'
	elseif mins < 3 then
		return '<font color="rgb(210,210,210)">' .. mins .. ' min ago</font>'
	elseif mins < 8 then
		return '<font color="rgb(255,200,50)">' .. mins .. ' min ago</font>'
	else
		return '<font color="rgb(220,70,70)">' .. mins .. ' min ago</font>'
	end
end

local function createCard(username, renderedName, message)
	local wrapper = Instance.new("Frame")
	wrapper.Name                   = "CardWrapper"
	wrapper.Size                   = UDim2.new(0, CARD_W, 0, CARD_H)
	wrapper.BackgroundTransparency = 1
	wrapper.Parent                 = Container

	local card = CardTemplate:Clone()
	card.Visible              = true
	card.Position             = UDim2.new(0, -(CARD_W + 16), 0, 0)
	card.Parent               = wrapper
	card.Username.Text        = "@" .. (username or "Unknown") .. " • " .. (renderedName or "Unknown")
	card.Message.Text         = message or ""
	card.Timestamp.Text       = formatTimestamp(0)

	TweenService:Create(card, TWEEN_IN, {
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()

	local spawnTime = os.clock()
	task.spawn(function()
		while card.Parent do
			task.wait(30)
			if card.Parent then
				card.Timestamp.Text = formatTimestamp(os.clock() - spawnTime)
			end
		end
	end)

	card.Close.MouseButton1Click:Connect(function()
		if currentWatch == username then
			HelpAction:FireServer("unwatch")
			currentWatch = nil
		end

		card.Close.Active = false

		local slideOut = TweenService:Create(card, TWEEN_OUT, {
			Position = UDim2.new(0, -(CARD_W + 16), 0, 0),
		})
		slideOut:Play()
		slideOut.Completed:Wait()

		wrapper.ClipsDescendants = true
		TweenService:Create(wrapper, TWEEN_COL, {
			Size = UDim2.new(0, CARD_W, 0, 0),
		}):Play()

		task.delay(TWEEN_COL.Time, function()
			wrapper:Destroy()
		end)
	end)
	
	card.Respawn.MouseButton1Click:Connect(function()
		HelpAction:FireServer("respawn", username)
	end)
	
	card.Watch.MouseButton1Click:Connect(function()
		if currentWatch == username then
			HelpAction:FireServer("unwatch")
			currentWatch = nil
		else
			HelpAction:FireServer("watch", username)
			currentWatch = username
		end
	end)

	return wrapper
end

HelpToggle.OnClientEvent:Connect(function(isVisible)
	admintoggle = isVisible
	Container.Visible = isVisible
end)

HelpNotify.OnClientEvent:Connect(function(username, renderedName, message)
	if admintoggle then
		createCard(username, renderedName, message)
	end
end)

return { createCard = createCard }
