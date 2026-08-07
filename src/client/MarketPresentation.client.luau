--!strict

-- This layer is intentionally silent unless the local market-village
-- prototype is present. Gate A's existing shop HUD is therefore unchanged.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Copy = require(projectRoot:WaitForChild("Copy"))
local MarketVillage = require(projectRoot:WaitForChild("MarketVillage"))
local Presentation = require(projectRoot:WaitForChild("Presentation"))
local Stewardship = require(projectRoot:WaitForChild("Stewardship"))

local village = Workspace:FindFirstChild(MarketVillage.RootName)
if not village or not village:IsA("Folder") or village:GetAttribute(MarketVillage.PresentationEnabledAttribute) ~= true then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("MarketVillagePresentation")
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MarketVillagePresentation"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "CareCard"
card.Position = UDim2.fromOffset(Presentation.Ui.HudLeft, Presentation.Ui.HudTop)
card.Size = UDim2.fromOffset(380, 52)
card.BackgroundColor3 = Presentation.Palette.Ink
card.BackgroundTransparency = 0.08
card.BorderSizePixel = 0
card.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = Presentation.Ui.CardCornerRadius
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = Presentation.Palette.CareSoft
stroke.Thickness = Presentation.Ui.CardStrokeThickness
stroke.Transparency = 0.18
stroke.Parent = card

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(16, 7)
title.Size = UDim2.fromOffset(112, 18)
title.Font = Enum.Font.GothamBold
title.Text = Copy.Village.CareTitle
title.TextColor3 = Presentation.Palette.CareSoft
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local progress = Instance.new("TextLabel")
progress.Name = "Progress"
progress.BackgroundTransparency = 1
progress.Position = UDim2.fromOffset(130, 7)
progress.Size = UDim2.new(1, -146, 0, 18)
progress.Font = Enum.Font.GothamSemibold
progress.TextColor3 = Presentation.Palette.Paper
progress.TextSize = 13
progress.TextXAlignment = Enum.TextXAlignment.Right
progress.Parent = card

local message = Instance.new("TextLabel")
message.Name = "Message"
message.BackgroundTransparency = 1
message.Position = UDim2.fromOffset(16, 27)
message.Size = UDim2.new(1, -32, 0, 18)
message.Font = Enum.Font.Gotham
message.TextColor3 = Presentation.Palette.Paper
message.TextSize = 12
message.TextXAlignment = Enum.TextXAlignment.Left
message.TextTruncate = Enum.TextTruncate.AtEnd
message.Parent = card

local function getGoodwill(): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local goodwill = leaderstats and leaderstats:FindFirstChild("Goodwill")
	return if goodwill and goodwill:IsA("IntValue") then goodwill else nil
end

local function render()
	local goodwill = getGoodwill()
	local careMarks = player:GetAttribute("CareMarks") or 0
	local stage = tostring(player:GetAttribute("StewardshipStage") or "OPEN HANDS")
	progress.Text = string.format(Copy.Village.CareProgress, careMarks, Stewardship.MaxCareMarks, stage)
	message.Text = tostring(player:GetAttribute("StewardshipMessage") or Copy.Village.OpenHands)
	card.BackgroundColor3 = if goodwill and goodwill.Value > 0 then Presentation.Palette.WoodDark else Presentation.Palette.Ink
end

player:GetAttributeChangedSignal("CareMarks"):Connect(render)
player:GetAttributeChangedSignal("StewardshipStage"):Connect(render)
player:GetAttributeChangedSignal("StewardshipMessage"):Connect(render)

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats")
	local goodwill = leaderstats:WaitForChild("Goodwill", 10)
	if goodwill and goodwill:IsA("IntValue") then
		goodwill.Changed:Connect(render)
	end
	render()
end)

render()
