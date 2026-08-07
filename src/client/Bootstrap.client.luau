local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Config = require(projectRoot:WaitForChild("Config"))

print(string.format("[JonAndLeo] client online - %s v%s", Config.ProjectName, Config.DevelopmentVersion))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("DogeAppleHUD")
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DogeAppleHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.fromScale(0.5, 0.035)
panel.Size = UDim2.fromOffset(440, 116)
panel.BackgroundColor3 = Color3.fromRGB(44, 35, 27)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(245, 195, 82)
stroke.Thickness = 2
stroke.Transparency = 0.25
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 12)
title.Size = UDim2.new(1, -40, 0, 30)
title.Font = Enum.Font.GothamBold
title.Text = "GOOD FRUIT"
title.TextColor3 = Color3.fromRGB(255, 218, 105)
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local progress = Instance.new("TextLabel")
progress.Name = "Progress"
progress.BackgroundTransparency = 1
progress.Position = UDim2.fromOffset(20, 43)
progress.Size = UDim2.new(1, -40, 0, 25)
progress.Font = Enum.Font.GothamSemibold
progress.TextColor3 = Color3.fromRGB(247, 239, 221)
progress.TextSize = 17
progress.TextXAlignment = Enum.TextXAlignment.Left
progress.Parent = panel

local instruction = Instance.new("TextLabel")
instruction.Name = "Instruction"
instruction.BackgroundTransparency = 1
instruction.Position = UDim2.fromOffset(20, 72)
instruction.Size = UDim2.new(1, -40, 0, 28)
instruction.Font = Enum.Font.Gotham
instruction.TextColor3 = Color3.fromRGB(224, 208, 178)
instruction.TextSize = 16
instruction.TextWrapped = true
instruction.TextXAlignment = Enum.TextXAlignment.Left
instruction.Parent = panel

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
	title.Text = if hasApple then "GOOD FRUIT  |  APPLE IN PAW" else "GOOD FRUIT"
end

local function pulse()
	local brighten = TweenService:Create(stroke, TweenInfo.new(0.12), {
		Color = Color3.fromRGB(122, 230, 127),
		Thickness = 4,
	})
	local settle = TweenService:Create(stroke, TweenInfo.new(0.45), {
		Color = Color3.fromRGB(245, 195, 82),
		Thickness = 2,
	})
	brighten.Completed:Once(function()
		settle:Play()
	end)
	brighten:Play()
end

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
	end)
	render()
end)

render()
