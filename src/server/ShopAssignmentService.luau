--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local ShopAssignment = require(projectRoot:WaitForChild("ShopAssignment"))

local ASSIGNMENT_ATTRIBUTE = "PipiLabuShopBay"

local ShopAssignmentService = {}

local started = false
local enabled = false
local registry = nil :: ShopAssignment.Registry?
local connections: { RBXScriptConnection } = {}

local function clearAssignment(player: Player)
	player:SetAttribute(ASSIGNMENT_ATTRIBUTE, nil)
end

local function assignPlayer(player: Player)
	local currentRegistry = registry
	if not currentRegistry then
		clearAssignment(player)
		return
	end

	local result = currentRegistry.assign(player.UserId)
	if result.Accepted and result.Assignment then
		player:SetAttribute(ASSIGNMENT_ATTRIBUTE, result.Assignment.BayId)
	else
		clearAssignment(player)
		warn(string.format("[PipiLabuShops] assignment rejected for %d: %s", player.UserId, result.Reason or "Unknown"))
	end
end

local function releasePlayer(player: Player)
	local currentRegistry = registry
	if currentRegistry then
		currentRegistry.release(player.UserId)
	end
	clearAssignment(player)
end

function ShopAssignmentService.Start(config)
	if started then
		return {
			Enabled = enabled,
			Code = if enabled then "AlreadyStarted" else "Disabled",
		}
	end
	started = true

	if type(config) ~= "table" or config.Enabled ~= true then
		return {
			Enabled = false,
			Code = "Disabled",
		}
	end

	registry = ShopAssignment.newRegistry(config.BayIds)
	enabled = true

	table.insert(connections, Players.PlayerAdded:Connect(assignPlayer))
	table.insert(connections, Players.PlayerRemoving:Connect(releasePlayer))
	for _, player in Players:GetPlayers() do
		assignPlayer(player)
	end

	return {
		Enabled = true,
		Code = "Started",
	}
end

function ShopAssignmentService.GetAssignment(player: Player): ShopAssignment.Assignment?
	local currentRegistry = registry
	return if currentRegistry then currentRegistry.get(player.UserId) else nil
end

function ShopAssignmentService.Snapshot(): { ShopAssignment.Assignment }
	local currentRegistry = registry
	return if currentRegistry then currentRegistry.snapshot() else {}
end

function ShopAssignmentService.Stop()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)

	for _, player in Players:GetPlayers() do
		clearAssignment(player)
	end

	registry = nil
	enabled = false
	started = false
end

return ShopAssignmentService
