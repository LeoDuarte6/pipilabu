local Kernel = require("../src/shared/PhysicalInteractionKernel")
local Config = require("../src/shared/Config")

local config = Config.PhysicalInteractionKernel
assert(config.Enabled == false, "physical interaction kernel must remain disabled by default")
local registry = Kernel.newRegistry(config)

assert(registry.beginGrab(101, "Ruby_01", 2, 0).Accepted, "in-range object should be grabbable")
local duplicate = registry.beginGrab(101, "Ruby_01", 2, 0.1)
assert(duplicate.Accepted and duplicate.Reason == "AlreadyHeld", "duplicate grab by owner must be idempotent")

local stolen = registry.beginGrab(202, "Ruby_01", 2, 0.2)
assert(not stolen.Accepted and stolen.Reason == "OwnedByAnotherPlayer", "another player cannot steal an active grab")
local secondObject = registry.beginGrab(101, "Crate_01", 2, 0.2)
assert(not secondObject.Accepted and secondObject.Reason == "PlayerAlreadyHolding", "one player cannot own two interactions")

local tooFar = registry.heartbeat(101, "Ruby_01", config.MaximumReachStuds + 0.01, 0.3)
assert(not tooFar.Accepted and tooFar.Reason == "OutOfReachReleased", "continuous server reach must release an invalid grab")
assert(registry.beginGrab(202, "Ruby_01", 1, 0.4).Accepted, "released object must be regrabbable")

assert(registry.heartbeat(202, "Ruby_01", 1, 0.8).Accepted, "valid heartbeat should renew lease")
local expired = registry.heartbeat(202, "Ruby_01", 1, 0.8 + config.LeaseSeconds + 0.01)
assert(not expired.Accepted and expired.Reason == "LeaseExpired", "stale lease must fail closed and release")

assert(registry.beginGrab(303, "Ruby_01", 1, 10).Accepted, "expired object must become available")
assert(registry.disconnect(303) == 1, "disconnect must release owned interaction")
assert(registry.disconnect(303) == 0, "duplicate disconnect must be harmless")

assert(registry.beginGrab(404, "Ruby_01", 1, 11).Accepted, "disconnect-released object must be regrabbable")
local consumed = registry.consume(404, "Ruby_01")
assert(consumed.Accepted and consumed.State == "Consumed", "owner must have one consume/serve seam")
local duplicateConsume = registry.consume(404, "Ruby_01")
assert(not duplicateConsume.Accepted and duplicateConsume.Reason == "NotOwner", "consumed object cannot reward twice")
local consumedGrab = registry.beginGrab(404, "Ruby_01", 1, 12)
assert(not consumedGrab.Accepted and consumedGrab.Reason == "ObjectConsumed", "consumed object cannot be regripped")

assert(not registry.beginGrab(0, "Ruby_02", 1, 0).Accepted, "invalid player must be rejected")
assert(not registry.beginGrab(1, "", 1, 0).Accepted, "empty object ID must be rejected")
assert(not registry.beginGrab(1, "Ruby_02", math.huge, 0).Accepted, "non-finite reach must be rejected")

assert(registry.beginGrab(505, "Soap_01", 1, 20).Accepted, "independent object should be grabbable")
assert(registry.expire(20 + config.LeaseSeconds + 0.01) == 1, "expiry sweep must release stale ownership")
local snapshot = registry.snapshot()
assert(snapshot.Soap_01.State == "Available" and snapshot.Soap_01.OwnerPlayerId == nil, "snapshot must expose released state")
snapshot.Soap_01.State = "Tampered"
assert(registry.snapshot().Soap_01.State == "Available", "snapshot callers must not mutate authority")

print("Pipi Labu physical interaction kernel passed ownership, reach, lease, regrab, disconnect, consume-once, and immutability cases")
