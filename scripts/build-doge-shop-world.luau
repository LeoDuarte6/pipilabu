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
shop:SetAttribute("Build", "MVP-0.2.0")
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

local cream = Color3.fromRGB(255, 236, 194)
local warmWood = Color3.fromRGB(135, 78, 43)
local darkWood = Color3.fromRGB(74, 41, 27)
local appleRed = Color3.fromRGB(216, 48, 45)
local leafGreen = Color3.fromRGB(58, 126, 67)
local awningRed = Color3.fromRGB(173, 46, 45)
local gold = Color3.fromRGB(245, 190, 62)

makePart("ShopFloor", Vector3.new(32, 1, 28), Vector3.new(0, 0, -16), cream, Enum.Material.WoodPlanks)
makePart("BackWall", Vector3.new(32, 12, 1), Vector3.new(0, 6, -29.5), warmWood, Enum.Material.WoodPlanks)
makePart("LeftWall", Vector3.new(1, 8, 28), Vector3.new(-15.5, 4, -16), warmWood, Enum.Material.WoodPlanks)
makePart("RightWall", Vector3.new(1, 8, 28), Vector3.new(15.5, 4, -16), warmWood, Enum.Material.WoodPlanks)

local awning = makePart("Awning", Vector3.new(34, 1, 5), Vector3.new(0, 10, -3), awningRed, Enum.Material.Fabric)
awning.Orientation = Vector3.new(0, 0, -5)

makePart("Counter", Vector3.new(22, 2.7, 2.5), Vector3.new(1.5, 1.35, -2), darkWood, Enum.Material.WoodPlanks)
makePart("CounterTop", Vector3.new(24, 0.7, 4), Vector3.new(1.5, 2.9, -2), warmWood, Enum.Material.WoodPlanks)

local function addBoard(name: string, size: Vector3, position: Vector3, text: string, color: Color3)
	local board = makePart(name, size, position, darkWood, Enum.Material.WoodPlanks)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Back
	gui.AlwaysOnTop = true
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 45
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextWrapped = true
	label.TextStrokeColor3 = Color3.fromRGB(55, 31, 20)
	label.TextStrokeTransparency = 0.15
	label.Parent = gui
end

addBoard("GoodFruitSign", Vector3.new(16, 5, 0.7), Vector3.new(-5.5, 7.5, -28.9), "GOOD FRUIT", gold)
addBoard(
	"Instructions",
	Vector3.new(11, 7, 0.7),
	Vector3.new(9, 5.5, -28.9),
	"1. TAKE ONE\n2. SERVE FRONT DOGE\n3. GROW GOOD",
	Color3.fromRGB(255, 244, 210)
)

local crate = makePart("AppleCrate", Vector3.new(6, 2.5, 5), Vector3.new(-10, 1.25, -10), warmWood, Enum.Material.WoodPlanks, shop)
crate:SetAttribute("Purpose", "ApplePickup")
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

local queueSpots = Instance.new("Folder")
queueSpots.Name = "QueueSpots"
queueSpots.Parent = shop
for index, z in ipairs({ 1, 6, 11, 16 }) do
	local spot = makePart(
		string.format("Spot_%02d", index),
		Vector3.new(5, 0.15, 3.5),
		Vector3.new(0, 0.58, z),
		Color3.fromRGB(255, 220, 112),
		Enum.Material.Neon,
		queueSpots
	)
	spot.Transparency = 0.62
	spot.CanCollide = false
end

local spawnMarker = makePart("CustomerSpawn", Vector3.new(3, 0.2, 3), Vector3.new(0, 0.55, 24), leafGreen, Enum.Material.Neon, shop)
spawnMarker.Transparency = 1
spawnMarker.CanCollide = false
local exitMarker = makePart("CustomerExit", Vector3.new(3, 0.2, 3), Vector3.new(23, 0.55, 1), leafGreen, Enum.Material.Neon, shop)
exitMarker.Transparency = 1
exitMarker.CanCollide = false

local customers = Instance.new("Folder")
customers.Name = "Customers"
customers.Parent = shop

local path = makePart("CustomerPath", Vector3.new(8, 0.2, 31), Vector3.new(0, 0.04, 10), Color3.fromRGB(198, 167, 119), Enum.Material.Cobblestone)
path.CanCollide = false

local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.Color = Color3.fromRGB(102, 142, 76)
	baseplate.Material = Enum.Material.Grass
	baseplate:SetAttribute("Owner", OWNER)
end

local spawn = Workspace:FindFirstChild("SpawnLocation")
if spawn and spawn:IsA("SpawnLocation") then
	spawn.Position = Vector3.new(-9, 0.5, 17)
	spawn.Orientation = Vector3.new(0, 145, 0)
	spawn.Neutral = true
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
