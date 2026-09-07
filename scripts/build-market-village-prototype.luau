-- Builds an additive market-village presentation prototype in either the
-- local fallback file or the one exact private Pipilabu cloud place.
--
-- This script never edits or reparents Workspace.DogeAppleShop. It replaces
-- only its own exact root so the entire lane can be removed and rebuilt.
-- Run through Studio MCP or the Studio Command Bar in Edit mode after Rojo
-- has synced the shared modules.

local isLocalFallback = game.PlaceId == 0 and game.GameId == 0
local isPrivatePipilabu = game.PlaceId == 133099029551440 and game.GameId == 10646495069
assert(isLocalFallback or isPrivatePipilabu, "Refusing to build outside the Pipilabu allowlist")
if isLocalFallback then
	assert(
		game.Name == "JonAndLeoDevelopment" or game.Name == "JonAndLeoDevelopment.rbxlx",
		"Unexpected local DataModel: " .. game.Name
	)
else
	assert(game.Name == "Pipilabu", "Unexpected private DataModel: " .. game.Name)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
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
	transparency: number?,
	canCollide: boolean?
): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Anchored = true
	item.CanCollide = canCollide == true
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
	billboard.MaxDistance = 42
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

	makePart("Floor", Vector3.new(11, 0.12, 6), position + Vector3.new(0, 0.06, 0), Palette.Wood, Enum.Material.WoodPlanks, stall, nil, true)
	local back = makePart("BackWall", Vector3.new(10, 4.8, 0.4), position + Vector3.new(0, 2.4, 2.5), Palette.Cream, Enum.Material.SmoothPlastic, stall, nil, true)
	makePart("Counter", Vector3.new(9.8, 1.05, 2.1), position + Vector3.new(0, 0.55, -0.55), Palette.WoodDark, Enum.Material.WoodPlanks, stall, nil, true)
	makePart("CounterTop", Vector3.new(10.2, 0.22, 2.45), position + Vector3.new(0, 1.18, -0.55), Palette.Wood, Enum.Material.WoodPlanks, stall, nil, true)
	makePart("Roof", Vector3.new(11, 0.38, 5.6), position + Vector3.new(0, 5.05, 0.25), Palette.Cream, Enum.Material.SmoothPlastic, stall, nil, true)

	local awning = makePart("Awning", Vector3.new(11.2, 0.34, 3.2), position + Vector3.new(0, 5.05, -1.15), awningColor, Enum.Material.SmoothPlastic, stall, nil, true)
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

	makePart("ShelfUpper", Vector3.new(8.2, 0.24, 0.8), position + Vector3.new(0, 2.55, 1.9), Palette.Wood, Enum.Material.WoodPlanks, stall, nil, true)
	makePart("ShelfLower", Vector3.new(8.2, 0.24, 0.8), position + Vector3.new(0, 1.75, 1.9), Palette.Wood, Enum.Material.WoodPlanks, stall, nil, true)
	addFruitDisplay(stall, position + Vector3.new(0, 1.42, -0.85), fruitColor)
	makeBillboard(back, "ShopSign", signText, Palette.Ink, UDim2.fromOffset(112, 28), Vector3.new(0, 1.15, 0))

	return stall
end

local function makeLantern(parent: Folder, name: string, position: Vector3)
	makePart("Post", Vector3.new(0.22, 3.8, 0.22), position + Vector3.new(0, 1.9, 0), Palette.WoodDark, Enum.Material.Wood, parent, nil, true)
	local lantern = makePart("Lantern", Vector3.new(0.92, 1.15, 0.92), position + Vector3.new(0, 3.85, 0), Palette.Lantern, Enum.Material.Glass, parent, nil, true)
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
makePart("MarketStreet", Vector3.new(10, 0.08, 50), Vector3.new(0, 0.05, 25), Palette.Path, Enum.Material.Cobblestone, grounding)
makePart("MarketPlaza", Vector3.new(42, 0.08, 12), Vector3.new(0, 0.07, 6), Palette.Stone, Enum.Material.Slate, grounding)
makePart("LowerCrossStreet", Vector3.new(42, 0.08, 3.2), Vector3.new(0, 0.06, 17), Palette.Path, Enum.Material.Cobblestone, grounding)
makePart("UpperCrossStreet", Vector3.new(42, 0.08, 3.2), Vector3.new(0, 0.06, 35), Palette.Path, Enum.Material.Cobblestone, grounding)
local neighborLanes = makeFolder(MarketVillage.NeighborLanesFolderName, village)
makePart("WestNeighborLane", Vector3.new(3.2, 0.08, 26), Vector3.new(-15, 0.08, -8), Palette.Path, Enum.Material.Cobblestone, neighborLanes)
makePart("EastNeighborLane", Vector3.new(3.2, 0.08, 26), Vector3.new(15, 0.08, -8), Palette.Path, Enum.Material.Cobblestone, neighborLanes)
makePart("WestUpperLane", Vector3.new(3.2, 0.08, 20), Vector3.new(-15, 0.08, 61), Palette.Path, Enum.Material.Cobblestone, neighborLanes)
makePart("EastUpperLane", Vector3.new(3.2, 0.08, 20), Vector3.new(15, 0.08, 61), Palette.Path, Enum.Material.Cobblestone, neighborLanes)

fixtures = makeFolder(MarketVillage.FixturesFolderName, village)
makeStall("TeaStall", Vector3.new(-19, 0, 22), Palette.Vermilion, "TEA & TREATS", Palette.AppleRed)
makeStall("FlowerStall", Vector3.new(19, 0, 22), Palette.Lantern, "FLOWER CART", Palette.Lantern)
makeStall("RiceStall", Vector3.new(-19, 0, 40), Palette.Leaf, "RICE SHOP", Palette.Leaf)
makeStall("LanternStall", Vector3.new(19, 0, 40), Palette.Indigo, "LANTERN SHOP", Palette.Paper)

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
	makeBillboard(pad, "PlotLabel", "COMING SOON", Palette.Ink, UDim2.fromOffset(88, 22), Vector3.new(0, 1.15, 0))
	for corner = -1, 1, 2 do
		makePart("PlotPostX", Vector3.new(0.18, 2.1, 0.18), data.Position + Vector3.new(corner * 5.3, 1.05, -6), Palette.WoodDark, Enum.Material.Wood, plot, nil, true)
		makePart("PlotPostZ", Vector3.new(0.18, 2.1, 0.18), data.Position + Vector3.new(corner * 5.3, 1.05, 6), Palette.WoodDark, Enum.Material.Wood, plot, nil, true)
	end
end

local stewardshipDisplay = makeFolder(MarketVillage.StewardshipDisplayName, village)
stewardshipDisplay:SetAttribute("Purpose", "Reserved; visible care board removed for gameplay clarity")

local anchor = Instance.new("Model")
anchor.Name = MarketVillage.PeepilabuAnchorName
anchor:SetAttribute("Owner", OWNER)
anchor:SetAttribute("Role", "Owner and future quest anchor")
anchor:SetAttribute("InteractionEnabled", false)
anchor:SetAttribute("BlocksGameplay", false)
anchor:SetAttribute("QuestSystem", "Reserved; no active quest logic")
anchor.Parent = village

local importedAssets = ServerStorage:FindFirstChild("PipilabuImportedAssets")
local importedOwner = importedAssets and importedAssets:FindFirstChild("OwnerShibaV1")
if importedOwner
	and importedOwner:IsA("Model")
	and importedOwner:GetAttribute("ApprovedForPresentation") == true
then
	local ownerVisual = importedOwner:Clone()
	ownerVisual.Name = "OwnerShibaVisual"
	ownerVisual:SetAttribute("PresentationRole", "Peepilabu owner prototype")
	ownerVisual:SetAttribute("InteractionEnabled", false)
	ownerVisual.Parent = anchor
	for _, descendant in ownerVisual:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Material = Enum.Material.SmoothPlastic
			if descendant.Name == "RootPart" then
				descendant.Transparency = 1
			elseif string.find(descendant.Name, "EyeGlint", 1, true) then
				descendant.Color = Palette.Paper
			elseif string.find(descendant.Name, "Eye", 1, true)
				or descendant.Name == "Nose"
				or descendant.Name == "Mouth"
			then
				descendant.Color = Palette.Ink
			elseif string.find(descendant.Name, "Cheek", 1, true)
				or string.find(descendant.Name, "Muzzle", 1, true)
				or string.find(descendant.Name, "ChestPatch", 1, true)
				or string.find(descendant.Name, "Hand", 1, true)
				or string.find(descendant.Name, "Foot", 1, true)
				or descendant.Name == "Tail_Tip"
			then
				descendant.Color = Palette.Muzzle
			else
				descendant.Color = Palette.DogeCoat
			end
		end
	end
	ownerVisual:PivotTo(CFrame.new(-3.5, 0.5, -6) * CFrame.Angles(0, math.rad(180), 0))
	anchor.PrimaryPart = ownerVisual.PrimaryPart
else
	local anchorRoot = makePart("Root", Vector3.new(1, 1, 1), Vector3.new(-3.5, 0.5, -6), Palette.DogeCoat, Enum.Material.SmoothPlastic, anchor, 1)
	anchor.PrimaryPart = anchorRoot
	anchor:SetAttribute("VisualStatus", "Awaiting approved character model")
end

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
