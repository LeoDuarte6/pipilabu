local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
Color3 = roblox.Color3

local AppleCatalog = require("../src/shared/AppleCatalog")
local Config = require("../src/shared/Config")
local Copy = require("../src/shared/Copy")

assert(Config.DisplayName == "Pipi Labu", "player-facing name must be exactly Pipi Labu")
assert(Config.DevelopmentVersion == "0.9.9-dev", "unexpected gameplay-gate version")

assert(#AppleCatalog.All == 2, "v0.9 must expose exactly two apple choices")
assert(AppleCatalog.All[1].Id == "Ruby", "first apple must be Ruby")
assert(AppleCatalog.All[2].Id == "Honeygold", "second apple must be Honeygold")

local expectedTeachingSequence = {
	"Ruby",
	"Ruby",
	"Honeygold",
	"Ruby",
	"Honeygold",
	"Honeygold",
	"Ruby",
	"Honeygold",
	"Ruby",
	"Honeygold",
}
for index, expected in expectedTeachingSequence do
	assert(AppleCatalog.forCustomer(index).Id == expected, string.format("wrong order at customer %d", index))
end
assert(AppleCatalog.forCustomer(11).Id == "Ruby", "teaching sequence must loop deterministically")

assert(Copy.Hud.TimeLabel == "TIME", "compact HUD time label changed")
assert(Copy.Hud.ServedLabel == "SERVED", "compact HUD served label changed")
assert(Copy.Hud.MissedLabel == "MISSED", "compact HUD missed label changed")
assert(Copy.Hud.StartButton == "START SHIFT", "approved start-button copy changed")
assert(Copy.Hud.NextShiftButton == "NEXT SHIFT", "a win must not be framed as a retry")
assert(Copy.Hud.RetryButton == "TRY AGAIN", "loss recovery copy changed")
assert(Copy.Messages.WrongApple == "They ordered %s. Keep this apple or swap it.", "wrong-match effort must be preserved")
assert(Copy.Messages.Sending == "" and Copy.Messages.Served == "", "serve filler copy must stay removed")

local bannedPlayerFacingFragments = {
	"pipilabu",
	"peepilabu",
	"peepy laboo",
	"pepe le pew",
	"good fruit",
	"nice serve",
	"serve kindly",
	"front doge",
	"small doge",
	"care board",
}

local function auditStrings(value, path)
	if type(value) == "string" then
		local lowered = string.lower(value)
		for _, fragment in bannedPlayerFacingFragments do
			assert(not string.find(lowered, fragment, 1, true), string.format("banned copy '%s' at %s", fragment, path))
		end
		return
	end
	if type(value) == "table" then
		for key, child in value do
			auditStrings(child, string.format("%s.%s", path, tostring(key)))
		end
	end
end

auditStrings(Copy, "Copy")

local gameService = fs.readFile("src/server/GameService.luau")
local shopBuilder = fs.readFile("scripts/build-doge-shop-world.luau")

-- GOLDEN-CHANGE: the complete August 7–8 dictation/task audit confirmed that
-- five/six only technically escaped the rejected three-customer line. Leo and
-- Jon repeatedly asked for a visibly populated, cute town line. The comfort
-- lane now starts with eight and reserves ten without increasing difficulty.
-- GOLDEN-CHANGE: literal cloud framing showed 3.4-stud spacing hid members
-- behind the wall/owner. Measured 2.10-stud visuals fit eight at 2.25 studs.
assert(Config.Shop.StartingQueueSize == 8, "the visible line must start with eight customers")
assert(Config.Shop.MaximumQueueSize == 10, "the authored lane must support ten customers")
-- GOLDEN-CHANGE: the 2026-08-10 live playtest explicitly capped level one at
-- its opening eight customers. The win target and total population now match;
-- replacement spawning is deferred to a later progression gate.
assert(Config.Shop.FirstShiftPopulationCap == 8, "level one must contain exactly its starting eight customers")
assert(Config.Shift.TargetServed == 8, "level-one win target must be achievable from its fixed population")
assert(not string.find(gameService, "task.delay(shopConfig.CustomerRespawnDelay", 1, true), "level one may not schedule replacement customers")
assert(Config.Shop.QueueSpacingStuds == 2.25, "all eight customers must fit the service view")
assert(
	string.find(gameService, "local laneY = if spots[1] then spots[1].Position.Y else 0.54", 1, true),
	"runtime queue extensions must inherit the authored queue-plane height"
)
assert(
	string.find(gameService, 'shop:SetAttribute("QueueSpacingStuds", shopConfig.QueueSpacingStuds)', 1, true),
	"runtime queue spacing must be observable in Studio"
)
assert(
	string.find(shopBuilder, "for index, x in ipairs({ 0, 2.25, 4.5, 6.75, 9, 11.25, 13.5, 15.75, 18, 20.25 }) do", 1, true),
	"queue must start at the centered counter position and extend toward screen-left"
)
assert(
	string.find(shopBuilder, 'Vector3.new(22.5, 0.55, 1)', 1, true)
		and string.find(shopBuilder, 'Vector3.new(-15, 0.55, 1)', 1, true),
	"customers must enter from +X and leave through -X for left-to-right shopkeeper flow"
)
assert(
	string.find(gameService, "local spot = spots[index]", 1, true)
		and string.find(gameService, "prompt.Enabled = index == 1", 1, true),
	"the first queue member must own the centered service spot and serve prompt"
)

assert(Config.OwnerPresentation.TargetPosition.X == -9, "owner must occupy the rear-left interior instead of the service lane")
assert(Config.OwnerPresentation.TargetPosition.Z == -20, "owner must stay well behind both apple crates and the counter lane")
assert(Config.OwnerPresentation.TargetYawDegrees == 0, "the imported side-ear owner must face the service lane")
assert(Config.OwnerPresentation.ScaleMultiplier == 1.15, "owner hierarchy must stay large without occluding the counter")

-- GOLDEN-CHANGE: Leo and Jon explicitly rejected the nearly invisible v0.9.4
-- transfer. The catch now prioritizes readable physical pleasure over speed.
assert(Config.Shop.HandoffDuration == 0.34, "handoff must be visible without feeling delayed")
assert(Config.Shop.HandoffArcHeight == 0.62, "handoff must describe a readable arc")
assert(Config.Shop.HandoffSettleTime == 0.16, "handoff catch must have a visible squash-settle")
assert(Config.Shop.ServeCelebrationTime >= 1.5, "customer must have time to enjoy the apple before leaving")
local handoffNameAt = string.find(gameService, 'heldApple.Name = "HandoffApple"', 1, true)
local handoffParentAt = string.find(gameService, "heldApple.Parent = customer", 1, true)
local handoffMotionAt = string.find(gameService, "local startCFrame = heldApple.CFrame", 1, true)
assert(handoffNameAt and handoffParentAt and handoffMotionAt, "handoff inventory-isolation seam is missing")
assert(handoffNameAt < handoffMotionAt and handoffParentAt < handoffMotionAt, "handoff visual must leave player inventory before motion begins")

print("Pipi Labu v0.9 gameplay contract passed naming, queue, apple, handoff, HUD, and copy gates")
