--!strict

local CURRENT_VERSION = 1

export type TutorialState = {
	FirstAppleTaken: boolean,
	FirstServeCompleted: boolean,
	ColorMatchIntroduced: boolean,
}

export type Profile = {
	SchemaVersion: number,
	Coins: number,
	ShopUpgrades: { [string]: number },
	DiscoveredAppleTypes: { string },
	Tutorial: TutorialState,
}

export type MigrationResult = {
	Profile: Profile,
	Recovered: boolean,
	Reason: string?,
}

local ProfileSchema = {
	CurrentVersion = CURRENT_VERSION,
}

local function isNonNegativeInteger(value: any): boolean
	return type(value) == "number" and value == value and value < math.huge and value >= 0 and value % 1 == 0
end

local function copyUpgrades(raw: any): ({ [string]: number }, boolean)
	local result = {}
	local recovered = false
	if raw == nil then
		return result, false
	end
	if type(raw) ~= "table" then
		return result, true
	end
	for key, value in raw do
		if type(key) == "string" and key ~= "" and isNonNegativeInteger(value) then
			result[key] = value
		else
			recovered = true
		end
	end
	return result, recovered
end

local function copyAppleTypes(raw: any): ({ string }, boolean)
	local seen = {}
	local result = {}
	local recovered = false
	if raw == nil then
		return { "Ruby" }, false
	end
	if type(raw) ~= "table" then
		return { "Ruby" }, true
	end
	for _, appleType in raw do
		if type(appleType) == "string" and appleType ~= "" and not seen[appleType] then
			seen[appleType] = true
			table.insert(result, appleType)
		else
			recovered = true
		end
	end
	if not seen.Ruby then
		table.insert(result, "Ruby")
		recovered = true
	end
	table.sort(result)
	return result, recovered
end

local function copyTutorial(raw: any): (TutorialState, boolean)
	local result = {
		FirstAppleTaken = false,
		FirstServeCompleted = false,
		ColorMatchIntroduced = false,
	}
	if raw == nil then
		return result, false
	end
	if type(raw) ~= "table" then
		return result, true
	end
	local recovered = false
	for key in result do
		local value = raw[key]
		if value == nil then
			continue
		elseif type(value) == "boolean" then
			result[key] = value
		else
			recovered = true
		end
	end
	return result, recovered
end

function ProfileSchema.newProfile(): Profile
	return {
		SchemaVersion = CURRENT_VERSION,
		Coins = 0,
		ShopUpgrades = {},
		DiscoveredAppleTypes = { "Ruby" },
		Tutorial = {
			FirstAppleTaken = false,
			FirstServeCompleted = false,
			ColorMatchIntroduced = false,
		},
	}
end

function ProfileSchema.migrate(raw: any): MigrationResult
	if type(raw) ~= "table" then
		return {
			Profile = ProfileSchema.newProfile(),
			Recovered = true,
			Reason = "MalformedProfile",
		}
	end

	local sourceVersion = raw.SchemaVersion
	if sourceVersion == nil then
		sourceVersion = 0
	end
	if not isNonNegativeInteger(sourceVersion) then
		return {
			Profile = ProfileSchema.newProfile(),
			Recovered = true,
			Reason = "InvalidSchemaVersion",
		}
	end
	if sourceVersion > CURRENT_VERSION then
		return {
			Profile = ProfileSchema.newProfile(),
			Recovered = true,
			Reason = "UnsupportedFutureVersion",
		}
	end

	local recovered = false
	local coins = raw.Coins
	if not isNonNegativeInteger(coins) then
		coins = 0
		recovered = true
	end

	local upgradeSource = if sourceVersion == 0 and raw.ShopUpgrades == nil then raw.Upgrades else raw.ShopUpgrades
	local appleSource = if sourceVersion == 0 and raw.DiscoveredAppleTypes == nil then raw.Apples else raw.DiscoveredAppleTypes
	local tutorialSource = if sourceVersion == 0 and raw.Tutorial == nil then raw.TutorialFlags else raw.Tutorial
	local upgrades, upgradesRecovered = copyUpgrades(upgradeSource)
	local apples, applesRecovered = copyAppleTypes(appleSource)
	local tutorial, tutorialRecovered = copyTutorial(tutorialSource)
	recovered = recovered or upgradesRecovered or applesRecovered or tutorialRecovered or sourceVersion ~= CURRENT_VERSION

	return {
		Profile = {
			SchemaVersion = CURRENT_VERSION,
			Coins = coins,
			ShopUpgrades = upgrades,
			DiscoveredAppleTypes = apples,
			Tutorial = tutorial,
		},
		Recovered = recovered,
		Reason = if sourceVersion == 0 then "MigratedFromV0" else nil,
	}
end

function ProfileSchema.validate(profile: any): (boolean, string?)
	if type(profile) ~= "table" then
		return false, "ProfileNotTable"
	end
	if profile.SchemaVersion ~= CURRENT_VERSION then
		return false, "SchemaVersionMismatch"
	end
	if not isNonNegativeInteger(profile.Coins) then
		return false, "InvalidCoins"
	end
	local upgrades, upgradesRecovered = copyUpgrades(profile.ShopUpgrades)
	if upgradesRecovered or type(profile.ShopUpgrades) ~= "table" then
		return false, "InvalidShopUpgrades"
	end
	local apples, applesRecovered = copyAppleTypes(profile.DiscoveredAppleTypes)
	if applesRecovered or #apples ~= #profile.DiscoveredAppleTypes then
		return false, "InvalidDiscoveredAppleTypes"
	end
	local _, tutorialRecovered = copyTutorial(profile.Tutorial)
	if tutorialRecovered or type(profile.Tutorial) ~= "table" then
		return false, "InvalidTutorial"
	end
	if type(profile.Tutorial.FirstAppleTaken) ~= "boolean"
		or type(profile.Tutorial.FirstServeCompleted) ~= "boolean"
		or type(profile.Tutorial.ColorMatchIntroduced) ~= "boolean"
	then
		return false, "InvalidTutorial"
	end
	for key in upgrades do
		if profile.ShopUpgrades[key] == nil then
			return false, "InvalidShopUpgrades"
		end
	end
	return true
end

return table.freeze(ProfileSchema)
