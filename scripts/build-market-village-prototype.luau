-- Builds an additive, local-only market-village presentation prototype.
--
-- This script never edits or reparents Workspace.DogeAppleShop. It replaces
-- only its own exact root so the entire lane can be removed and rebuilt.
-- Run through Studio MCP or the Studio Command Bar in Edit mode after Rojo
-- has synced the shared modules.

assert(game.PlaceId == 0 and game.GameId == 0, "Refusing to build outside a local file")
assert(
	game.Name == "JonAndLeoDevelopment" or game.Name == "JonAndLeoDevelopment.rbxlx",
	"Unexpected local DataModel: " .. game.Name
)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Copy = require(projectRoot:WaitForChild("Copy"))
local MarketVillage = require(projectRoot:WaitForChild("MarketVillage"))
local Presentation = require(projectRoot:WaitForChild("Presentation"))

local OWNER = "Jon and Leo Development"
local Palette = Presentation.Palette

local existingShop = Workspace:FindFirstChild("DogeAppleShop")
assert(existingShop and existingShop:IsA("Folder"), "Build the existing DogeAppleShop first")

local previous = Workspace:FindFirstChild(MarketVillage.RootName)
if previous then
	assert(previous:IsA("Folder"), "Refusing to replace an unexpected village instance")
	previous:Destroy()
end

local village = Instance.new("Folder")
village.Name = MarketVillage.RootName
village:SetAttribute("Owner", OWNER)
village:SetAttribute("Build", MarketVillage.Build)
village:SetAttribute(MarketVillage.PresentationEnabledAttribute, true)
village:SetAttribute("TouchesDogeAppleShop", false)
village:SetAttribute("PrototypePolicy", "Decorative layout plus positive service readback only")
village:SetAttribute("ActiveShopContract", "Workspace.DogeAppleShop")
village.Parent = Workspace

local function makeFolder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("Owner", OWNER)
	folder:SetAttribute("PrototypeOnly", true)
	folder.Parent = parent
	return folder
end

local function makePart(
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	transparency: number?
): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Anchored = true
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.CastShadow = true
	item.Material = material
	item.Color = color
	item.Transparency = transparency or 0
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item:SetAttribute("Owner", OWNER)
	item:SetAttribute("PrototypeOnly", true)
	item.Parent = parent
	return item
end

local function makeBillboard(
	adornee: BasePart,
	name: string,
	text: string,
	color: Color3,
	size: UDim2,
	offset: Vector3
): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = name .. "Billboard"
	billboard.Adornee = adornee
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 80
	billboard.Size = size
	billboard.StudsOffset = offset
	billboard.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundColor3 = Palette.Paper
	label.BackgroundTransparency = 0.06
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Color = Palette.WoodDark
	stroke.Thickness = 1.25
	stroke.Parent = label
	return label
end

local function addFruitDisplay(parent: Folder, center: Vector3, fruitColor: Color3)
	local display = makeFolder("FruitDisplay", parent)
	for column = -2, 2 do
		local fruit = makePart(
			string.format("Fruit_%02d", column + 3),
			Vector3.new(0.86, 0.86, 0.86),
			center + Vector3.new(column * 1.2, 0.52, 0),
			fruitColor,
			Enum.Material.SmoothPlastic,
			display
		)
		fruit.Shape = Enum.PartType.Ball
		fruit.Reflectance = 0.03

		makePart(
			string.format("Stem_%02d", column + 3),
			Vector3.new(0.12, 0.32, 0.12),
			center + Vector3.new(column * 1.2, 1.03, 0),
			Palette.WoodDark,
			Enum.Material.Wood,
			display
		)
	end

	local leaf = makePart(
		"DisplayLeaf",
		Vector3.new(1.2, 0.08, 0.36),
		center + Vector3.new(0.6, 1.08, 0),
		Palette.Leaf,
		Enum.Material.SmoothPlastic,
		display
	)
	leaf.Orientation = Vector3.new(0, 0, -18)
end

local fixtures: Folder

local function makeStall(
	name: string,
	position: Vector3,
	awningColor: Color3,
	signText: string,
	fruitColor: Color3
): Folder
	local stall = makeFolder(name, fixtures)
	stall:SetAttribute("Role", "FutureNeighborShopDisplay")
	stall:SetAttribute("InteractionEnabled", false)

	makePart("Floor", Vector3.new(11, 0.12, 6), position + Vector3.new(0, 0.06, 0), Palette.Wood, Enum.Material.WoodPlanks, stall)
	local back = makePart("BackWall", Vector3.new(10, 4.8, 0.4), position + Vector3.new(0, 2.4, 2.5), Palette.Cream, Enum.Material.SmoothPlastic, stall)
	makePart("Counter", Vector3.new(9.8, 1.05, 2.1), position + Vector3.new(0, 0.55, -0.55), Palette.WoodDark, Enum.Material.WoodPlanks, stall)
	makePart("CounterTop", Vector3.new(10.2, 0.22, 2.45), position + Vector3.new(0, 1.18, -0.55), Palette.Wood, Enum.Material.WoodPlanks, stall)

	local awning = makePart("Awning", Vector3.new(11.2, 0.34, 3.2), position + Vector3.new(0, 5.05, -0.55), awningColor, Enum.Material.SmoothPlastic, stall)
	for stripe = -2, 2 do
		makePart(
			string.format("AwningStripe_%02d", stripe + 3),
			Vector3.new(1.35, 0.05, 3.28),
			position + Vector3.new(stripe * 2.2, 4.84, -0.55),
			if stripe % 2 == 0 then Palette.Paper else awningColor,
			Enum.Material.SmoothPlastic,
			stall
		)
	end
	awning:SetAttribute("PresentationRole", "ShelterAndSilhouette")

	makePart("ShelfUpper", Vector3.new(8.2, 0.24, 0.8), position + Vector3.new(0, 2.55, 1.9), Palette.Wood, Enum.Material.WoodPlanks, stall)
	makePart("ShelfLower", Vector3.new(8.2, 0.24, 0.8), position + Vector3.new(0, 1.75, 1.9), Palette.Wood, Enum.Material.WoodPlanks, stall)
	addFruitDisplay(stall, position + Vector3.new(0, 1.42, -0.85), fruitColor)
	makeBillboard(back, "ShopSign", signText, Palette.Ink, UDim2.fromOffset(190, 46), Vector3.new(0, 1.15, 0))

	return stall
end

local function makeLantern(parent: Folder, name: string, position: Vector3)
	makePart("Post", Vector3.new(0.22, 3.8, 0.22), position + Vector3.new(0, 1.9, 0), Palette.WoodDark, Enum.Material.Wood, parent)
	local lantern = makePart("Lantern", Vector3.new(0.92, 1.15, 0.92), position + Vector3.new(0, 3.85, 0), Palette.Lantern, Enum.Material.Glass, parent)
	lantern.Shape = Enum.PartType.Ball
	lantern:SetAttribute("FixtureName", name)

	local light = Instance.new("PointLight")
	light.Name = "WarmGlow"
	light.Color = Palette.Lantern
	light.Range = 8
	light.Brightness = 0.7
	light.Enabled = true
	light.Parent = lantern
end

local grounding = makeFolder(MarketVillage.GroundingFolderName, village)
makePart("MarketStreet", Vector3.new(10, 0.08, 58), Vector3.new(0, 0.05, 42), Palette.Path, Enum.Material.Cobblestone, grounding)
makePart("MarketPlaza", Vector3.new(42, 0.08, 12), Vector3.new(0, 0.07, 6), Palette.Stone, Enum.Material.Slate, grounding)
local neighborLanes = makeFolder(MarketVillage.NeighborLanesFolderName, village)
makePart("WestNeighborLane", Vector3.new(3.2, 0.08, 26), Vector3.new(-15, 0.08, -8), Palette.Path, Enum.Material.Cobblestone, neighborLanes)
makePart("EastNeighborLane", Vector3.new(3.2, 0.08, 26), Vector3.new(15, 0.08, -8), Palette.Path, Enum.Material.Cobblestone, neighborLanes)
makePart("WestUpperLane", Vector3.new(3.2, 0.08, 20), Vector3.new(-15, 0.08, 61), Palette.Path, Enum.Material.Cobblestone, neighborLanes)
makePart("EastUpperLane", Vector3.new(3.2, 0.08, 20), Vector3.new(15, 0.08, 61), Palette.Path, Enum.Material.Cobblestone, neighborLanes)

fixtures = makeFolder(MarketVillage.FixturesFolderName, village)
makeStall("TeaStall", Vector3.new(-19, 0, 28), Palette.Indigo, "TEA", Palette.Persimmon)
makeStall("FlowerStall", Vector3.new(19, 0, 28), Palette.FlowerPink, "FLOWERS", Palette.FlowerPink)
makeStall("RiceStall", Vector3.new(-19, 0, 49), Palette.Cream, "RICE", Palette.Paper)
makeStall("LanternStall", Vector3.new(19, 0, 49), Palette.Vermilion, "LANTERNS", Palette.Lantern)

for index, position in ipairs({
	Vector3.new(-6, 0, 16),
	Vector3.new(6, 0, 16),
	Vector3.new(-6, 0, 57),
	Vector3.new(6, 0, 57),
}) do
	makeLantern(fixtures, string.format("Lantern_%02d", index), position)
end

local plots = makeFolder(MarketVillage.ShopPlotsFolderName, village)
plots:SetAttribute("OwnershipMode", "Reserved display only")
plots:SetAttribute("MultiplayerReady", false)
local plotData = {
	{ Name = "Plot_West_01", Position = Vector3.new(-22, 0.1, -16), Lane = "WestNeighborLane" },
	{ Name = "Plot_East_01", Position = Vector3.new(22, 0.1, -16), Lane = "EastNeighborLane" },
	{ Name = "Plot_West_02", Position = Vector3.new(-21, 0.1, 64), Lane = "WestUpperLane" },
	{ Name = "Plot_East_02", Position = Vector3.new(21, 0.1, 64), Lane = "EastUpperLane" },
}
for _, data in ipairs(plotData) do
	local plot = makeFolder(data.Name, plots)
	plot:SetAttribute("ReservedFor", "FutureNeighborShop")
	plot:SetAttribute("Lane", data.Lane)
	plot:SetAttribute("InteractionEnabled", false)
	local pad = makePart("ReservedPad", Vector3.new(12, 0.08, 14), data.Position, Palette.Stone, Enum.Material.Slate, plot, 0.2)
	pad:SetAttribute("FutureSystem", "OneShopPerPlayer after Gate F")
	makeBillboard(pad, "PlotLabel", "FUTURE SHOP", Palette.Ink, UDim2.fromOffset(160, 38), Vector3.new(0, 1.6, 0))
	for corner = -1, 1, 2 do
		makePart("PlotPostX", Vector3.new(0.18, 2.1, 0.18), data.Position + Vector3.new(corner * 5.3, 1.05, -6), Palette.WoodDark, Enum.Material.Wood, plot)
		makePart("PlotPostZ", Vector3.new(0.18, 2.1, 0.18), data.Position + Vector3.new(corner * 5.3, 1.05, 6), Palette.WoodDark, Enum.Material.Wood, plot)
	end
end

local stewardshipDisplay = makeFolder(MarketVillage.StewardshipDisplayName, village)
stewardshipDisplay:SetAttribute("Purpose", "Positive service consequence readback")
local board = makePart("Board", Vector3.new(9, 4.8, 0.35), Vector3.new(-9, 2.7, 7.2), Palette.WoodDark, Enum.Material.WoodPlanks, stewardshipDisplay)
local boardSurface = Instance.new("SurfaceGui")
boardSurface.Name = "BoardSurface"
boardSurface.Face = Enum.NormalId.Front
boardSurface.AlwaysOnTop = false
boardSurface.CanvasSize = Vector2.new(900, 480)
boardSurface.Parent = board

local boardMessage = Instance.new("TextLabel")
boardMessage.Name = "Message"
boardMessage.BackgroundTransparency = 1
boardMessage.Position = UDim2.fromScale(0.06, 0.06)
boardMessage.Size = UDim2.fromScale(0.88, 0.25)
boardMessage.Font = Enum.Font.GothamBold
boardMessage.Text = Copy.Village.OpenHands
boardMessage.TextColor3 = Palette.CareSoft
boardMessage.TextScaled = true
boardMessage.Parent = boardSurface

local boardCount = Instance.new("TextLabel")
boardCount.Name = "Count"
boardCount.BackgroundTransparency = 1
boardCount.Position = UDim2.fromScale(0.68, 0.72)
boardCount.Size = UDim2.fromScale(0.25, 0.18)
boardCount.Font = Enum.Font.GothamBlack
boardCount.Text = "0 / 3"
boardCount.TextColor3 = Palette.Paper
boardCount.TextScaled = true
boardCount.Parent = boardSurface

local careMarkers = makeFolder(MarketVillage.CareMarkersName, stewardshipDisplay)
for index, threshold in ipairs({ 3, 6, 10 }) do
	local marker = makePart(
		string.format("%s%02d", MarketVillage.CareMarkerPrefix, index),
		Vector3.new(1.1, 1.1, 0.24),
		Vector3.new(-11.1 + (index - 1) * 2.1, 2.35, 6.98),
		Palette.Paper,
		Enum.Material.SmoothPlastic,
		careMarkers,
		0.48
	)
	marker:SetAttribute("CareThreshold", threshold)
	marker:SetAttribute("RewardsPlayer", false)
	local glow = Instance.new("PointLight")
	glow.Name = "CareGlow"
	glow.Color = Palette.CareGreen
	glow.Range = 6
	glow.Brightness = 0.8
	glow.Enabled = false
	glow.Parent = marker
end

local anchor = Instance.new("Model")
anchor.Name = MarketVillage.PeepilabuAnchorName
anchor:SetAttribute("Owner", OWNER)
anchor:SetAttribute("Role", "Owner and future quest anchor")
anchor:SetAttribute("InteractionEnabled", false)
anchor:SetAttribute("BlocksGameplay", false)
anchor:SetAttribute("QuestSystem", "Reserved; no active quest logic")
anchor.Parent = village

local anchorRoot = makePart("Root", Vector3.new(2, 4, 2), Vector3.new(12, 2.1, 13), Palette.DogeCoat, Enum.Material.SmoothPlastic, anchor, 1)
anchor.PrimaryPart = anchorRoot
makePart("Body", Vector3.new(2.6, 2.8, 2.1), Vector3.new(12, 1.45, 13), Palette.DogeCoat, Enum.Material.SmoothPlastic, anchor)
local anchorHead = makePart("Head", Vector3.new(2.55, 2.35, 2.4), Vector3.new(12, 3.8, 12.9), Palette.DogeCoat, Enum.Material.SmoothPlastic, anchor)
anchorHead.Shape = Enum.PartType.Ball
makePart("Muzzle", Vector3.new(1.35, 0.75, 1.05), Vector3.new(12, 3.45, 11.75), Palette.Muzzle, Enum.Material.SmoothPlastic, anchor)
makePart("LeftEar", Vector3.new(0.7, 1.15, 0.55), Vector3.new(11.25, 5.15, 12.85), Palette.WoodDark, Enum.Material.SmoothPlastic, anchor)
makePart("RightEar", Vector3.new(0.7, 1.15, 0.55), Vector3.new(12.75, 5.15, 12.85), Palette.WoodDark, Enum.Material.SmoothPlastic, anchor)
makePart("LeftEye", Vector3.new(0.22, 0.32, 0.18), Vector3.new(11.55, 4, 11.75), Palette.Ink, Enum.Material.SmoothPlastic, anchor)
makePart("RightEye", Vector3.new(0.22, 0.32, 0.18), Vector3.new(12.45, 4, 11.75), Palette.Ink, Enum.Material.SmoothPlastic, anchor)
makePart("Clipboard", Vector3.new(0.85, 1.2, 0.12), Vector3.new(11.1, 1.6, 11.85), Palette.Wood, Enum.Material.WoodPlanks, anchor)
makeBillboard(anchorHead, "AnchorLabel", Copy.Village.PeepilabuAnchor, Palette.Ink, UDim2.fromOffset(210, 62), Vector3.new(0, 1.9, 0))

local seams = makeFolder(MarketVillage.ExtensionSeamsName, village)
seams:SetAttribute("RuntimeBehavior", "None")
local seamData = {
	{ Name = "Reputation", System = "Reputation", Position = Vector3.new(-30, 0.08, 7) },
	{ Name = "Economy", System = "EconomicMoments", Position = Vector3.new(30, 0.08, 7) },
	{ Name = "RandomEvents", System = "ControlledSurprises", Position = Vector3.new(-30, 0.08, 53) },
	{ Name = "NeighborHelp", System = "NeighborHelping", Position = Vector3.new(30, 0.08, 53) },
}
for _, data in ipairs(seamData) do
	local seam = makeFolder(data.Name, seams)
	seam:SetAttribute("ReservedSystem", data.System)
	seam:SetAttribute("ActivationGate", "Future human playtest gate")
	seam:SetAttribute("Active", false)
	local marker = makePart("Hook", Vector3.new(1.2, 0.12, 1.2), data.Position, Palette.Paper, Enum.Material.SmoothPlastic, seam, 1)
	marker:SetAttribute("NoRuntimeBehavior", true)
end

return {
	name = village.Name,
	build = village:GetAttribute("Build"),
	parts = #village:GetDescendants(),
	fixtures = #fixtures:GetChildren(),
	plots = #plots:GetChildren(),
	extensionSeams = #seams:GetChildren(),
	placeId = game.PlaceId,
	gameId = game.GameId,
}
