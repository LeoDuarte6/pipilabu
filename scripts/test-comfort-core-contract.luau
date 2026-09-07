local fs = require("@lune/fs")

local Config = require("../src/shared/Config")
local Copy = require("../src/shared/Copy")
local gameService = fs.readFile("src/server/GameService.luau")
local clientBootstrap = fs.readFile("src/client/Bootstrap.client.luau")

assert(Copy.Messages.WrongAppleReaction == "NOPE!", "wrong apple needs a readable character reaction")
assert(Copy.Messages.EnjoyedApple == "YUM!", "successful service needs an enjoyment reaction")

assert(
	string.find(gameService, "root.CanCollide = true", 1, true)
		and string.find(gameService, 'root:SetAttribute("ComfortCollisionProxy", true)', 1, true),
	"customers must own one stable physical collision proxy"
)
assert(
	string.find(gameService, "local function animateWrongAppleBounce", 1, true)
		and string.find(gameService, 'proxy.Name = "RejectedApple"', 1, true)
		and string.find(gameService, 'task.spawn(animateWrongAppleBounce, player, customer, order.Id)', 1, true),
	"wrong apples must visibly travel out and return instead of producing text only"
)
assert(
	string.find(gameService, 'player:SetAttribute("WrongAppleSerial", 0)', 1, true)
		and string.find(gameService, 'bumpPlayerSerial(player, "WrongAppleSerial")', 1, true),
	"wrong-apple reactions must expose deterministic telemetry"
)
assert(
	string.find(gameService, "local function animateAppleEnjoyment", 1, true)
		and string.find(gameService, 'crumb.Name = "AppleCrumb"', 1, true)
		and string.find(gameService, 'customer:SetAttribute("EnjoymentComplete", true)', 1, true),
	"served customers must visibly eat the apple and complete the reaction"
)
assert(
	string.find(gameService, 'local function animateQueueRipple(kind: "Served" | "WrongApple"', 1, true)
		and string.find(gameService, 'waitingCustomer:SetAttribute("GroupReactionSerial", serial)', 1, true)
		and string.find(gameService, 'animateQueueRipple("WrongApple", customer)', 1, true)
		and string.find(gameService, 'animateQueueRipple("Served", customer)', 1, true)
		and string.find(gameService, "if reacted > 5 then", 1, true),
	"nearby customers must react as a bounded staggered group without a global event system"
)
assert(
	string.find(clientBootstrap, 'elseif action == "Wrong" then', 1, true)
		and string.find(clientBootstrap, "Copy.Messages.WrongAppleReaction", 1, true),
	"wrong-apple feedback must reach the local presentation layer"
)

assert(Config.Shop.WrongAppleOutDuration > 0 and Config.Shop.WrongAppleReturnDuration > 0, "wrong-apple travel must be timed")
assert(Config.Shop.WrongAppleArcHeight > 0, "wrong-apple return needs a readable arc")
assert(Config.Shop.EnjoymentApproachDuration > 0 and Config.Shop.EnjoymentBiteDuration > 0, "eating must be paced")

-- Negative guarantee: the wrong-apple branch returns before the authoritative
-- inventory-clear block. A rejection may animate the visual but cannot consume
-- the player's held item.
local wrongBranch = assert(string.find(gameService, 'if player:GetAttribute("HeldAppleType") ~= order.Id then', 1, true))
local wrongReturn = assert(string.find(gameService, "\n\t\t\t\treturn", wrongBranch, true))
local inventoryClear = assert(string.find(gameService, 'player:SetAttribute("HasApple", false)', wrongBranch, true))
assert(wrongReturn < inventoryClear, "wrong apple must return before inventory is consumed")

print("Pipi Labu comfort-core contract passed collision, rejection, handoff, eating, and inventory-preservation gates")
