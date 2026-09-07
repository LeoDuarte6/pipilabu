--!strict

-- Studio-only interaction laboratory. These objects deliberately do not own
-- inventory, scoring, orders, or the production apple loop. They exist to let
-- Leo and Jon compare physical response before one mechanic is promoted.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

type PhysicsLabConfig = {
	Enabled: boolean,
	StudioOnly: boolean?,
	OriginX: number,
	OriginY: number,
	OriginZ: number,
}

local PhysicsLabService = {}
local started = false
local LAB_NAME = "PipiLabuPhysicsLab"
local OWNER = "Jon and Leo Development"

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	anchored: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Anchored = anchored
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part:SetAttribute("Owner", OWNER)
	part:SetAttribute("PhysicsLabOnly", true)
	part.Parent = parent
	return part
end

local function addBillboard(adornee: BasePart, text: string, offset: Vector3, width: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = "LabLabel"
	gui.Adornee = adornee
	gui.AlwaysOnTop = false
	gui.MaxDistance = 48
	gui.Size = UDim2.fromOffset(width, 38)
	gui.StudsOffset = offset
	gui.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(43, 38, 34)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Font = Enum.Font.BuilderSansBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(248, 238, 218)
	label.TextSize = 14
	label.TextWrapped = true
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	return label
end

local function addPhysicalDrag(part: BasePart, responsiveness: number, maxForce: number): DragDetector
	local detector = Instance.new("DragDetector")
	detector.Name = "PhysicalDrag"
	detector.DragStyle = Enum.DragDetectorDragStyle.TranslateViewPlane
	-- The old physical response lagged behind the pointer, then stranded the
	-- object on the original view plane when the camera/player moved. Geometric
	-- response is deliberate here: pointer intent wins while held; gravity and
	-- collision resume immediately on release.
	detector.ResponseStyle = Enum.DragDetectorResponseStyle.Geometric
	detector.ApplyAtCenterOfMass = true
	detector.Responsiveness = math.max(responsiveness, 32)
	detector.MaxForce = maxForce
	detector.MaxTorque = maxForce * 0.2
	detector.RunLocally = true
	detector.Parent = part
	part:SetAttribute("LabDraggable", true)
	part:SetAttribute("DragActive", false)
	detector.DragStart:Connect(function()
		part:SetAttribute("DragActive", true)
	end)
	detector.DragEnd:Connect(function()
		part:SetAttribute("DragActive", false)
	end)
	return detector
end

local function makeApple(parent: Instance, name: string, position: Vector3, color: Color3): Part
	local apple = makePart(parent, name, Vector3.new(1.4, 1.25, 1.4), position, color, Enum.Material.SmoothPlastic, false)
	apple.Shape = Enum.PartType.Ball
	apple.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.45, 0.35, 1, 1)
	apple:SetAttribute("LabRole", "JourneyApple")
	apple:SetAttribute("JourneyState", "AttachedDirty")
	apple:SetAttribute("CleanProgress", 0)

	local stem = makePart(parent, name .. "Stem", Vector3.new(0.16, 0.48, 0.16), position + Vector3.new(0, 0.78, 0), Color3.fromRGB(83, 57, 39), Enum.Material.Wood, false)
	stem.CanCollide = false
	stem.CanTouch = false
	stem.CanQuery = false
	stem.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = apple
	weld.Part1 = stem
	weld.Parent = stem
	return apple
end

local function makeBubble(parent: Instance, position: Vector3)
	local bubble = Instance.new("Part")
	bubble.Name = "WashBubble"
	bubble.Shape = Enum.PartType.Ball
	bubble.Size = Vector3.new(0.16, 0.16, 0.16)
	bubble.Position = position
	bubble.Anchored = false
	bubble.CanCollide = false
	bubble.CanTouch = false
	bubble.CanQuery = false
	bubble.Material = Enum.Material.Glass
	bubble.Color = Color3.fromRGB(220, 245, 250)
	bubble.Transparency = 0.35
	bubble.AssemblyLinearVelocity = Vector3.new(math.random(-2, 2) * 0.15, 1.5, math.random(-2, 2) * 0.15)
	bubble.Parent = parent
	Debris:AddItem(bubble, 0.7)
end

local function buildLab(config: PhysicsLabConfig): Folder
	local previous = Workspace:FindFirstChild(LAB_NAME)
	if previous then
		previous:Destroy()
	end

	local origin = Vector3.new(config.OriginX, config.OriginY, config.OriginZ)
	local lab = Instance.new("Folder")
	lab.Name = LAB_NAME
	lab:SetAttribute("Owner", OWNER)
	lab:SetAttribute("PrototypeOnly", true)
	lab:SetAttribute("GameplayAuthority", "None")
	lab:SetAttribute("Instruction", "Drag objects with mouse, touch, or gamepad")
	lab.Parent = Workspace

	local interactionEvent = Instance.new("RemoteEvent")
	interactionEvent.Name = "PhysicsLabEvent"
	interactionEvent.Parent = lab

	local wood = Color3.fromRGB(112, 76, 52)
	local darkWood = Color3.fromRGB(67, 47, 36)
	local ruby = Color3.fromRGB(202, 52, 44)

	makePart(lab, "LabTableTop", Vector3.new(15, 0.7, 8), origin + Vector3.new(0, 2.35, 0), wood, Enum.Material.WoodPlanks, true)
	for _, offset in {
		Vector3.new(-6.6, 1.05, -3.1),
		Vector3.new(6.6, 1.05, -3.1),
		Vector3.new(-6.6, 1.05, 3.1),
		Vector3.new(6.6, 1.05, 3.1),
	} do
		makePart(lab, "LabTableLeg", Vector3.new(0.55, 2.1, 0.55), origin + offset, darkWood, Enum.Material.WoodPlanks, true)
	end

	-- Station A: the accepted pluck-first hypothesis. The spring provides
	-- immediate tension and retained wobble; only a bounded extension detaches.
	local branch = makePart(lab, "SpringBranch", Vector3.new(4.2, 0.42, 0.42), origin + Vector3.new(-4.2, 4.75, 0.5), darkWood, Enum.Material.Wood, true)
	branch.CFrame *= CFrame.Angles(0, 0, math.rad(-8))
	local branchAttachment = Instance.new("Attachment")
	branchAttachment.Name = "StemAnchor"
	branchAttachment.Position = Vector3.new(1.9, -0.15, 0)
	branchAttachment.Parent = branch

	local branchApple = makeApple(lab, "JourneyApple", origin + Vector3.new(-2.25, 3.35, 0.5), ruby)
	branchApple.Anchored = true
	branchApple:SetAttribute("ClientControlledDrag", true)
	branchApple:SetAttribute("ClientDragMode", "PluckSpring")
	branchApple:SetAttribute("PluckRestPosition", branchApple.Position)
	branchApple:SetAttribute("PluckTravelThreshold", 3.4)
	branchApple:SetAttribute("PluckMaxTravel", 2.15)
	branchApple:SetAttribute("StemTension", 0)
	branchApple:SetAttribute("Plucked", false)
	local dirtFlecks: { BasePart } = {}
	for index, offset in {
		Vector3.new(0.42, 0.2, -0.52),
		Vector3.new(-0.38, 0.33, -0.5),
		Vector3.new(0.12, -0.35, -0.62),
		Vector3.new(0.48, -0.22, 0.28),
		Vector3.new(-0.48, -0.18, 0.2),
	} do
		local fleck = makePart(lab, string.format("JourneyDirt_%02d", index), Vector3.new(0.2, 0.12, 0.08), branchApple.Position + offset, Color3.fromRGB(89, 61, 39), Enum.Material.Ground, false)
		fleck.CanCollide = false
		fleck.CanTouch = false
		fleck.CanQuery = false
		fleck.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = branchApple
		weld.Part1 = fleck
		weld.Parent = fleck
		table.insert(dirtFlecks, fleck)
	end
	local appleAttachment = Instance.new("Attachment")
	appleAttachment.Name = "StemAttachment"
	appleAttachment.Position = Vector3.new(0, 0.6, 0)
	appleAttachment.Parent = branchApple

	local spring = Instance.new("SpringConstraint")
	spring.Name = "StemSpring"
	spring.Attachment0 = branchAttachment
	spring.Attachment1 = appleAttachment
	spring.FreeLength = 1.15
	spring.Stiffness = 34
	spring.Damping = 3.5
	spring.MaxForce = 420
	spring.Visible = false
	-- The client owns the attached apple pose exactly under the pointer. The
	-- constraint remains visual metadata until the authoritative pop, avoiding
	-- a second solver fighting the direct manipulation path.
	spring.Enabled = false
	spring.Parent = branchApple

	local stemBeam = Instance.new("Beam")
	stemBeam.Name = "StemBeam"
	stemBeam.Attachment0 = branchAttachment
	stemBeam.Attachment1 = appleAttachment
	stemBeam.Color = ColorSequence.new(Color3.fromRGB(83, 57, 39))
	stemBeam.Width0 = 0.12
	stemBeam.Width1 = 0.09
	stemBeam.FaceCamera = true
	stemBeam.Parent = branchApple

	local branchDrag = addPhysicalDrag(branchApple, 8, 6500)
	branchDrag.Enabled = false
	local pluckStatus = addBillboard(branch, "A  |  GRAB APPLE • PULL", Vector3.new(0, 0.65, 0), 190)
	pluckStatus.Parent.Name = "PluckStatus"

	local plucked = false
	interactionEvent.OnServerEvent:Connect(function(player, action: unknown, target: unknown, reportedTension: unknown)
		if action ~= "Pluck" or target ~= branchApple or plucked then
			return
		end
		if type(reportedTension) ~= "number" or reportedTension < 1 or reportedTension > 1.25 then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or (root.Position - branchApple.Position).Magnitude > 18 then
			return
		end

		plucked = true
		branchApple:SetAttribute("Plucked", true)
		branchApple:SetAttribute("JourneyState", "PluckedDirty")
		branchApple:SetAttribute("PluckSerial", (branchApple:GetAttribute("PluckSerial") or 0) + 1)
		lab:SetAttribute("PluckSerial", (lab:GetAttribute("PluckSerial") or 0) + 1)
		if spring.Parent then
			spring:Destroy()
		end
		if stemBeam.Parent then
			stemBeam:Destroy()
		end
		branchApple.Anchored = false
		branchApple.AssemblyLinearVelocity = Vector3.new(0, 2.2, -1.4)
		branchApple.AssemblyAngularVelocity = Vector3.new(0, 2.8, -3.6)
		pluckStatus.Text = "A  |  POP! • RESET TO PLUCK AGAIN"
	end)

	-- Station B: the server owns wash progress and soap state. A client-side
	-- spring grid gives the water a responsive surface without pretending that
	-- Roblox's solid-part solver is a full fluid simulator.
	local basin = Instance.new("Model")
	basin.Name = "WashBasin"
	basin:SetAttribute("Hollow", true)
	basin:SetAttribute("WaterDepthStuds", 0.95)
	basin.Parent = lab
	local basinCenter = origin + Vector3.new(3.5, 0, 0.7)
	local basinFloor = makePart(basin, "BasinFloor", Vector3.new(4.5, 0.25, 3.3), basinCenter + Vector3.new(0, 2.95, 0), Color3.fromRGB(123, 135, 137), Enum.Material.Metal, true)
	makePart(basin, "BasinWallLeft", Vector3.new(0.28, 1.45, 3.3), basinCenter + Vector3.new(-2.11, 3.68, 0), Color3.fromRGB(123, 135, 137), Enum.Material.Metal, true)
	makePart(basin, "BasinWallRight", Vector3.new(0.28, 1.45, 3.3), basinCenter + Vector3.new(2.11, 3.68, 0), Color3.fromRGB(123, 135, 137), Enum.Material.Metal, true)
	makePart(basin, "BasinWallFront", Vector3.new(3.95, 1.45, 0.28), basinCenter + Vector3.new(0, 3.68, -1.51), Color3.fromRGB(123, 135, 137), Enum.Material.Metal, true)
	makePart(basin, "BasinWallBack", Vector3.new(3.95, 1.45, 0.28), basinCenter + Vector3.new(0, 3.68, 1.51), Color3.fromRGB(123, 135, 137), Enum.Material.Metal, true)
	basin.PrimaryPart = basinFloor

	local water = makePart(lab, "WashWaterSensor", Vector3.new(3.82, 0.95, 2.62), basinCenter + Vector3.new(0, 3.67, 0), Color3.fromRGB(99, 181, 201), Enum.Material.Glass, true)
	water.Transparency = 1
	water.CanCollide = false
	water.CanTouch = false
	water.CanQuery = true
	water:SetAttribute("InteractiveWater", true)
	water:SetAttribute("Soapy", false)
	local waterVolume = makePart(lab, "WashWaterVolume", Vector3.new(3.78, 0.88, 2.58), water.Position, Color3.fromRGB(99, 181, 201), Enum.Material.Glass, true)
	waterVolume.Transparency = 0.58
	waterVolume.CanCollide = false
	waterVolume.CanTouch = false
	waterVolume.CanQuery = false
	waterVolume:SetAttribute("VisibleDepth", true)

	local waterCells = Instance.new("Folder")
	waterCells.Name = "WashWaterSurface"
	waterCells:SetAttribute("GridColumns", 6)
	waterCells:SetAttribute("GridRows", 4)
	waterCells.Parent = lab
	for row = 1, 4 do
		for column = 1, 6 do
			local x = -1.625 + (column - 1) * 0.65
			local z = -1.0125 + (row - 1) * 0.675
			local cell = makePart(
				waterCells,
				string.format("WaterCell_%02d_%02d", row, column),
				Vector3.new(0.67, 0.12, 0.7),
				water.Position + Vector3.new(x, 0.48, z),
				Color3.fromRGB(99, 181, 201),
				Enum.Material.Glass,
				true
			)
			cell.Transparency = 0.24
			cell.CanCollide = false
			cell.CanTouch = false
			cell.CanQuery = false
			cell:SetAttribute("WaterRow", row)
			cell:SetAttribute("WaterColumn", column)
			cell:SetAttribute("BaseCFrame", cell.CFrame)
		end
	end

	local cleanProgress = 0
	local soapyUntil = 0
	addBillboard(basinFloor, "B  |  POUR SOAP + SCRUB", Vector3.new(0, 1.95, 0), 165)

	local soap = makePart(lab, "SoapBottle", Vector3.new(0.72, 1.5, 0.72), origin + Vector3.new(6.2, 4.15, 2.1), Color3.fromRGB(238, 202, 105), Enum.Material.SmoothPlastic, true)
	soap.CFrame *= CFrame.Angles(math.rad(56), 0, math.rad(-12))
	soap.CustomPhysicalProperties = PhysicalProperties.new(0.55, 0.55, 0.2, 1, 1)
	soap:SetAttribute("LabRole", "PourableSoap")
	soap:SetAttribute("ClientControlledDrag", true)
	local soapCap = makePart(lab, "SoapBottleCap", Vector3.new(0.46, 0.3, 0.46), soap.Position + Vector3.new(0, 0.87, 0), Color3.fromRGB(244, 232, 190), Enum.Material.SmoothPlastic, false)
	soapCap.CFrame = soap.CFrame * CFrame.new(0, 0.87, 0)
	soapCap.CanCollide = false
	soapCap.CanTouch = false
	soapCap.CanQuery = false
	soapCap.Massless = true
	soapCap:SetAttribute("ClientDragProxy", "SoapBottle")
	local capWeld = Instance.new("WeldConstraint")
	capWeld.Part0 = soap
	capWeld.Part1 = soapCap
	capWeld.Parent = soapCap
	local nozzle = makePart(lab, "SoapNozzle", Vector3.new(0.18, 0.18, 0.64), soap.Position + Vector3.new(0, 1.03, -0.25), Color3.fromRGB(244, 232, 190), Enum.Material.SmoothPlastic, false)
	nozzle.CFrame = soap.CFrame * CFrame.new(0, 1.03, -0.25)
	nozzle.CanCollide = false
	nozzle.CanTouch = false
	nozzle.CanQuery = false
	nozzle.Massless = true
	nozzle:SetAttribute("ClientDragProxy", "SoapBottle")
	local nozzleWeld = Instance.new("WeldConstraint")
	nozzleWeld.Part0 = soap
	nozzleWeld.Part1 = nozzle
	nozzleWeld.Parent = nozzle
	local soapDrag = addPhysicalDrag(soap, 40, 12000)
	soapDrag.Enabled = false
	local soapAccumulated = 0
	local lastDropAt = 0
	local function setSoapy()
		soapyUntil = os.clock() + 12
		water:SetAttribute("Soapy", true)
		waterCells:SetAttribute("Soapy", true)
		for _, child in waterCells:GetChildren() do
			if child:IsA("BasePart") then
				child.Color = Color3.fromRGB(183, 224, 222)
			end
		end
	end

	RunService.Heartbeat:Connect(function(deltaTime)
		if not lab.Parent or not soap.Parent or not water.Parent then
			return
		end
		local localNozzle = water.CFrame:PointToObjectSpace(nozzle.Position)
		local half = water.Size * 0.5
		local overWater = math.abs(localNozzle.X) <= half.X and math.abs(localNozzle.Z) <= half.Z and localNozzle.Y > -0.2 and localNozzle.Y < 4.5
		local pouring = soap:GetAttribute("DragActive") == true and overWater
		soap:SetAttribute("Pouring", pouring)
		water:SetAttribute("SoapPouring", pouring)
		if pouring then
			soapAccumulated = math.min(1, soapAccumulated + deltaTime * 0.85)
			water:SetAttribute("SoapFill", soapAccumulated)
			if os.clock() - lastDropAt >= 0.065 then
				lastDropAt = os.clock()
				local drop = Instance.new("Part")
				drop.Name = "SoapDrop"
				drop.Shape = Enum.PartType.Ball
				drop.Size = Vector3.new(0.14, 0.14, 0.14)
				drop.Position = nozzle.Position
				drop.Color = Color3.fromRGB(247, 236, 194)
				drop.Material = Enum.Material.Glass
				drop.Transparency = 0.12
				drop.CanCollide = false
				drop.CanTouch = false
				drop.CanQuery = false
				drop.AssemblyLinearVelocity = Vector3.new(0, -5.5, 0)
				drop.Parent = lab
				Debris:AddItem(drop, 0.7)
			end
			if soapAccumulated >= 0.35 then
				setSoapy()
			end
		elseif water:GetAttribute("Soapy") == true and os.clock() >= soapyUntil then
			soapAccumulated = 0
			water:SetAttribute("SoapFill", 0)
			water:SetAttribute("Soapy", false)
			waterCells:SetAttribute("Soapy", false)
			for _, child in waterCells:GetChildren() do
				if child:IsA("BasePart") then
					child.Color = Color3.fromRGB(99, 181, 201)
				end
			end
		end
	end)

	-- Station C: geometric rotation around an explicit model pivot. The old
	-- physical hinge fought the detector and often appeared completely stuck.
	local crate = Instance.new("Model")
	crate.Name = "PhysicsCrate"
	crate:SetAttribute("Hollow", true)
	crate:SetAttribute("LockingGrid", true)
	crate.Parent = lab
	local crateCenter = origin + Vector3.new(0, 0, -2.15)
	local crateBase = makePart(crate, "CrateFloor", Vector3.new(3.7, 0.25, 2.5), crateCenter + Vector3.new(0, 2.95, 0), darkWood, Enum.Material.WoodPlanks, true)
	makePart(crate, "CrateWallLeft", Vector3.new(0.25, 1.75, 2.5), crateCenter + Vector3.new(-1.72, 3.7, 0), darkWood, Enum.Material.WoodPlanks, true)
	makePart(crate, "CrateWallRight", Vector3.new(0.25, 1.75, 2.5), crateCenter + Vector3.new(1.72, 3.7, 0), darkWood, Enum.Material.WoodPlanks, true)
	makePart(crate, "CrateWallFront", Vector3.new(3.2, 1.75, 0.25), crateCenter + Vector3.new(0, 3.7, -1.12), darkWood, Enum.Material.WoodPlanks, true)
	makePart(crate, "CrateWallBack", Vector3.new(3.2, 1.75, 0.25), crateCenter + Vector3.new(0, 3.7, 1.12), darkWood, Enum.Material.WoodPlanks, true)
	crate.PrimaryPart = crateBase
	local crateSensor = makePart(crate, "CrateInteriorSensor", Vector3.new(3.1, 1.45, 1.9), crateCenter + Vector3.new(0, 3.7, 0), Color3.fromRGB(222, 190, 116), Enum.Material.Neon, true)
	crateSensor.Transparency = 1
	crateSensor.CanCollide = false
	crateSensor.CanTouch = false
	crateSensor.CanQuery = true
	crateSensor:SetAttribute("InteriorSensor", true)
	local crateSlots = Instance.new("Folder")
	crateSlots.Name = "CrateGridSlots"
	crateSlots.Parent = crate
	local slotParts: { BasePart } = {}
	for row = 1, 2 do
		for column = 1, 3 do
			local slotIndex = (row - 1) * 3 + column
			local slot = makePart(
				crateSlots,
				string.format("CrateSlot_%02d", slotIndex),
				Vector3.new(0.58, 0.06, 0.58),
				crateCenter + Vector3.new((column - 2) * 0.96, 3.64, (row - 1.5) * 0.82),
				Color3.fromRGB(222, 190, 116),
				Enum.Material.Neon,
				true
			)
			slot.Transparency = 0.72
			slot.CanCollide = false
			slot.CanTouch = false
			slot.CanQuery = false
			slot:SetAttribute("Occupied", false)
			table.insert(slotParts, slot)
		end
	end
	local lidAssembly = Instance.new("Model")
	lidAssembly.Name = "PhysicsCrateLidAssembly"
	lidAssembly.Parent = lab
	local lidPivot = makePart(lidAssembly, "LidPivot", Vector3.new(0.18, 0.18, 0.18), crateCenter + Vector3.new(0, 4.68, 1.22), wood, Enum.Material.WoodPlanks, true)
	lidPivot.Transparency = 1
	lidPivot.CanCollide = false
	lidPivot.CanTouch = false
	lidPivot.CanQuery = false
	local crateLid = makePart(lidAssembly, "PhysicsCrateLid", Vector3.new(3.8, 0.25, 2.6), crateCenter + Vector3.new(0, 4.68, 0), wood, Enum.Material.WoodPlanks, false)
	local lidWeld = Instance.new("WeldConstraint")
	lidWeld.Part0 = lidPivot
	lidWeld.Part1 = crateLid
	lidWeld.Parent = crateLid
	lidAssembly.PrimaryPart = lidPivot
	local lidDrag = Instance.new("DragDetector")
	lidDrag.Name = "LidDrag"
	lidDrag.DragStyle = Enum.DragDetectorDragStyle.RotateAxis
	lidDrag.ResponseStyle = Enum.DragDetectorResponseStyle.Geometric
	lidDrag.Axis = Vector3.xAxis
	lidDrag.ReferenceInstance = crateBase
	lidDrag.MinDragAngle = math.rad(-4)
	lidDrag.MaxDragAngle = math.rad(105)
	lidDrag.Responsiveness = 40
	lidDrag.MaxForce = 12000
	lidDrag.MaxTorque = 12000
	lidDrag.RunLocally = true
	-- Rotation is computed from pointer delta around the model's explicit pivot
	-- by PhysicsLabDrag; the detector remains as authored metadata only.
	lidDrag.Enabled = false
	lidDrag.Parent = lidAssembly
	lidAssembly:SetAttribute("LabDraggable", true)
	lidAssembly:SetAttribute("ClientControlledDrag", true)
	lidAssembly:SetAttribute("ClientDragMode", "RotateHingeX")
	lidAssembly:SetAttribute("DragActive", false)
	lidDrag.DragStart:Connect(function()
		lidAssembly:SetAttribute("DragActive", true)
	end)
	lidDrag.DragEnd:Connect(function()
		lidAssembly:SetAttribute("DragActive", false)
	end)
	addBillboard(crateBase, "C  |  LIFT LID", Vector3.new(0, 0.9, 0), 105)

	interactionEvent.OnServerEvent:Connect(function(player, action: unknown, target: unknown, payload: unknown)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or (root.Position - branchApple.Position).Magnitude > 25 then
			return
		end
		if action == "SoapPour" and target == soap then
			if type(payload) == "number" and payload >= 0.35 and payload <= 1.1 then
				setSoapy()
			end
			return
		end
		if action == "WashProgress" and target == branchApple then
			local state = branchApple:GetAttribute("JourneyState")
			if (state == "PluckedDirty" or state == "WashingDirty") and water:GetAttribute("Soapy") == true and type(payload) == "number" then
				cleanProgress = math.clamp(math.max(cleanProgress, payload), 0, 1)
				branchApple:SetAttribute("CleanProgress", cleanProgress)
				branchApple:SetAttribute("JourneyState", if cleanProgress >= 1 then "Clean" else "WashingDirty")
				for _, fleck in dirtFlecks do
					fleck.Transparency = cleanProgress
				end
				if cleanProgress >= 1 then
					lab:SetAttribute("WashSerial", (lab:GetAttribute("WashSerial") or 0) + 1)
				end
			end
			return
		end
		if action == "Crate" and target == branchApple and branchApple:GetAttribute("JourneyState") == "Clean" and typeof(payload) == "Vector3" then
			local localDrop = crateSensor.CFrame:PointToObjectSpace(payload)
			local half = crateSensor.Size * 0.5
			if math.abs(localDrop.X) > half.X or math.abs(localDrop.Y) > half.Y + 0.7 or math.abs(localDrop.Z) > half.Z then
				return
			end
			local slot: BasePart? = nil
			for _, candidate in slotParts do
				if candidate:GetAttribute("Occupied") ~= true then
					slot = candidate
					break
				end
			end
			if not slot then
				return
			end
			slot:SetAttribute("Occupied", true)
			branchApple:SetAttribute("JourneyState", "Crating")
			branchApple.Anchored = false
			branchApple.CanCollide = true
			branchApple.CFrame = CFrame.new(payload) * branchApple.CFrame.Rotation
			branchApple.AssemblyLinearVelocity = Vector3.new(0, -1.6, 0)
			branchApple.AssemblyAngularVelocity = Vector3.new(0, 1.2, 0)
			task.delay(0.38, function()
				if not branchApple.Parent or not slot or not slot.Parent then
					return
				end
				branchApple.AssemblyLinearVelocity = Vector3.zero
				branchApple.AssemblyAngularVelocity = Vector3.zero
				branchApple.CFrame = slot.CFrame + Vector3.new(0, branchApple.Size.Y * 0.5, 0)
				branchApple.Anchored = true
				branchApple:SetAttribute("JourneyState", "CratedLocked")
				branchApple:SetAttribute("CrateSlotIndex", table.find(slotParts, slot) or 0)
				lab:SetAttribute("CrateSerial", (lab:GetAttribute("CrateSerial") or 0) + 1)
			end)
		end
	end)

	local resetButton = makePart(lab, "ResetLab", Vector3.new(1.5, 0.45, 1.5), origin + Vector3.new(0, 2.95, 2.6), Color3.fromRGB(176, 66, 54), Enum.Material.SmoothPlastic, true)
	addBillboard(resetButton, "RESET", Vector3.new(0, 0.65, 0), 70)
	local resetClick = Instance.new("ClickDetector")
	resetClick.MaxActivationDistance = 18
	resetClick.Parent = resetButton
	resetClick.MouseClick:Connect(function()
		buildLab(config)
	end)

	lab:SetAttribute("Ready", true)
	lab:SetAttribute("Stations", 3)
	return lab
end

function PhysicsLabService.Start(config: PhysicsLabConfig?): string
	if started then
		return "AlreadyStarted"
	end
	started = true
	if not config or not config.Enabled then
		return "Disabled"
	end
	if config.StudioOnly == true and not RunService:IsStudio() then
		return "StudioOnly"
	end
	buildLab(config)
	return "Ready"
end

return PhysicsLabService
