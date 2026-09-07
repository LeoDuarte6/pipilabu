local ShuffleBag = require("../src/shared/DeterministicShuffleBag")
local ReactionSelector = require("../src/server/PeepilabuReactionSelector")

local function assertThrows(callback, expectedFragment)
	local ok, message = pcall(callback)
	assert(not ok, "expected callback to throw")
	assert(string.find(tostring(message), expectedFragment, 1, true), tostring(message))
end

local function assertCycleContainsEveryValue(values, expected)
	local seen = {}
	for _, value in values do
		assert(not seen[value], "shuffle cycle emitted a duplicate")
		seen[value] = true
	end
	for _, value in expected do
		assert(seen[value], string.format("shuffle cycle omitted %s", tostring(value)))
	end
end

local source = { "one", "two", "three" }
local firstBag = ShuffleBag.new(source, 20260807)
local secondBag = ShuffleBag.new(source, 20260807)
local previous = nil

for cycle = 1, 20 do
	local emitted = {}
	for _ = 1, #source do
		local first = firstBag.next()
		local second = secondBag.next()
		assert(first == second, "equal seeds must produce equal sequences")
		assert(first ~= previous, "shuffle bag repeated across an emission boundary")
		previous = first
		table.insert(emitted, first)
	end
	assertCycleContainsEveryValue(emitted, source)
	assert(firstBag.cycle() == cycle, "shuffle bag reported the wrong cycle")
end

assert(firstBag.size() == #source, "shuffle bag reported the wrong size")
assertThrows(function()
	ShuffleBag.new({ "only" }, 1)
end, "at least two")
assertThrows(function()
	ShuffleBag.new({ "same", "same" }, 1)
end, "unique")
assertThrows(function()
	ShuffleBag.new({ "a", "b" }, 0 / 0)
end, "finite")

local playableIds = {
	["baby-peepilabu-01"] = 101,
	["baby-peepilabu-02"] = "202",
	["baby-peepilabu-03"] = "rbxassetid://303",
	["what-the-dog-doing-01"] = "rbxassetid://999",
}

local rightsBlocked = ReactionSelector.new(ShuffleBag, {
	AssetIds = playableIds,
	RightsCleared = false,
	Seed = 42,
})
assert(not rightsBlocked.isEnabled(), "uncleared source audio must remain disabled")
assert(rightsBlocked.nextBabyServeReaction() == nil, "rights-blocked selector must stay silent")

local unavailable = ReactionSelector.new(ShuffleBag, {
	RightsCleared = true,
	Seed = 42,
})
assert(not unavailable.isEnabled(), "missing IDs must keep reactions disabled")
assert(unavailable.nextBabyServeReaction() == nil, "missing IDs must be silent")

local single = ReactionSelector.new(ShuffleBag, {
	AssetIds = { ["baby-peepilabu-01"] = 101 },
	RightsCleared = true,
	Seed = 42,
})
assert(not single.isEnabled(), "one ID cannot satisfy the no-repeat contract")
assert(single.nextBabyServeReaction() == nil, "single-ID selector must stay silent")

assertThrows(function()
	ReactionSelector.new(ShuffleBag, {
		AssetIds = {
			["baby-peepilabu-01"] = "not-an-asset",
			["baby-peepilabu-02"] = 202,
		},
		RightsCleared = true,
	})
end, "invalid reaction asset ID")

local firstSelector = ReactionSelector.new(ShuffleBag, {
	AssetIds = playableIds,
	RightsCleared = true,
	Seed = 7007,
})
local secondSelector = ReactionSelector.new(ShuffleBag, {
	AssetIds = playableIds,
	RightsCleared = true,
	Seed = 7007,
})

assert(firstSelector.isEnabled(), "three rights-cleared baby reactions should enable selection")
assert(firstSelector.eligibleCount() == 3, "player callouts must not enter the serve-reaction pool")

local previousClip = nil
for _cycle = 1, 20 do
	local emitted = {}
	for _ = 1, 3 do
		local first = firstSelector.nextBabyServeReaction()
		local second = secondSelector.nextBabyServeReaction()
		assert(first ~= nil and second ~= nil, "enabled selectors must return reactions")
		assert(first.ClipId == second.ClipId, "reaction selection must be deterministic")
		assert(first.SoundId == second.SoundId, "resolved sound IDs must be deterministic")
		assert(first.PlaybackSpeed == second.PlaybackSpeed, "playback speed must be deterministic")
		assert(first.Role == "baby_serve_reaction", "auto-serve selection returned the wrong role")
		assert(first.ClipId ~= "what-the-dog-doing-01", "player callout leaked into auto serve")
		assert(first.ClipId ~= previousClip, "serve reactions repeated immediately")
		assert(
			first.PlaybackSpeed >= ReactionSelector.MinPlaybackSpeed
				and first.PlaybackSpeed <= ReactionSelector.MaxPlaybackSpeed,
			"playback speed escaped the manifest range"
		)
		previousClip = first.ClipId
		table.insert(emitted, first.ClipId)
	end
	assertCycleContainsEveryValue(emitted, ReactionSelector.BabyServeReactionIds)
end

print("Peepilabu reaction contract passed deterministic shuffle, rights, role, ID, and silence gates")
