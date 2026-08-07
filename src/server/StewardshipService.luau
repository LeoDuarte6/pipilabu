--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Copy = require(projectRoot:WaitForChild("Copy"))
local MarketVillage = require(projectRoot:WaitForChild("MarketVillage"))
local Presentation = require(projectRoot:WaitForChild("Presentation"))
local Stewardship = require(projectRoot:WaitForChild("Stewardship"))

local StewardshipService = {}

local started = false
local village: Folder
local servedConnections: { [Player]: RBXScriptConnection } = {}

local function getOrCreateIntValue(parent: Instance, name: string): IntValue
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("IntValue") then
		return existing
	end

	local value = Instance.new("IntValue")
	value.Name = name
	value.Parent = parent
	return value
end

local function messageForStage(stageId: string): string
	if stageId == "WarmWelcome" then
		return Copy.Village.WarmWelcome
	elseif stageId == "GrowingLane" then
		return Copy.Village.GrowingLane
	elseif stageId == "GoodCareTravels" then
		return Copy.Village.GoodCareTravels
	end
	return Copy.Village.OpenHands
end

local function renderDisplay(evaluation: Stewardship.Evaluation)
	village:SetAttribute("LastServed", evaluation.Served)
	village:SetAttribute("CareMarks", evaluation.CareMarks)
	village:SetAttribute("StewardshipStage", evaluation.StageId)

	local display = village:FindFirstChild(MarketVillage.StewardshipDisplayName)
	if not display then
		return
	end

	local markers = display:FindFirstChild(MarketVillage.CareMarkersName)
	if markers then
		for index = 1, MarketVillage.CareMarkerCount do
			local marker = markers:FindFirstChild(string.format("%s%02d", MarketVillage.CareMarkerPrefix, index))
			if marker and marker:IsA("BasePart") then
				local active = index <= evaluation.CareMarks
				marker.Color = if active then Presentation.Palette.CareGreen else Presentation.Palette.Paper
				marker.Material = if active then Enum.Material.Neon else Enum.Material.SmoothPlastic
				marker.Transparency = if active then 0 else 0.48

				local glow = marker:FindFirstChild("CareGlow")
				if glow and glow:IsA("PointLight") then
					glow.Enabled = active
				end
			end
		end
	end

	local message = display:FindFirstChild("Message", true)
	if message and message:IsA("TextLabel") then
		message.Text = messageForStage(evaluation.StageId)
	end

	local count = display:FindFirstChild("Count", true)
	if count and count:IsA("TextLabel") then
		count.Text = string.format("%d / %d", evaluation.CareMarks, Stewardship.MaxCareMarks)
	end
end

local function refreshPlayer(player: Player, served: IntValue, goodwill: IntValue)
	local evaluation = Stewardship.evaluate(served.Value)
	goodwill.Value = evaluation.Goodwill
	player:SetAttribute("Goodwill", evaluation.Goodwill)
	player:SetAttribute("CareMarks", evaluation.CareMarks)
	player:SetAttribute("StewardshipStage", evaluation.StageName)
	player:SetAttribute("StewardshipMessage", messageForStage(evaluation.StageId))
	renderDisplay(evaluation)
end

local function bindPlayer(player: Player)
	if servedConnections[player] then
		return
	end

	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		warn(string.format("[JonAndLeo] stewardship skipped %s: leaderstats unavailable", player.Name))
		return
	end

	local served = leaderstats:FindFirstChild("Served")
	if not served or not served:IsA("IntValue") then
		warn(string.format("[JonAndLeo] stewardship skipped %s: Served stat unavailable", player.Name))
		return
	end

	local goodwill = getOrCreateIntValue(leaderstats, "Goodwill")
	servedConnections[player] = served.Changed:Connect(function()
		refreshPlayer(player, served :: IntValue, goodwill)
	end)
	refreshPlayer(player, served, goodwill)
end

function StewardshipService.Start()
	if started then
		return
	end

	local existing = Workspace:FindFirstChild(MarketVillage.RootName)
	if not existing or not existing:IsA("Folder") then
		print(string.format("[JonAndLeo] stewardship prototype disabled: %s not present", MarketVillage.RootName))
		return
	end

	village = existing
	if village:GetAttribute(MarketVillage.PresentationEnabledAttribute) ~= true then
		print("[JonAndLeo] stewardship prototype disabled: presentation flag is false")
		return
	end

	started = true
	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		local connection = servedConnections[player]
		if connection then
			connection:Disconnect()
			servedConnections[player] = nil
		end
	end)

	for _, player in Players:GetPlayers() do
		bindPlayer(player)
	end

	print(string.format("[JonAndLeo] stewardship prototype ready: %s", MarketVillage.Build))
end

return StewardshipService
