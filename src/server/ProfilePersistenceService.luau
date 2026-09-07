--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local ProfileSchema = require(projectRoot:WaitForChild("ProfileSchema"))

local STATE_ATTRIBUTE = "PipiLabuProfileState"

local ProfilePersistenceService = {}

local started = false
local enabled = false
local store = nil
local keyPrefix = "player:"
local profiles: { [number]: ProfileSchema.Profile } = {}
local loadNonce: { [number]: number } = {}
local connections: { RBXScriptConnection } = {}

local function copyProfile(profile: ProfileSchema.Profile): ProfileSchema.Profile
	return ProfileSchema.migrate(profile).Profile
end

local function profileKey(userId: number): string
	return keyPrefix .. tostring(userId)
end

local function nextNonce(userId: number): number
	local value = (loadNonce[userId] or 0) + 1
	loadNonce[userId] = value
	return value
end

local function loadPlayer(player: Player)
	local currentStore = store
	if not enabled or not currentStore then
		return
	end

	local userId = player.UserId
	local nonce = nextNonce(userId)
	player:SetAttribute(STATE_ATTRIBUTE, "Loading")

	local ok, raw = pcall(function()
		return currentStore:GetAsync(profileKey(userId))
	end)
	if loadNonce[userId] ~= nonce or player.Parent ~= Players then
		return
	end
	if not ok then
		player:SetAttribute(STATE_ATTRIBUTE, "LoadFailed")
		warn(string.format("[PipiLabuProfiles] load failed for %d", userId))
		return
	end

	local migration = ProfileSchema.migrate(raw)
	if migration.Reason == "UnsupportedFutureVersion" then
		player:SetAttribute(STATE_ATTRIBUTE, "LoadRejected")
		warn(string.format("[PipiLabuProfiles] future profile rejected for %d", userId))
		return
	end

	profiles[userId] = migration.Profile
	player:SetAttribute(STATE_ATTRIBUTE, if migration.Recovered then "ReadyRecovered" else "Ready")
end

local function saveUserId(userId: number): boolean
	local currentStore = store
	local profile = profiles[userId]
	if not enabled or not currentStore or not profile then
		return false
	end

	local valid = ProfileSchema.validate(profile)
	if not valid then
		warn(string.format("[PipiLabuProfiles] refused invalid profile for %d", userId))
		return false
	end

	local snapshot = copyProfile(profile)
	local ok = pcall(function()
		currentStore:UpdateAsync(profileKey(userId), function()
			return snapshot
		end)
	end)
	if not ok then
		warn(string.format("[PipiLabuProfiles] save failed for %d", userId))
	end
	return ok
end

local function releasePlayer(player: Player)
	local userId = player.UserId
	nextNonce(userId)
	saveUserId(userId)
	profiles[userId] = nil
	player:SetAttribute(STATE_ATTRIBUTE, nil)
end

function ProfilePersistenceService.Start(config)
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
	assert(type(config.StoreName) == "string" and config.StoreName ~= "", "profile store name is required")
	assert(type(config.KeyPrefix) == "string" and config.KeyPrefix ~= "", "profile key prefix is required")

	keyPrefix = config.KeyPrefix
	store = DataStoreService:GetDataStore(config.StoreName)
	enabled = true

	table.insert(connections, Players.PlayerAdded:Connect(loadPlayer))
	table.insert(connections, Players.PlayerRemoving:Connect(releasePlayer))
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	game:BindToClose(function()
		if not enabled then
			return
		end
		for userId in profiles do
			saveUserId(userId)
		end
	end)

	return {
		Enabled = true,
		Code = "Started",
	}
end

function ProfilePersistenceService.GetProfile(player: Player): ProfileSchema.Profile?
	local profile = profiles[player.UserId]
	return if profile then copyProfile(profile) else nil
end

function ProfilePersistenceService.SetProfile(player: Player, profile: ProfileSchema.Profile): (boolean, string?)
	if not enabled or profiles[player.UserId] == nil then
		return false, "ProfileNotReady"
	end
	local valid, reason = ProfileSchema.validate(profile)
	if not valid then
		return false, reason
	end
	profiles[player.UserId] = copyProfile(profile)
	return true
end

function ProfilePersistenceService.Stop()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)

	if enabled then
		for userId in profiles do
			saveUserId(userId)
		end
	end
	table.clear(profiles)
	table.clear(loadNonce)
	store = nil
	enabled = false
	started = false
end

return ProfilePersistenceService
