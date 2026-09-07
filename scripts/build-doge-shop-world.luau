-- Rebuilds the local Doge Apple Shop world layer.
-- Run through Studio MCP execute_luau or the Studio Command Bar in Edit mode.

assert(game.PlaceId == 0 and game.GameId == 0, "Refusing to build outside a local file")
assert(
	game.Name == "JonAndLeoDevelopment" or game.Name == "JonAndLeoDevelopment.rbxlx",
	"Unexpected local DataModel: " .. game.Name
)

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local OWNER = "Jon and Leo Development"

local previous = Workspace:FindFirstChild("DogeAppleShop")
if previous then
	previous:Destroy()
end

local shop = Instance.new("Folder")
shop.Name = "DogeAppleShop"
shop:SetAttribute("Owner", OWNER)
shop:SetAttribute("Build", "MVP-0.9.0")
shop.Parent = Workspace

local building = Instance.new("Folder")
building.Name = "Building"
building.Parent = shop

local function makePart(
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?,
	parent: Instance?
): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Anchored = true
	item.Material = material or Enum.Material.SmoothPlastic
	item.Color = color
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item:SetAttribute("Owner", OWNER)
	item.Parent = parent or building
	return item
end

local wallCream = Color3.fromRGB(240, 226, 200)
local floorWood = Color3.fromRGB(154, 108, 72)
local warmWood = Color3.fromRGB(118, 78, 52)
local darkWood = Color3.fromRGB(66, 46, 34)
local appleRed = Color3.fromRGB(184, 54, 46)
local leafGreen = Color3.fromRGB(62, 112, 62)

makePart("ShopFloor", Vector3.new(28, 0.4, 24), Vector3.new(0, 0.2, -16), floorWood, Enum.Material.WoodPlanks)
makePart("BackWall", Vector3.new(28, 7.5, 0.5), Vector3.new(0, 4.15, -28), wallCream, Enum.Material.SmoothPlastic)
makePart("LeftWall", Vector3.new(0.5, 7.5, 24), Vector3.new(-13.75, 4.15, -16), wallCream, Enum.Material.SmoothPlastic)
makePart("RightWall", Vector3.new(0.5, 7.5, 24), Vector3.new(13.75, 4.15, -16), wallCream, Enum.Material.SmoothPlastic)

local awning = makePart("Awning", Vector3.new(28.5, 0.4, 3.5), Vector3.new(0, 7.75, -4.25), appleRed, Enum.Material.SmoothPlastic)
awning.Orientation = Vector3.zero
awning.CanCollide = true
local roof = makePart("Roof", Vector3.new(28, 0.45, 20.5), Vector3.new(0, 7.75, -17), wallCream, Enum.Material.SmoothPlastic)
roof.CanCollide = true

makePart("Counter", Vector3.new(20, 1.25, 2), Vector3.new(0, 0.625, -2.75), darkWood, Enum.Material.WoodPlanks)
makePart("CounterTop", Vector3.new(21, 0.3, 2.75), Vector3.new(0, 1.4, -2.75), warmWood, Enum.Material.WoodPlanks)

local crate = makePart("AppleCrate", Vector3.new(6, 2.5, 5), Vector3.new(-10, 1.25, -10), warmWood, Enum.Material.WoodPlanks, shop)
crate:SetAttribute("Purpose", "ApplePickup")
crate:SetAttribute("AppleType", "Ruby")
for row = 0, 2 do
	for column = 0, 3 do
		local apple = makePart(
			string.format("DisplayApple_%02d", row * 4 + column + 1),
			Vector3.new(1.15, 1.15, 1.15),
			Vector3.new(-11.8 + column * 1.2, 2.8 + row * 0.65, -10.5 + (row % 2) * 0.8),
			appleRed,
			Enum.Material.SmoothPlastic,
			shop
		)
		apple.Shape = Enum.PartType.Ball
		apple.CanCollide = false

		local stem = makePart(
			string.format("DisplayStem_%02d", row * 4 + column + 1),
			Vector3.new(0.16, 0.5, 0.16),
			apple.Position + Vector3.new(0, 0.7, 0),
			darkWood,
			Enum.Material.Wood,
			shop
		)
		stem.CanCollide = false
	end
end

local honeygold = Color3.fromRGB(239, 181, 54)
local honeygoldCrate = makePart("HoneygoldAppleCrate", Vector3.new(6, 2.5, 5), Vector3.new(8, 1.25, -10), warmWood, Enum.Material.WoodPlanks, shop)
honeygoldCrate:SetAttribute("Purpose", "ApplePickup")
honeygoldCrate:SetAttribute("AppleType", "Honeygold")
for row = 0, 1 do
	for column = 0, 3 do
		local apple = makePart(
			string.format("HoneygoldDisplay_%02d", row * 4 + column + 1),
			Vector3.new(1.15, 1.15, 1.15),
			Vector3.new(6.2 + column * 1.2, 2.8 + row * 0.65, -10.5 + row * 0.8),
			honeygold,
			Enum.Material.SmoothPlastic,
			shop
		)
		apple.Shape = Enum.PartType.Ball
		apple.CanCollide = false
	end
end

local queueSpots = Instance.new("Folder")
queueSpots.Name = "QueueSpots"
queueSpots.Parent = shop
-- From the shopkeeper camera (looking toward +Z), +X reads screen-left.
-- Customers therefore travel +X -> 0 -> -X to appear left-to-right.
for index, x in ipairs({ 0, 2.25, 4.5, 6.75, 9, 11.25, 13.5, 15.75, 18, 20.25 }) do
	local spot = makePart(
		string.format("Spot_%02d", index),
		Vector3.new(3.2, 0.08, 2.6),
		Vector3.new(x, 0.54, 1),
		Color3.fromRGB(140, 132, 116),
		Enum.Material.SmoothPlastic,
		queueSpots
	)
	spot.Transparency = 1
	spot.CanCollide = false
end

local spawnMarker = makePart("CustomerSpawn", Vector3.new(3, 0.2, 3), Vector3.new(22.5, 0.55, 1), leafGreen, Enum.Material.Neon, shop)
spawnMarker.Transparency = 1
spawnMarker.CanCollide = false
local exitMarker = makePart("CustomerExit", Vector3.new(3, 0.2, 3), Vector3.new(-15, 0.55, 1), leafGreen, Enum.Material.Neon, shop)
exitMarker.Transparency = 1
exitMarker.CanCollide = false

local customers = Instance.new("Folder")
customers.Name = "Customers"
customers.Parent = shop

local path = makePart("CustomerPath", Vector3.new(53, 0.06, 4.25), Vector3.new(9.5, 0.53, 1), Color3.fromRGB(164, 151, 129), Enum.Material.Cobblestone)
path.CanCollide = false

local existingBaseplate = Workspace:FindFirstChild("Baseplate")
local baseplate: BasePart
if existingBaseplate and existingBaseplate:IsA("BasePart") then
	baseplate = existingBaseplate
else
	if existingBaseplate then
		existingBaseplate:Destroy()
	end
	local replacement = Instance.new("Part")
	replacement.Name = "Baseplate"
	replacement.Parent = Workspace
	baseplate = replacement
end
baseplate.Size = Vector3.new(256, 1, 256)
baseplate.Position = Vector3.new(0, -0.5, 0)
baseplate.Anchored = true
baseplate.Color = Color3.fromRGB(102, 142, 76)
baseplate.Material = Enum.Material.Grass
baseplate.Transparency = 0
baseplate.CanCollide = true
baseplate.TopSurface = Enum.SurfaceType.Smooth
baseplate.BottomSurface = Enum.SurfaceType.Smooth
baseplate:SetAttribute("Owner", OWNER)

local spawn = Workspace:FindFirstChild("SpawnLocation")
if spawn and spawn:IsA("SpawnLocation") then
	local spawnPosition = Vector3.new(0, 0.5, -8)
	spawn.CFrame = CFrame.lookAt(spawnPosition, Vector3.new(0, 0.5, 1))
	spawn.Neutral = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn:SetAttribute("Owner", OWNER)
end

Lighting.ClockTime = 10.5
Lighting.Brightness = 2.2
Lighting.EnvironmentDiffuseScale = 0.45
Lighting.EnvironmentSpecularScale = 0.35

return {
	name = shop.Name,
	owner = shop:GetAttribute("Owner"),
	build = shop:GetAttribute("Build"),
	parts = #shop:GetDescendants(),
	queueSpots = #queueSpots:GetChildren(),
	placeId = game.PlaceId,
	gameId = game.GameId,
}
