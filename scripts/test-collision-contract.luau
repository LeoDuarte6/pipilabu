local fs = require("@lune/fs")

local gameService = fs.readFile("src/server/GameService.luau")
local shopBuilder = fs.readFile("scripts/build-doge-shop-world.luau")
local marketBuilder = fs.readFile("scripts/build-market-village-prototype.luau")
local clientBootstrap = fs.readFile("src/client/Bootstrap.client.luau")

local requiredStructuralNames = {
	"ShopFloor",
	"BackWall",
	"LeftWall",
	"RightWall",
	"Awning",
	"Roof",
	"Counter",
	"CounterTop",
	"AppleCrate",
	"HoneygoldAppleCrate",
	"Floor",
	"ShelfUpper",
	"ShelfLower",
}

for _, name in requiredStructuralNames do
	local declaration = string.format("%s = true", name)
	assert(string.find(gameService, declaration, 1, true), string.format("structural collision allowlist is missing %s", name))
end

assert(
	string.find(gameService, 'Workspace:FindFirstChild("PipilabuMarketVillagePrototype")', 1, true),
	"runtime collision enforcement must audit the market prototype"
)
assert(
	string.find(gameService, "descendant.CanCollide = true", 1, true)
		and string.find(gameService, "descendant.CanQuery = true", 1, true),
	"runtime collision enforcement must restore both collision and spatial queries"
)

assert(
	string.find(shopBuilder, "awning.CanCollide = true", 1, true)
		and string.find(shopBuilder, "roof.CanCollide = true", 1, true),
	"shop roof and awning must be honest collidable geometry"
)
assert(
	not string.find(clientBootstrap, "LocalTransparencyModifier", 1, true),
	"the real shop roof must stay visible on the client"
)
assert(
	string.find(shopBuilder, "baseplate.CanCollide = true", 1, true),
	"ground must remain collidable"
)

for _, snippet in {
	'makePart("Counter",',
	'makePart("CounterTop",',
	'makePart("Roof",',
	'makePart("ShelfUpper",',
	'makePart("ShelfLower",',
} do
	local at = string.find(marketBuilder, snippet, 1, true)
	assert(at, string.format("market builder is missing %s", snippet))
	local lineEnd = string.find(marketBuilder, "\n", at, true) or #marketBuilder
	local line = string.sub(marketBuilder, at, lineEnd)
	assert(string.find(line, "true", 1, true), string.format("%s must opt into structural collision", snippet))
end

assert(
	string.find(gameService, "STRUCTURAL_COLLISION_NAMES[descendant.Name] == true", 1, true),
	"collision repair must remain allowlisted rather than enabling every visual or marker"
)
assert(
	not string.find(gameService, "Fruit = true", 1, true)
		and not string.find(gameService, "OrderMarker = true", 1, true)
		and not string.find(gameService, "QueueSpot = true", 1, true),
	"fruit, order UI, and queue markers must never become structural collision"
)

print("Pipi Labu collision contract passed shop, market, ground, and allowlist boundaries")
