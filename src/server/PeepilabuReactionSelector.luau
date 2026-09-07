--!strict

-- Pure server-facing selection policy. This module creates no Sound instances,
-- performs no uploads, and emits nothing when rights or playable assets are
-- unavailable. The caller injects a shuffle-bag module and rights-cleared IDs.

export type ReactionRole = "baby_serve_reaction" | "player_callout"
export type AssetId = number | string

export type ShuffleBag<T> = {
	next: () -> T,
	cycle: () -> number,
	size: () -> number,
}

export type ShuffleBagFactory = {
	new: <T>(items: { T }, seed: number?) -> ShuffleBag<T>,
}

export type Options = {
	AssetIds: { [string]: AssetId }?,
	RightsCleared: boolean?,
	Seed: number?,
}

export type Selection = {
	ClipId: string,
	Role: "baby_serve_reaction",
	SoundId: string,
	PlaybackSpeed: number,
}

export type Selector = {
	nextBabyServeReaction: () -> Selection?,
	isEnabled: () -> boolean,
	eligibleCount: () -> number,
}

type EligibleReaction = {
	ClipId: string,
	SoundId: string,
}

local BABY_SERVE_REACTION_IDS = table.freeze({
	"baby-peepilabu-01",
	"baby-peepilabu-02",
	"baby-peepilabu-03",
})

local PLAYER_CALLOUT_IDS = table.freeze({
	"what-the-dog-doing-01",
	"what-the-dog-doing-02",
})

local PLAYBACK_SPEEDS = table.freeze({ 0.97, 0.99, 1.01, 1.03, 1.05 })
local DEFAULT_SEED = 8675309
local SPEED_SEED_OFFSET = 7919

local function normalizeAssetId(value: AssetId?): string?
	if value == nil or value == "" or value == 0 then
		return nil
	end

	if type(value) == "number" then
		assert(
			value == value and value ~= math.huge and value ~= -math.huge and value > 0 and value == math.floor(value),
			"reaction asset IDs must be positive integers"
		)
		return string.format("rbxassetid://%.0f", value)
	end

	local digits = string.match(value, "^rbxassetid://(%d+)$") or string.match(value, "^(%d+)$")
	assert(digits ~= nil and tonumber(digits) ~= nil and (tonumber(digits) :: number) > 0, "invalid reaction asset ID")
	return "rbxassetid://" .. digits
end

local function disabledSelector(): Selector
	return table.freeze({
		nextBabyServeReaction = function(): Selection?
			return nil
		end,
		isEnabled = function(): boolean
			return false
		end,
		eligibleCount = function(): number
			return 0
		end,
	})
end

local function new(shuffleBagFactory: ShuffleBagFactory, options: Options?): Selector
	local resolvedOptions = options or {}
	if resolvedOptions.RightsCleared ~= true then
		return disabledSelector()
	end

	local configuredIds = resolvedOptions.AssetIds or {}
	local eligible: { EligibleReaction } = {}
	for _, clipId in BABY_SERVE_REACTION_IDS do
		local soundId = normalizeAssetId(configuredIds[clipId])
		if soundId ~= nil then
			table.insert(eligible, table.freeze({
				ClipId = clipId,
				SoundId = soundId,
			}))
		end
	end

	-- One playable reaction cannot satisfy the no-immediate-repeat contract.
	-- Stay silent until at least two rights-cleared assets are available.
	if #eligible < 2 then
		return disabledSelector()
	end

	local seed = resolvedOptions.Seed or DEFAULT_SEED
	local reactionBag = shuffleBagFactory.new(eligible, seed)
	local speedBag = shuffleBagFactory.new(table.clone(PLAYBACK_SPEEDS), seed + SPEED_SEED_OFFSET)

	return table.freeze({
		nextBabyServeReaction = function(): Selection
			local reaction = reactionBag.next()
			return table.freeze({
				ClipId = reaction.ClipId,
				Role = "baby_serve_reaction",
				SoundId = reaction.SoundId,
				PlaybackSpeed = speedBag.next(),
			})
		end,
		isEnabled = function(): boolean
			return true
		end,
		eligibleCount = function(): number
			return #eligible
		end,
	})
end

return table.freeze({
	BabyServeReactionIds = BABY_SERVE_REACTION_IDS,
	PlayerCalloutIds = PLAYER_CALLOUT_IDS,
	MinPlaybackSpeed = PLAYBACK_SPEEDS[1],
	MaxPlaybackSpeed = PLAYBACK_SPEEDS[#PLAYBACK_SPEEDS],
	new = new,
})
