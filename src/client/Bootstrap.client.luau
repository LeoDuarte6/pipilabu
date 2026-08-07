local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local HapticService = game:GetService("HapticService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Config = require(projectRoot:WaitForChild("Config"))

print(string.format("[JonAndLeo] client online - %s v%s", Config.ProjectName, Config.DevelopmentVersion))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
player.CameraMode = Enum.CameraMode.Classic
player.CameraMinZoomDistance = Config.Camera.MinimumZoom
player.CameraMaxZoomDistance = Config.Camera.MaximumZoom

local function applyCameraDefaults()
	local camera = Workspace.CurrentCamera
	if camera then
		camera.FieldOfView = Config.Camera.FieldOfView
	end
end

applyCameraDefaults()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(applyCameraDefaults)

local feedbackEvent = projectRoot:WaitForChild("ShopFeedback") :: RemoteEvent

local existing = playerGui:FindFirstChild("DogeAppleHUD")
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DogeAppleHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromOffset(22, 18)
panel.Size = UDim2.fromOffset(380, 100)
panel.BackgroundColor3 = Color3.fromRGB(36, 33, 30)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(135, 76, 63)
stroke.Thickness = 1.5
stroke.Transparency = 0.25
stroke.Parent = panel

local panelScale = Instance.new("UIScale")
panelScale.Name = "FeedbackScale"
panelScale.Scale = 1
panelScale.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 12)
title.Size = UDim2.new(1, -40, 0, 30)
title.Font = Enum.Font.GothamBold
title.Text = "GOOD FRUIT"
title.TextColor3 = Color3.fromRGB(245, 235, 215)
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local progress = Instance.new("TextLabel")
progress.Name = "Progress"
progress.BackgroundTransparency = 1
progress.Position = UDim2.fromOffset(20, 43)
progress.Size = UDim2.new(1, -40, 0, 25)
progress.Font = Enum.Font.GothamSemibold
progress.TextColor3 = Color3.fromRGB(236, 232, 223)
progress.TextSize = 17
progress.TextXAlignment = Enum.TextXAlignment.Left
progress.Parent = panel

local instruction = Instance.new("TextLabel")
instruction.Name = "Instruction"
instruction.BackgroundTransparency = 1
instruction.Position = UDim2.fromOffset(20, 69)
instruction.Size = UDim2.new(1, -40, 0, 24)
instruction.Font = Enum.Font.Gotham
instruction.TextColor3 = Color3.fromRGB(204, 196, 183)
instruction.TextSize = 16
instruction.TextWrapped = true
instruction.TextXAlignment = Enum.TextXAlignment.Left
instruction.Parent = panel

local celebration = Instance.new("TextLabel")
celebration.Name = "Celebration"
celebration.AnchorPoint = Vector2.new(0.5, 0.5)
celebration.BackgroundTransparency = 1
celebration.Font = Enum.Font.GothamBlack
celebration.Position = UDim2.fromScale(0.5, 0.64)
celebration.Size = UDim2.fromOffset(520, 100)
celebration.Text = "GOOD FRUIT!"
celebration.TextColor3 = Color3.fromRGB(250, 242, 224)
celebration.TextScaled = true
celebration.TextStrokeColor3 = Color3.fromRGB(55, 31, 20)
celebration.TextStrokeTransparency = 1
celebration.TextTransparency = 1
celebration.Parent = screenGui

local pickupSound = Instance.new("Sound")
pickupSound.Name = "PickupFeedback"
pickupSound.SoundId = Config.Audio.PickupSoundId
pickupSound.Volume = 0.32
pickupSound.PlaybackSpeed = 1.08

local serveSound = Instance.new("Sound")
serveSound.Name = "ServeFeedback"
serveSound.SoundId = Config.Audio.ServeSoundId
serveSound.Volume = 0.42
serveSound.PlaybackSpeed = 1.04

local function getStat(name: string): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local value = leaderstats and leaderstats:FindFirstChild(name)
	return if value and value:IsA("IntValue") then value else nil
end

local function render()
	local coins = getStat("Coins")
	local served = getStat("Served")
	local queueSize = player:GetAttribute("QueueSize") or 0
	local hasApple = player:GetAttribute("HasApple") == true

	progress.Text = string.format("Coins  %d     Served  %d     Waiting  %d", coins and coins.Value or 0, served and served.Value or 0, queueSize)
	instruction.Text = tostring(player:GetAttribute("ShopMessage") or if hasApple then "Serve the front Doge" else "Take one apple from the crate")
	title.Text = if hasApple then "GOOD FRUIT  •  APPLE READY" else "GOOD FRUIT"
	title.TextColor3 = if hasApple then Color3.fromRGB(255, 206, 191) else Color3.fromRGB(245, 235, 215)
	stroke.Color = if hasApple then Color3.fromRGB(202, 72, 59) else Color3.fromRGB(135, 76, 63)
end

local function pulse()
	local brighten = TweenService:Create(stroke, TweenInfo.new(0.12), {
		Color = Color3.fromRGB(122, 230, 127),
		Thickness = 4,
	})
	local settle = TweenService:Create(stroke, TweenInfo.new(0.45), {
		Color = if player:GetAttribute("HasApple") == true then Color3.fromRGB(202, 72, 59) else Color3.fromRGB(135, 76, 63),
		Thickness = 1.5,
	})
	brighten.Completed:Once(function()
		settle:Play()
	end)
	brighten:Play()
end

local function confirmWithController()
	local gamepad = Enum.UserInputType.Gamepad1
	local motor = Enum.VibrationMotor.Small
	if not HapticService:IsVibrationSupported(gamepad) or not HapticService:IsMotorSupported(gamepad, motor) then
		return
	end

	HapticService:SetMotor(gamepad, motor, 0.55)
	task.delay(0.09, function()
		HapticService:SetMotor(gamepad, motor, 0)
	end)
end

local function playOneShot(template: Sound)
	local sound = template:Clone()
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 4)
end

local function bumpPanel(amount: number)
	panelScale.Scale = 1
	local expand = TweenService:Create(panelScale, TweenInfo.new(0.09, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = amount,
	})
	local settle = TweenService:Create(panelScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = 1,
	})
	expand.Completed:Once(function()
		settle:Play()
	end)
	expand:Play()
end

local function celebrateServe()
	celebration.Position = UDim2.fromScale(0.5, 0.66)
	celebration.TextTransparency = 0
	celebration.TextStrokeTransparency = 0.18
	local rise = TweenService:Create(celebration, TweenInfo.new(0.62, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.56),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	rise:Play()
end

feedbackEvent.OnClientEvent:Connect(function(action: string)
	if action == "Pickup" then
		playOneShot(pickupSound)
		bumpPanel(1.025)
	elseif action == "Serve" then
		playOneShot(serveSound)
		bumpPanel(1.055)
		celebrateServe()
	end
end)

player:GetAttributeChangedSignal("HasApple"):Connect(render)
player:GetAttributeChangedSignal("ShopMessage"):Connect(render)
player:GetAttributeChangedSignal("QueueSize"):Connect(render)

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats")
	local coins = leaderstats:WaitForChild("Coins") :: IntValue
	local served = leaderstats:WaitForChild("Served") :: IntValue
	coins.Changed:Connect(render)
	served.Changed:Connect(function()
		render()
		pulse()
		confirmWithController()
	end)
	render()
end)

render()
