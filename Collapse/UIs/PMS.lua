--[[ (Summarized with AI)
    messagePMs - Client-side admin notification UI handler.
    
    Displays styled private messages sent from the admin system to the local
    player. Supports three message types, each with distinct visual behavior:
    
    - plainPM: Simple fade-in/out text notification
    - shakyPM: Text with per-frame random offset shake effect
    - basicAnxiety: Full-screen horror effect with camera shake, red vignette,
      heartbeat/ear-ringing audio, and smooth lerp-based transitions.
      Uses RenderStepped for frame-accurate fade timing rather than tweens,
      since the effect has multiple overlapping phases that need precise control.
    
    Also handles an "observe" mode for the admin spectate command, which
    bypasses the camera controller by binding to RenderStepped at Camera
    priority and setting CameraSubject to the target's head each frame.
    
    All message types share cancel logic so triggering a new PM mid-display
    correctly cleans up the previous one. The anxiety effect has its own
    deeper cancel (cancelActive) since it owns additional state like audio
    and the vignette overlay.
    
    Markdown parsing converts Discord-style formatting to Roblox RichText tags,
    supporting bold, italic, underline, strikethrough, and combinations.
]]

-- eyyCopy's code at its finest 3/21 (first UI implementation)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local SharedFramework = require(ReplicatedStorage:WaitForChild("SharedFramework"))()
local ReplicatedStorage_ACH_Package = ReplicatedStorage:WaitForChild("ReplicatedStorage_ACH_Package")
local Remotes             = ReplicatedStorage_ACH_Package:WaitForChild("Remotes")
local AdminClientDispatch = Remotes:WaitForChild("AdminClientDispatch")
local Screen    = script.Parent
local Container = Screen:WaitForChild("Container")
local Display   = Container:WaitForChild("Display")

local function lerp(a, b, t) return a + (b - a) * t end

Container.BackgroundTransparency = 1
Container.Visible                = false
-- Display.TextScaled               = false
Display.RichText                 = true

local activeConn   = nil
local NTime        = 0
local FadeAfter    = 0
local DimFadeAfter = 0
local SHAKE_KEY    = "BasicAnxietyShake"
local Vignette     = script:WaitForChild("Vingette Horror")
Vignette.Parent            = Screen
Vignette.ImageTransparency = 1
Vignette.ImageColor3       = Color3.fromRGB(160, 0, 0)
local HeartSound   = script:WaitForChild("Heart")
local EarRingSound = script:WaitForChild("Ear-Ringing")
local heartFadeTween = nil

-- Markdown parser, discord language to HTML for richtext
local function parseMarkdown(s)
	-- Triple combinations first
	s = s:gsub("%*%*%*__(.-)__%*%*%*", "<b><i><u>%1</u></i></b>")  -- ***__bold italic underline__***
	s = s:gsub("___%*%*%*(.-)%*%*%*___", "<b><i><u>%1</u></i></b>") -- ___***bold italic underline***___
	s = s:gsub("%*%*%*~~(.-)~~%*%*%*", "<b><i><s>%1</s></i></b>")  -- ***~~bold italic strike~~***
	s = s:gsub("%*%*%*(.-)%*%*%*",     "<b><i>%1</i></b>")          -- ***bold italic***
	s = s:gsub("__~~(.-)~~__",         "<u><s>%1</s></u>")          -- __~~underline strike~~__
	s = s:gsub("~~__(.-)__~~",         "<u><s>%1</s></u>")          -- ~~__underline strike__~~
	
	-- Double combinations
	s = s:gsub("%*%*__(.-)__%*%*",     "<b><u>%1</u></b>")          -- **__bold underline__**
	s = s:gsub("%*%*~~(.-)~~%*%*",     "<b><s>%1</s></b>")          -- **~~bold strike~~**
	s = s:gsub("%*__(.-)__%*",         "<i><u>%1</u></i>")          -- *__italic underline__*
	s = s:gsub("%*~~(.-)~~%*",         "<i><s>%1</s></i>")          -- *~~italic strike~~*
	
	-- Singles
	s = s:gsub("%*%*(.-)%*%*",         "<b>%1</b>")                 -- **bold**
	s = s:gsub("%*(.-)%*",             "<i>%1</i>")                 -- *italic*
	s = s:gsub("__(.-)__",             "<u>%1</u>")                 -- __underline__
	s = s:gsub("~~(.-)~~",             "<s>%1</s>")                 -- ~~strikethrough~~
	return s
end

-- Shared state
local activeTween           = nil
local activeThread          = nil
local shakeConn             = nil
local basePosition          = Display.Position
local containerBasePosition = Container.Position
local anxietyActive         = false
local pmActive              = false
local anxietyTextDone       = false

local function stopShake()
	RunService:UnbindFromRenderStep(SHAKE_KEY)
end

local function cancelPM()
	if activeTween  then activeTween:Cancel();      activeTween  = nil end
	if activeThread then task.cancel(activeThread); activeThread = nil end
	if shakeConn    then shakeConn:Disconnect();    shakeConn    = nil end
	Display.Position = basePosition
	pmActive = false
	if anxietyActive then
		anxietyTextDone = true
	end
end

local function cancelActive()
	cancelPM()
	if activeConn then activeConn:Disconnect(); activeConn = nil end
	stopShake()
	HeartSound:Stop()
	EarRingSound:Stop()
	local areaMusic = workspace:FindFirstChild("AreaMusic")
	if areaMusic then
		areaMusic.Volume = (areaMusic:GetAttribute("RVolume") or 0.5) * (areaMusic:GetAttribute("multiplier") or 1)
		areaMusic:SetAttribute("OwnedInterface", nil)
	end
	Vignette.ImageTransparency       = 1
	Container.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	Container.BackgroundTransparency = 1
	Container.Visible                = false
	Container.Position               = containerBasePosition
	Display.TextTransparency         = 1
	anxietyActive   = false
	anxietyTextDone = false
end

local Normal = {
	Font            = Font.new("rbxasset://fonts/families/Montserrat.json"),
	TextSize        = 32,
	TextColor       = Color3.fromRGB(255, 255, 255),
	FadeInDuration  = 0.4,
	DisplayDuration = 5,
	FadeOutDuration = 1.0,
}
local function playNormal(message)
	cancelPM()
	local cfg = Normal
	Display.FontFace         = cfg.Font
	Display.TextSize         = cfg.TextSize
	Display.TextColor3       = cfg.TextColor
	Display.Text             = parseMarkdown(message)
	Display.TextTransparency = 1
	Container.Visible        = true
	pmActive                 = true

	local fadeIn = TweenService:Create(Display, TweenInfo.new(cfg.FadeInDuration), { TextTransparency = 0 })
	activeTween = fadeIn
	fadeIn:Play()

	activeThread = task.delay(cfg.FadeInDuration + cfg.DisplayDuration, function()
		local fadeOut = TweenService:Create(Display, TweenInfo.new(cfg.FadeOutDuration), { TextTransparency = 1 })
		activeTween = fadeOut
		fadeOut:Play()
		fadeOut.Completed:Wait()
		pmActive = false
		if not anxietyActive then
			Container.Visible = false
		end
		activeTween  = nil
		activeThread = nil
	end)
end

local Shaky = {
	Font            = Font.new("rbxasset://fonts/families/Montserrat.json"),
	TextSize        = 32,
	TextColor       = Color3.fromRGB(255, 255, 255),
	FadeInDuration  = 0.4,
	DisplayDuration = 5,
	FadeOutDuration = 1.0,
	ShakeIntensity  = 0.2,
}
local function playShaky(message)
	cancelPM()
	local cfg = Shaky
	Display.FontFace         = cfg.Font
	Display.TextSize         = cfg.TextSize
	Display.TextColor3       = cfg.TextColor
	Display.Text             = parseMarkdown(message)
	Display.TextTransparency = 1
	Container.Visible        = true
	pmActive                 = true

	shakeConn = RunService.RenderStepped:Connect(function()
		local s = cfg.ShakeIntensity
		Display.Position = UDim2.new(
			basePosition.X.Scale,
			basePosition.X.Offset + math.random(-s, s),
			basePosition.Y.Scale,
			basePosition.Y.Offset + math.random(-s, s)
		)
	end)

	local fadeIn = TweenService:Create(Display, TweenInfo.new(cfg.FadeInDuration), { TextTransparency = 0 })
	activeTween = fadeIn
	fadeIn:Play()

	activeThread = task.delay(cfg.FadeInDuration + cfg.DisplayDuration, function()
		if shakeConn then shakeConn:Disconnect(); shakeConn = nil end
		Display.Position = basePosition

		local fadeOut = TweenService:Create(Display, TweenInfo.new(cfg.FadeOutDuration), { TextTransparency = 1 })
		activeTween = fadeOut
		fadeOut:Play()
		fadeOut.Completed:Wait()
		pmActive = false
		if not anxietyActive then
			Container.Visible = false
		end
		activeTween  = nil
		activeThread = nil
	end)
end

local basicAnxiety = {
	Font             = Font.new("rbxassetid://12187365769"),
	TextSize         = 32,
	TextColor        = Color3.fromRGB(255, 255, 255),
	FadeInDuration   = 0.4,
	DisplayDuration  = 15,
	FadeOutDuration  = 1.5,
	DimExtraDuration = 3,
	ShakeDegrees     = 0.4,
	HeartVolume      = 1,
	EarRingVolume    = 1,
}
local function playAnxiety(message)
	cancelActive()
	local cfg    = basicAnxiety
	NTime        = os.clock()
	FadeAfter    = NTime + cfg.DisplayDuration
	DimFadeAfter = FadeAfter + cfg.DimExtraDuration
	anxietyActive   = true
	anxietyTextDone = false
	
	Display.FontFace   = cfg.Font
	Display.TextSize   = cfg.TextSize
	Display.TextColor3 = cfg.TextColor
	Display.Text       = parseMarkdown(message or " ")
	Container.BackgroundColor3       = Color3.fromRGB(60, 0, 0)
	Container.BackgroundTransparency = 1
	Container.Visible = true
	HeartSound.Volume   = cfg.HeartVolume
	EarRingSound.Volume = cfg.EarRingVolume
	HeartSound:Resume()
	EarRingSound:Resume()

	-- this is trash I should prob rewrite it sometime -copy
	local si = math.rad(cfg.ShakeDegrees)
	RunService:BindToRenderStep(SHAKE_KEY, Enum.RenderPriority.Camera.Value + 1, function()
		local t = os.clock()
		workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * CFrame.Angles(
			-- more intense, and harsh shake
			-- math.noise(t * 2.5, 0) * si,
			-- math.noise(0, t * 2.5) * si,
			-- math.noise(t * 2.5, t * 2.5) * si * 0.3

			-- more smooth, less harsh shake
			math.noise(t * 0.4, 0) * si,
			math.noise(0, t * 0.4) * si,
			math.noise(t * 0.4, t * 0.4) * si * 0.3
		)
	end)

	activeConn = RunService.RenderStepped:Connect(function(dt)
		local clock = os.clock()

		-- EarRing fade out currently fades out about half-way through the total duration
		local totalDuration = (cfg.DisplayDuration + cfg.DimExtraDuration) / 2
		EarRingSound.Volume = cfg.EarRingVolume * math.max(0, 1 - (clock - NTime) / totalDuration)

		if clock > DimFadeAfter then
			local dimElapsed = clock - DimFadeAfter
			if dimElapsed > cfg.FadeOutDuration then
				anxietyActive   = false
				anxietyTextDone = false
				if not pmActive then Container.Visible = false end
				Container.BackgroundTransparency = 1
				Vignette.ImageTransparency = 1
				stopShake()
				activeConn:Disconnect()
				activeConn = nil
				local soundFadeInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear)
				heartFadeTween = TweenService:Create(HeartSound, soundFadeInfo, { Volume = 0 })
				heartFadeTween:Play()
				heartFadeTween.Completed:Connect(function()
					HeartSound:Pause()
					HeartSound.Volume = cfg.HeartVolume
					heartFadeTween = nil
				end)
				EarRingSound:Pause()
				EarRingSound.Volume = cfg.EarRingVolume
			else
				local t = dimElapsed / cfg.FadeOutDuration
				Container.BackgroundTransparency = lerp(0.6, 1, t)
				Vignette.ImageTransparency       = lerp(0,   1, t)
			end

		elseif clock > FadeAfter then
			local fadeElapsed = clock - FadeAfter
			if not anxietyTextDone then
				Display.TextTransparency = lerp(0.4, 1, math.min(fadeElapsed, 1))
			end
			Container.BackgroundTransparency = 0.6
			Vignette.ImageTransparency       = 0
			stopShake()

		else
			local alpha = math.min(4 * dt, 1)
			Container.BackgroundTransparency = lerp(Container.BackgroundTransparency, 0.6, alpha)
			Vignette.ImageTransparency       = lerp(Vignette.ImageTransparency, 0, alpha)
			if not anxietyTextDone then
				Display.TextTransparency = lerp(Display.TextTransparency, 0.4, alpha)
			end
		end
	end)
end

-- Observe
local observeTween = nil
local Observe = {
	Font             = Font.new("rbxasset://fonts/families/Montserrat.json"),
	TextSize         = 32,
	TextColor        = Color3.fromRGB(255, 255, 255),
	TextGreen        = Color3.fromRGB(0, 255, 0),
	TextTransparency = 0,
	FadeInDuration   = 0.4,
	FadeOutDuration  = 1.0,
}

local function stopObserve()
	if observeTween then observeTween:Cancel(); observeTween = nil end
	RunService:UnbindFromRenderStep("ObserveCameraStep")
	SharedFramework.PushSharedData("ObserveActive", false)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	local char = game:GetService("Players").LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then workspace.CurrentCamera.CameraSubject = hum end
	end
	
	--remove observing text
	Display.TextTransparency = 1
	Container.Visible = false
end

local function playObserve(playerName, character)
	stopObserve()
	
	--logic to bypass the cameracontroller
	if character then
		local head = character:FindFirstChild("Head")
		SharedFramework.PushSharedData("ObserveActive", true) --sharedframework is so damn cool
		RunService:BindToRenderStep("ObserveCameraStep", Enum.RenderPriority.Camera.Value + 1, function()
			if head and head.Parent then
				workspace.CurrentCamera.CameraSubject = head
			end
		end)
	end
	
	local cfg = Observe
	Display.FontFace         = cfg.Font
	Display.TextSize         = cfg.TextSize
	Display.TextColor3       = cfg.TextColor
	Display.Text             = 'Observing: <font color="rgb(' .. math.round(cfg.TextGreen.R*255) .. ',' .. math.round(cfg.TextGreen.G*255) .. ',' .. math.round(cfg.TextGreen.B*255) .. ')">' .. playerName .. '</font>'
	Display.TextTransparency = 1
	Container.Visible        = true
	
	-- fade in the observe text
	local fadeIn = TweenService:Create(Display, TweenInfo.new(cfg.FadeInDuration), { TextTransparency = cfg.TextTransparency })
	observeTween = fadeIn
	fadeIn:Play()
	fadeIn.Completed:Connect(function() observeTween = nil end)
end

-- Event handler
AdminClientDispatch.OnClientEvent:Connect(function(_type_, ...)
	if _type_ == "plainPM" then
		playNormal((...))
	elseif _type_ == "shakyPM" then
		playShaky((...))
	elseif _type_ == "basicAnxiety" then
		playAnxiety((...))
	elseif _type_ == "observe" then
		local args = {...}
		if args[1] then
			playObserve(args[1], args[2])
		else
			stopObserve()
		end
	end
end)

return {}
