local ShopAssignment = require("../src/shared/ShopAssignment")
local Config = require("../src/shared/Config")

local assignmentConfig = Config.MultiplayerShopAssignment
assert(assignmentConfig.Enabled == false, "multiplayer shop assignment must remain disabled by default")
assert(#assignmentConfig.BayIds == 4, "the candidate contract should expose four deterministic shop bays")

local registry = ShopAssignment.newRegistry(assignmentConfig.BayIds)

local first = registry.assign(101)
assert(first.Accepted and first.Assignment.BayId == "Shop_01", "first player should receive first bay")

local duplicate = registry.assign(101)
assert(duplicate.Accepted and duplicate.Reason == "AlreadyAssigned", "duplicate assignment must be idempotent")
assert(duplicate.Assignment.BayId == "Shop_01" and registry.count() == 1, "duplicate assignment must not consume a bay")

assert(registry.assign(202).Assignment.BayId == "Shop_02", "second player should receive second bay")
assert(registry.assign(303).Assignment.BayId == "Shop_03", "third player should receive third bay")
assert(registry.assign(404).Assignment.BayId == "Shop_04", "fourth player should receive fourth bay")

local full = registry.assign(505)
assert(not full.Accepted and full.Reason == "NoShopAvailable", "full server must reject without corrupting assignments")
assert(registry.count() == 4, "full-server rejection must preserve the four assignments")

local respawn = registry.get(202)
assert(respawn and respawn.BayId == "Shop_02", "character respawn lookup must preserve the server-session assignment")
respawn.BayId = "Tampered"
assert(registry.get(202).BayId == "Shop_02", "callers must not mutate registry truth")

local released = registry.release(202)
assert(released.Accepted and released.Assignment.BayId == "Shop_02", "leave must release the owned bay")
assert(registry.get(202) == nil and registry.count() == 3, "released player must no longer own a bay")

local rejoin = registry.assign(202)
assert(rejoin.Accepted and rejoin.Assignment.BayId == "Shop_02", "deterministic rejoin must reclaim the lowest available bay")

local snapshot = registry.snapshot()
assert(#snapshot == 4, "snapshot should expose every active assignment")
for index, assignment in snapshot do
	assert(assignment.BayId == string.format("Shop_%02d", index), "snapshot must remain in bay order")
end

assert(not registry.assign(0).Accepted, "invalid player IDs must be rejected")
assert(not registry.assign(1.5).Accepted, "fractional player IDs must be rejected")
assert(not registry.release(999).Accepted, "unknown player release must be explicit")

local duplicateBayOk = pcall(function()
	ShopAssignment.newRegistry({ "Shop_01", "Shop_01" })
end)
assert(not duplicateBayOk, "duplicate bay configuration must fail closed")

print("Pipi Labu shop assignment contract passed allocation, capacity, respawn, release, rejoin, and immutability cases")
