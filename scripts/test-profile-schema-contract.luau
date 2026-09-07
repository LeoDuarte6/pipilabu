local ProfileSchema = require("../src/shared/ProfileSchema")

local function deepEqual(left, right)
	if type(left) ~= type(right) then
		return false
	end
	if type(left) ~= "table" then
		return left == right
	end
	for key, value in left do
		if not deepEqual(value, right[key]) then
			return false
		end
	end
	for key in right do
		if left[key] == nil then
			return false
		end
	end
	return true
end

local fresh = ProfileSchema.newProfile()
assert(fresh.SchemaVersion == ProfileSchema.CurrentVersion, "new profile must use current schema")
assert(fresh.Coins == 0 and fresh.DiscoveredAppleTypes[1] == "Ruby", "new profile must have conservative defaults")
assert(ProfileSchema.validate(fresh), "new profile must validate")

local validLoad = ProfileSchema.migrate({
	SchemaVersion = 1,
	Coins = 18,
	ShopUpgrades = { Counter = 2 },
	DiscoveredAppleTypes = { "Ruby", "Honeygold" },
	Tutorial = {
		FirstAppleTaken = true,
		FirstServeCompleted = true,
		ColorMatchIntroduced = false,
	},
	IgnoredFutureField = "ignored",
})
assert(not validLoad.Recovered and validLoad.Profile.Coins == 18, "valid current profile must load without recovery")
assert(validLoad.Profile.IgnoredFutureField == nil, "unknown top-level fields must not enter canonical profile")

local migrated = ProfileSchema.migrate({
	Coins = 7,
	Upgrades = { Counter = 1 },
	Apples = { "Honeygold" },
	TutorialFlags = { FirstAppleTaken = true },
})
assert(migrated.Recovered and migrated.Reason == "MigratedFromV0", "unversioned profile must use explicit v0 migration")
assert(migrated.Profile.ShopUpgrades.Counter == 1, "v0 upgrades must migrate")
assert(migrated.Profile.DiscoveredAppleTypes[1] == "Honeygold" and migrated.Profile.DiscoveredAppleTypes[2] == "Ruby", "migration must retain known apples and guarantee Ruby")
assert(migrated.Profile.Tutorial.FirstAppleTaken, "v0 tutorial flags must migrate")

local malformed = ProfileSchema.migrate("corrupt")
assert(malformed.Recovered and malformed.Reason == "MalformedProfile", "malformed profile must fail into safe recovery")
assert(deepEqual(malformed.Profile, ProfileSchema.newProfile()), "malformed recovery must use a clean profile")

local partiallyCorrupt = ProfileSchema.migrate({
	SchemaVersion = 1,
	Coins = -50,
	ShopUpgrades = { Counter = 2, Broken = -1 },
	DiscoveredAppleTypes = { "Ruby", "Ruby", 4 },
	Tutorial = { FirstAppleTaken = "yes" },
})
assert(partiallyCorrupt.Recovered and partiallyCorrupt.Profile.Coins == 0, "invalid fields must recover conservatively")
assert(partiallyCorrupt.Profile.ShopUpgrades.Counter == 2 and partiallyCorrupt.Profile.ShopUpgrades.Broken == nil, "valid subfields may survive bounded recovery")

local future = ProfileSchema.migrate({ SchemaVersion = 99 })
assert(future.Recovered and future.Reason == "UnsupportedFutureVersion", "future versions must fail closed")

local firstPass = ProfileSchema.migrate(validLoad.Profile)
local secondPass = ProfileSchema.migrate(firstPass.Profile)
assert(not firstPass.Recovered and not secondPass.Recovered, "current canonical profile migration must be idempotent")
assert(deepEqual(firstPass.Profile, secondPass.Profile), "idempotent migration must preserve exact canonical data")

local invalidOk, invalidReason = ProfileSchema.validate({
	SchemaVersion = 1,
	Coins = 0.5,
	ShopUpgrades = {},
	DiscoveredAppleTypes = { "Ruby" },
	Tutorial = {},
})
assert(not invalidOk and invalidReason == "InvalidCoins", "validation must reject fractional currency")

local missingTutorialOk, missingTutorialReason = ProfileSchema.validate({
	SchemaVersion = 1,
	Coins = 0,
	ShopUpgrades = {},
	DiscoveredAppleTypes = { "Ruby" },
	Tutorial = {},
})
assert(not missingTutorialOk and missingTutorialReason == "InvalidTutorial", "canonical validation must require every tutorial boolean")

print("Pipi Labu profile schema contract passed defaults, load, migration, corruption, future-version, and idempotence cases")
