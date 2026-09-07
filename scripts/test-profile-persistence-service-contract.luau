local fs = require("@lune/fs")

local Config = require("../src/shared/Config")
local service = fs.readFile("src/server/ProfilePersistenceService.luau")
local bootstrap = fs.readFile("src/server/Bootstrap.server.luau")

assert(Config.ProfilePersistence.Enabled == false, "profile persistence must remain disabled by default")
assert(string.find(service, 'Code = "Disabled"', 1, true), "disabled result must be explicit")
assert(string.find(service, "if type(config) ~= \"table\" or config.Enabled ~= true then", 1, true), "DataStore access must be behind the disabled gate")

local gatePosition = string.find(service, "if type(config) ~= \"table\" or config.Enabled ~= true then", 1, true)
local storePosition = string.find(service, "DataStoreService:GetDataStore(config.StoreName)", 1, true)
assert(gatePosition and storePosition and gatePosition < storePosition, "DataStore must not be requested before the enabled gate")

assert(string.find(service, "currentStore:GetAsync(profileKey(userId))", 1, true), "bounded load is missing")
assert(string.find(service, "currentStore:UpdateAsync(profileKey(userId)", 1, true), "conflict-safe save is missing")
assert(not string.find(service, ":SetAsync(", 1, true), "blind SetAsync writes are prohibited")
assert(string.find(service, 'migration.Reason == "UnsupportedFutureVersion"', 1, true), "future schemas must fail closed")
assert(string.find(service, 'player:SetAttribute(STATE_ATTRIBUTE, "LoadFailed")', 1, true), "load failure state is missing")
assert(string.find(service, "if loadNonce[userId] ~= nonce or player.Parent ~= Players then", 1, true), "departed-player load race guard is missing")
assert(string.find(service, "ProfileSchema.validate(profile)", 1, true), "save validation is missing")
assert(string.find(service, "Players.PlayerRemoving:Connect(releasePlayer)", 1, true), "leave save/release is missing")
assert(string.find(service, "game:BindToClose", 1, true), "server-close flush is missing")
assert(string.find(bootstrap, "ProfilePersistenceService.Start(Config.ProfilePersistence)", 1, true), "bootstrap must route through the disabled persistence gate")

print("Pipi Labu profile-persistence service contract passed disabled gate, load/save, race, validation, and future-schema checks")
