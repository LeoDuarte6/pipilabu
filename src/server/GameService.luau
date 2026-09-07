--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local AppleCatalog = require(projectRoot:WaitForChild("AppleCatalog"))
local Copy = require(projectRoot:WaitForChild("Copy"))
local CustomerPresentationService = require(script.Parent:WaitForChild("CustomerPresentationService"))

type ShopConfig = {
	StartingQueueSize: number,
	MaximumQueueSize: number,
	FirstShiftPopulationCap: number,
	QueueSpacingStuds: number,
	ServeReward: number,
	CustomerRespawnDelay: number,
	CustomerMoveTime: number,
	ServeCelebrationTime: number,
	PromptHoldDuration: number,
	HandoffDuration: number,
	HandoffArcHeight: number,
	HandoffSpinDegrees: number,
	HandoffSettleTime: number,
	WrongAppleOutDuration: number,
	WrongAppleReturnDuration: number,
	WrongAppleArcHeight: number,
	EnjoymentApproachDuration: number,
	EnjoymentBiteDuration: number,
	PickupPromptDistance: number,
	ServePromptDistance: number,
}

type ShiftConfig = {
	DurationSeconds: number,
	TargetServed: number,
	MaximumMissed: number,
	CustomerPatienceSeconds: number,
	TickRateSeconds: number,
	PayoutBase: number,
	PayoutClearBonus: number,
	PayoutPosition: { X: number, Y: number, Z: number },
}

type CustomerAction = "Idle" | "Receive" | "Hold" | "Happy" | "Run" | "TurnLeave"
type CustomerExitAction = "Run" | "TurnLeave"

type CustomerPresentationConfig = {
	Enabled: boolean,
	AllowUnapprovedCandidateInStudio: boolean?,
	AllowStudioKeyframeSequences: boolean?,
	RequireInitialAnimation: boolean?,
	InitialAnimation: CustomerAction?,
	ExitAnimation: CustomerExitAction?,
}

type ProjectConfig = {
	ProjectName: string,
	DevelopmentVersion: string,
	Shop: ShopConfig,
	Shift: ShiftConfig,
	CustomerPresentation: CustomerPresentationConfig?,
}

local GameService = {}

-- Server-only extension seam for future reputation, economy, and disruption systems.
-- Consumers can observe named lifecycle events without owning the core shift state.
local lifecycleEvent = Instance.new("BindableEvent")
lifecycleEvent.Name = "ShopLifecycle"
lifecycleEvent.Parent = script
GameService.Lifecycle = lifecycleEvent.Event
GameService.LifecycleNames = table.freeze({
	ShiftStarted = "ShiftStarted",
	CustomerServed = "CustomerServed",
	CustomerMissed = "CustomerMissed",
	ShiftEnded = "ShiftEnded",
})

local started = false
local customerSerial = 0
local queue: { Model } = {}
local serving = false
local shiftState = "Waiting"
local shiftOwner: Player? = nil
local shiftEndsAt = 0
local shiftTimeRemaining = 0
local shiftServed = 0
local shiftMissed = 0
local shiftCustomerSpawned = 0
local shiftPayoutAmount = 0
local shiftPayoutReady = false
local shiftPayoutCollected = false
local runSerial = 0
local frontCustomer: Model? = nil
local frontPatienceEndsAt = 0
local frontPatienceRemaining = 0

local shop: Folder
local customersFolder: Folder
local queueSpots: Folder
local customerSpawn: BasePart
local customerExit: BasePart
local shopConfig: ShopConfig
local shiftConfig: ShiftConfig
local feedbackEvent: RemoteEvent
local controlEvent: RemoteEvent
local applePrompts: { ProximityPrompt } = {}
local shiftPayoutModel: Model? = nil

local DOGE_COLORS = {
	Color3.fromRGB(222, 177, 112),
	Color3.fromRGB(201, 145, 78),
	Color3.fromRGB(238, 205, 151),
	Color3.fromRGB(180, 121, 66),
}

local function getOrCreateValue(parent: Instance, className: string, name: string): ValueBase
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing :: ValueBase
	end

	local value = Instance.new(className)
	value.Name = name
	value.Parent = parent
	return value :: ValueBase
end

local function applyShiftAttributes(player: Player)
	player:SetAttribute("ShiftState", shiftState)
	player:SetAttribute("ShiftTimeRemaining", shiftTimeRemaining)
	player:SetAttribute("ShiftTarget", shiftConfig.TargetServed)
	player:SetAttribute("ShiftServed", shiftServed)
	player:SetAttribute("ShiftMissed", shiftMissed)
	player:SetAttribute("ShiftPopulationCap", shopConfig.FirstShiftPopulationCap)
	player:SetAttribute("ShiftPopulationSpawned", shiftCustomerSpawned)
	player:SetAttribute("ShiftMaximumMissed", shiftConfig.MaximumMissed)
	player:SetAttribute("FrontPatienceRemaining", frontPatienceRemaining)
	player:SetAttribute("ShiftPayoutAmount", shiftPayoutAmount)
	player:SetAttribute("ShiftPayoutReady", shiftPayoutReady and player == shiftOwner)
	player:SetAttribute("ShiftPayoutCollected", shiftPayoutCollected and player == shiftOwner)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	player:SetAttribute("ShiftCashBalance", if coins and coins:IsA("IntValue") then coins.Value else 0)
end

local function publishShiftAttributes()
	for _, player in Players:GetPlayers() do
		applyShiftAttributes(player)
	end
end

local function emitLifecycle(eventName: string, player: Player?)
	lifecycleEvent:Fire(eventName, table.freeze({
		ownerUserId = if shiftOwner then shiftOwner.UserId else 0,
		playerUserId = if player then player.UserId else 0,
		state = shiftState,
		served = shiftServed,
		missed = shiftMissed,
		timeRemaining = shiftTimeRemaining,
	}))
end

local function waitingMessage(): string
	return string.format(Copy.Messages.Waiting, shiftConfig.TargetServed, shiftConfig.MaximumMissed)
end

local function bumpPlayerSerial(player: Player, attributeName: string): number
	local nextSerial = (tonumber(player:GetAttribute(attributeName)) or 0) + 1
	player:SetAttribute(attributeName, nextSerial)
	return nextSerial
end

local function configurePlayer(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coins = getOrCreateValue(leaderstats, "IntValue", "Coins") :: IntValue
	local served = getOrCreateValue(leaderstats, "IntValue", "Served") :: IntValue
	served.Value = 0

	player:SetAttribute("HasApple", false)
	player:SetAttribute("HeldAppleType", "")
	player:SetAttribute("FrontReadySerial", 0)
	player:SetAttribute("FrontReadyOrderType", "")
	player:SetAttribute("HandoffSerial", 0)
	player:SetAttribute("HandoffCompletedSerial", 0)
	player:SetAttribute("ImmediateNextPickupSerial", 0)
	player:SetAttribute("ImmediateNextPickupAppleType", "")
	player:SetAttribute("HandoffInFlight", false)
	player:SetAttribute("LastHandoffAppleType", "")
	player:SetAttribute("WrongAppleInFlight", false)
	player:SetAttribute("WrongAppleSerial", 0)
	player:SetAttribute("LastWrongAppleType", "")
	player:SetAttribute("OwnerDialogueSerial", 0)
	player:SetAttribute("OwnerDialogueText", "")
	player:SetAttribute("OwnerTaskText", "")
	player:SetAttribute("HasCashInHand", false)
	player:SetAttribute("ShiftPayoutSerial", 0)
	player:SetAttribute("ShopMessage", if shiftState == "Waiting" then waitingMessage() else Copy.Messages.ShiftInProgress)
	player:SetAttribute("QueueSize", #queue)
	applyShiftAttributes(player)
end

local function removeHeldApple(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local heldApple = character:FindFirstChild("HeldApple")
	if heldApple then
		heldApple:Destroy()
	end
end

local function showHeldApple(player: Player)
	local character = player.Character
	if not character then
		return
	end

	removeHeldApple(player)

	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or character:FindFirstChild("HumanoidRootPart")
	if not hand or not hand:IsA("BasePart") then
		return
	end

	local appleDefinition = AppleCatalog.get(player:GetAttribute("HeldAppleType") :: string?)
	local apple = Instance.new("Part")
	apple.Name = "HeldApple"
	apple.Shape = Enum.PartType.Ball
	apple.Size = Vector3.new(1.3, 1.3, 1.3)
	apple.Color = appleDefinition.Color
	apple:SetAttribute("AppleType", appleDefinition.Id)
	apple.Material = Enum.Material.SmoothPlastic
	apple.Reflectance = 0.04
	apple.CanCollide = false
	apple.CanTouch = false
	apple.CanQuery = false
	apple.Massless = true
	local handOffset = if hand.Name == "RightHand" then CFrame.new(0, -0.15, -0.78) else CFrame.new(0, -0.48, -0.82)
	apple.CFrame = hand.CFrame * handOffset
	apple.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = apple
	weld.Parent = apple

	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Size = Vector3.new(0.16, 0.4, 0.16)
	stem.Color = Color3.fromRGB(82, 53, 31)
	stem.Material = Enum.Material.Wood
	stem.CanCollide = false
	stem.CanTouch = false
	stem.CanQuery = false
	stem.Massless = true
	stem.CFrame = apple.CFrame * CFrame.new(0, 0.76, 0)
	stem.Parent = apple

	local stemWeld = Instance.new("WeldConstraint")
	stemWeld.Part0 = apple
	stemWeld.Part1 = stem
	stemWeld.Parent = stem

	local leaf = Instance.new("Part")
	leaf.Name = "Leaf"
	leaf.Size = Vector3.new(0.38, 0.08, 0.24)
	leaf.Color = Color3.fromRGB(62, 112, 62)
	leaf.Material = Enum.Material.SmoothPlastic
	leaf.CanCollide = false
	leaf.CanTouch = false
	leaf.CanQuery = false
	leaf.Massless = true
	leaf.CFrame = apple.CFrame * CFrame.new(0.24, 0.66, 0) * CFrame.Angles(0, 0, math.rad(24))
	leaf.Parent = apple

	local leafWeld = Instance.new("WeldConstraint")
	leafWeld.Part0 = apple
	leafWeld.Part1 = leaf
	leafWeld.Parent = leaf

	local highlight = Instance.new("Highlight")
	highlight.Name = "HeldAppleOutline"
	highlight.Adornee = apple
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(255, 225, 207)
	highlight.OutlineTransparency = 0.45
	highlight.Parent = apple
end

local function takeApple(player: Player, appleType: string)
	if shiftState ~= "Active" or shiftOwner ~= player then
		player:SetAttribute("ShopMessage", if shiftState == "Active" then Copy.Messages.ShiftInProgress else waitingMessage())
		return
	end

	local appleDefinition = AppleCatalog.get(appleType)
	if player:GetAttribute("HasApple") == true and player:GetAttribute("HeldAppleType") == appleDefinition.Id then
		player:SetAttribute("ShopMessage", Copy.Messages.PawsFull)
		return
	end
	if player:GetAttribute("HandoffInFlight") == true then
		player:SetAttribute("ImmediateNextPickupAppleType", appleDefinition.Id)
		bumpPlayerSerial(player, "ImmediateNextPickupSerial")
	end

	player:SetAttribute("HasApple", true)
	player:SetAttribute("HeldAppleType", appleDefinition.Id)
	player:SetAttribute(
		"ShopMessage",
		string.format(
			if player.Character and player.Character:FindFirstChild("HeldApple") then Copy.Messages.AppleSwapped else Copy.Messages.AppleReady,
			appleDefinition.DisplayName
		)
	)
	showHeldApple(player)
	feedbackEvent:FireClient(player, "Pickup")
end

local function makePart(name: string, size: Vector3, color: Color3, offset: CFrame, root: BasePart, shape: Enum.PartType?): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CFrame = root.CFrame * offset
	part.Parent = root.Parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part

	return part
end

local function destroyCustomer(customer: Model)
	CustomerPresentationService.Detach(customer)
	if customer.Parent then
		customer:Destroy()
	end
end

local function createCustomer(): Model
	customerSerial += 1

	local model = Instance.new("Model")
	model.Name = string.format("DogeCustomer_%02d", customerSerial)
	model:SetAttribute("QueueNumber", customerSerial)
	local order = AppleCatalog.forCustomer(customerSerial)
	model:SetAttribute("OrderType", order.Id)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 3, 2)
	root.Transparency = 1
	root.Anchored = true
	-- Customers are physical residents, not holograms. The invisible gameplay
	-- root is the single stable collision proxy while the animated render mesh
	-- remains non-colliding.
	root.CanCollide = true
	root.CanTouch = false
	root.CanQuery = true
	root:SetAttribute("ComfortCollisionProxy", true)
	root.CFrame = customerSpawn.CFrame
	root.Parent = model
	model.PrimaryPart = root

	local coat = DOGE_COLORS[((customerSerial - 1) % #DOGE_COLORS) + 1]
	makePart("Body", Vector3.new(2.5, 2.6, 1.8), coat, CFrame.new(0, 0.1, 0), root)
	local head = makePart("Head", Vector3.new(2.2, 2.1, 2.1), coat, CFrame.new(0, 2.15, -0.15), root, Enum.PartType.Ball)
	makePart("Muzzle", Vector3.new(1.3, 0.75, 1), Color3.fromRGB(244, 221, 182), CFrame.new(0, 1.8, -1.05), root)
	makePart("LeftEar", Vector3.new(0.7, 1, 0.5), Color3.fromRGB(106, 70, 44), CFrame.new(-0.7, 3.15, -0.05) * CFrame.Angles(0, 0, math.rad(-18)), root)
	makePart("RightEar", Vector3.new(0.7, 1, 0.5), Color3.fromRGB(106, 70, 44), CFrame.new(0.7, 3.15, -0.05) * CFrame.Angles(0, 0, math.rad(18)), root)
	makePart("LeftEye", Vector3.new(0.24, 0.34, 0.18), Color3.fromRGB(34, 27, 22), CFrame.new(-0.43, 2.43, -1.03), root, Enum.PartType.Ball)
	makePart("RightEye", Vector3.new(0.24, 0.34, 0.18), Color3.fromRGB(34, 27, 22), CFrame.new(0.43, 2.43, -1.03), root, Enum.PartType.Ball)
	makePart("Nose", Vector3.new(0.38, 0.3, 0.3), Color3.fromRGB(32, 25, 22), CFrame.new(0, 1.98, -1.58), root, Enum.PartType.Ball)
	makePart("LeftFoot", Vector3.new(0.9, 0.65, 1.2), Color3.fromRGB(244, 221, 182), CFrame.new(-0.65, -1.45, -0.2), root)
	makePart("RightFoot", Vector3.new(0.9, 0.65, 1.2), Color3.fromRGB(244, 221, 182), CFrame.new(0.65, -1.45, -0.2), root)
	makePart("Tail", Vector3.new(0.45, 0.45, 1.4), coat, CFrame.new(0.85, 0.35, 1) * CFrame.Angles(math.rad(-28), 0, math.rad(-25)), root)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ServePrompt"
	prompt.ActionText = Copy.Prompts.GiveAppleAction
	prompt.ObjectText = Copy.Prompts.WaitingDoge
	prompt.HoldDuration = shopConfig.PromptHoldDuration
	prompt.MaxActivationDistance = shopConfig.ServePromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Enabled = false
	prompt.Parent = head

	local orderBillboard = Instance.new("BillboardGui")
	orderBillboard.Name = "OrderBillboard"
	orderBillboard.Adornee = head
	orderBillboard.AlwaysOnTop = false
	orderBillboard.Enabled = false
	orderBillboard.MaxDistance = 32
	orderBillboard.Size = UDim2.fromOffset(78, 78)
	orderBillboard.StudsOffset = Vector3.new(0, 1.3, 0)
	orderBillboard.Parent = head

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.BackgroundColor3 = Color3.fromRGB(248, 240, 222)
	card.BackgroundTransparency = 0.02
	card.BorderSizePixel = 0
	card.Size = UDim2.fromScale(1, 1)
	card.Parent = orderBillboard

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(1, 0)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(82, 58, 43)
	cardStroke.Thickness = 2
	cardStroke.Parent = card

	local appleDot = Instance.new("Frame")
	appleDot.Name = "AppleDot"
	appleDot.AnchorPoint = Vector2.new(0.5, 0.5)
	appleDot.BackgroundColor3 = order.Color
	appleDot.BorderSizePixel = 0
	appleDot.Position = UDim2.fromOffset(39, 31)
	appleDot.Size = UDim2.fromOffset(32, 32)
	appleDot.Parent = card

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = appleDot

	local orderText = Instance.new("TextLabel")
	orderText.Name = "OrderText"
	orderText.BackgroundTransparency = 1
	orderText.Font = Enum.Font.BuilderSansBold
	orderText.Position = UDim2.fromOffset(9, 49)
	orderText.Size = UDim2.fromOffset(60, 18)
	orderText.Text = order.ShortName
	orderText.TextColor3 = Color3.fromRGB(75, 44, 29)
	orderText.TextSize = 12
	orderText.Parent = card

	local patienceRing = Instance.new("Frame")
	patienceRing.Name = "PatienceRing"
	patienceRing.BackgroundTransparency = 1
	patienceRing.Position = UDim2.fromOffset(2, 2)
	patienceRing.Size = UDim2.new(1, -4, 1, -4)
	patienceRing.Parent = card

	local patienceCorner = Instance.new("UICorner")
	patienceCorner.CornerRadius = UDim.new(1, 0)
	patienceCorner.Parent = patienceRing

	local patienceStroke = Instance.new("UIStroke")
	patienceStroke.Name = "PatienceStroke"
	patienceStroke.Color = Color3.fromRGB(91, 190, 105)
	patienceStroke.Thickness = 3
	patienceStroke.Transparency = 0.08
	patienceStroke.Parent = patienceRing

	local patienceText = Instance.new("TextLabel")
	patienceText.Name = "PatienceText"
	patienceText.BackgroundTransparency = 1
	patienceText.Font = Enum.Font.BuilderSansBold
	patienceText.AnchorPoint = Vector2.new(1, 0)
	patienceText.Position = UDim2.new(1, 3, 0, -3)
	patienceText.Size = UDim2.fromOffset(25, 18)
	patienceText.BackgroundColor3 = Color3.fromRGB(55, 47, 40)
	patienceText.BackgroundTransparency = 0.08
	patienceText.BorderSizePixel = 0
	patienceText.Text = string.format(Copy.Prompts.Patience, shiftConfig.CustomerPatienceSeconds)
	patienceText.TextColor3 = Color3.fromRGB(255, 255, 255)
	patienceText.TextSize = 11
	patienceText.TextStrokeTransparency = 0.55
	patienceText.ZIndex = 2
	patienceText.Parent = card
	local patienceTextCorner = Instance.new("UICorner")
	patienceTextCorner.CornerRadius = UDim.new(1, 0)
	patienceTextCorner.Parent = patienceText

	model.Parent = customersFolder
	CustomerPresentationService.Attach(model)
	return model
end

local function sortedQueueSpots(): { BasePart }
	local spots: { BasePart } = {}
	for _, child in queueSpots:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(spots, child)
		end
	end
	table.sort(spots, function(a, b)
		return a.Name < b.Name
	end)
	return spots
end

local function tweenCustomer(customer: Model, target: CFrame, onComplete: (() -> ())?)
	local root = customer.PrimaryPart
	if not root then
		return
	end

	local tween = TweenService:Create(root, TweenInfo.new(shopConfig.CustomerMoveTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = target,
	})
	if onComplete then
		tween.Completed:Once(onComplete)
	end
	tween:Play()
end

local function updatePatiencePresentation(customer: Model, remaining: number)
	local ratio = math.clamp(remaining / shiftConfig.CustomerPatienceSeconds, 0, 1)
	local stroke = customer:FindFirstChild("PatienceStroke", true)
	if stroke and stroke:IsA("UIStroke") then
		stroke.Color = if ratio > 0.5
			then Color3.fromRGB(91, 190, 105)
			elseif ratio > 0.25 then Color3.fromRGB(232, 173, 65)
			else Color3.fromRGB(220, 72, 65)
		stroke.Thickness = 2.5 + (1 - ratio) * 2.5
		stroke.Transparency = 0.08 + (1 - ratio) * 0.28
	end

	local patienceText = customer:FindFirstChild("PatienceText", true)
	if patienceText and patienceText:IsA("TextLabel") then
		patienceText.Text = string.format(Copy.Prompts.Patience, math.max(0, math.ceil(remaining)))
	end
end

local function armFrontCustomer()
	local candidate = if shiftState == "Active" and not serving then queue[1] else nil
	if candidate == frontCustomer then
		return
	end

	frontCustomer = candidate
	if candidate then
		if shiftOwner then
			bumpPlayerSerial(shiftOwner, "FrontReadySerial")
			shiftOwner:SetAttribute("FrontReadyOrderType", tostring(candidate:GetAttribute("OrderType") or ""))
		end
		frontPatienceEndsAt = os.clock() + shiftConfig.CustomerPatienceSeconds
		frontPatienceRemaining = shiftConfig.CustomerPatienceSeconds
		updatePatiencePresentation(candidate, shiftConfig.CustomerPatienceSeconds)
	else
		frontPatienceEndsAt = 0
		frontPatienceRemaining = 0
	end
end

local function refreshQueue()
	local spots = sortedQueueSpots()
	for index, customer in queue do
		local spot = spots[index]
		if spot then
			tweenCustomer(customer, spot.CFrame)
		end

		local prompt = customer:FindFirstChild("ServePrompt", true)
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = index == 1 and shiftState == "Active" and shiftOwner ~= nil and not serving
			prompt.ObjectText = if index == 1 then Copy.Prompts.SmallDoge else string.format(Copy.Prompts.WaitingDogeNumbered, index)
		end

		local billboard = customer:FindFirstChild("OrderBillboard", true)
		if billboard and billboard:IsA("BillboardGui") then
			billboard.Enabled = index == 1 and shiftState == "Active"
			local patienceRing = billboard:FindFirstChild("PatienceRing", true)
			if patienceRing and patienceRing:IsA("Frame") then
				patienceRing.Visible = index == 1 and shiftState == "Active" and not serving
			end
			local orderText = billboard:FindFirstChild("OrderText", true)
			if orderText and orderText:IsA("TextLabel") then
				local order = AppleCatalog.get(customer:GetAttribute("OrderType") :: string?)
				orderText.Text = order.ShortName
				orderText.TextColor3 = Color3.fromRGB(75, 44, 29)
			end
			local appleDot = billboard:FindFirstChild("AppleDot", true)
			if appleDot and appleDot:IsA("Frame") then
				appleDot.BackgroundColor3 = AppleCatalog.get(customer:GetAttribute("OrderType") :: string?).Color
			end
		end
	end

	for _, player in Players:GetPlayers() do
		player:SetAttribute("QueueSize", #queue)
	end
	armFrontCustomer()
end

local function awardServe(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local served = leaderstats:FindFirstChild("Served")
	if served and served:IsA("IntValue") then
		served.Value += 1
	end
	shiftServed += 1
	publishShiftAttributes()
	emitLifecycle(GameService.LifecycleNames.CustomerServed, player)
end

local function clearPayoutModel()
	if shiftPayoutModel then
		shiftPayoutModel:Destroy()
		shiftPayoutModel = nil
	end
end

local function removeHeldCash(player: Player)
	local character = player.Character
	local held = character and character:FindFirstChild("HeldShiftCash")
	if held then
		held:Destroy()
	end
	player:SetAttribute("HasCashInHand", false)
end

local function makeCashNote(parent: Instance, name: string, cframe: CFrame, anchored: boolean, canCollide: boolean): Part
	local note = Instance.new("Part")
	note.Name = name
	note.Size = Vector3.new(1.65, 0.065, 0.82)
	note.CFrame = cframe
	note.Anchored = anchored
	note.CanCollide = canCollide
	note.CanTouch = canCollide
	note.Massless = not anchored
	note.Material = Enum.Material.SmoothPlastic
	note.Color = Color3.fromRGB(107, 151, 103)
	note.TopSurface = Enum.SurfaceType.Smooth
	note.BottomSurface = Enum.SurfaceType.Smooth
	note.Parent = parent
	return note
end

local function showHeldCash(player: Player, amount: number)
	removeHeldCash(player)
	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	if not hand or not hand:IsA("BasePart") then
		return
	end

	local bundle = Instance.new("Model")
	bundle.Name = "HeldShiftCash"
	bundle:SetAttribute("Amount", amount)
	bundle.Parent = character
	local root = makeCashNote(bundle, "CashNote_1", hand.CFrame * CFrame.new(0, -0.58, -0.1) * CFrame.Angles(0, 0, math.rad(8)), false, false)
	bundle.PrimaryPart = root
	for index = 2, 4 do
		local note = makeCashNote(bundle, string.format("CashNote_%d", index), root.CFrame * CFrame.new(0, (index - 1) * 0.055, 0), false, false)
		local stackWeld = Instance.new("WeldConstraint")
		stackWeld.Part0 = root
		stackWeld.Part1 = note
		stackWeld.Parent = note
	end
	local handWeld = Instance.new("WeldConstraint")
	handWeld.Part0 = hand
	handWeld.Part1 = root
	handWeld.Parent = root
	player:SetAttribute("HasCashInHand", true)
end

local function collectShiftPayout(player: Player)
	if not shiftPayoutReady or player ~= shiftOwner then
		player:SetAttribute("ShopMessage", Copy.Messages.PayoutNotYours)
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not coins or not coins:IsA("IntValue") then
		return
	end

	shiftPayoutReady = false
	shiftPayoutCollected = true
	coins.Value += shiftPayoutAmount
	showHeldCash(player, shiftPayoutAmount)
	player:SetAttribute("ShopMessage", string.format(Copy.Messages.PayoutCollected, shiftPayoutAmount, coins.Value))
	bumpPlayerSerial(player, "ShiftPayoutSerial")
	clearPayoutModel()
	publishShiftAttributes()
	feedbackEvent:FireClient(player, "PayoutCollected", shiftPayoutAmount)
end

local function spawnShiftPayout(result: string)
	clearPayoutModel()
	if not shiftOwner or shiftPayoutAmount <= 0 then
		return
	end

	local payout = Instance.new("Model")
	payout.Name = "PipilabuShiftPayout"
	payout:SetAttribute("PayoutAmount", shiftPayoutAmount)
	payout:SetAttribute("ShiftResult", result)
	payout.Parent = Workspace
	shiftPayoutModel = payout
	local origin = Vector3.new(shiftConfig.PayoutPosition.X, shiftConfig.PayoutPosition.Y, shiftConfig.PayoutPosition.Z)
	local root = makeCashNote(payout, "CashNote_1", CFrame.new(origin), true, true)
	payout.PrimaryPart = root
	for index = 2, 5 do
		makeCashNote(payout, string.format("CashNote_%d", index), root.CFrame * CFrame.new(0, (index - 1) * 0.07, 0), true, true)
	end

	local band = Instance.new("Part")
	band.Name = "PaperBand"
	band.Size = Vector3.new(0.38, 0.38, 0.86)
	band.CFrame = root.CFrame * CFrame.new(0, 0.16, 0)
	band.Anchored = true
	band.CanCollide = false
	band.Material = Enum.Material.SmoothPlastic
	band.Color = Color3.fromRGB(245, 226, 174)
	band.Parent = payout

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TakeShiftPayoutPrompt"
	prompt.ActionText = Copy.Prompts.TakePayoutAction
	prompt.ObjectText = string.format(Copy.Prompts.ShiftPay, shiftPayoutAmount)
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(collectShiftPayout)
end

local function celebrateCustomer(customer: Model)
	local root = customer.PrimaryPart
	if not root then
		return
	end

	local billboard = customer:FindFirstChild("OrderBillboard", true)
	if billboard and billboard:IsA("BillboardGui") then
		billboard.Enabled = true
		local orderText = billboard:FindFirstChild("OrderText", true)
		if orderText and orderText:IsA("TextLabel") then
			orderText.Text = Copy.Prompts.ThankYou
			orderText.TextColor3 = Color3.fromRGB(42, 126, 68)
		end
		local appleDot = billboard:FindFirstChild("AppleDot", true)
		if appleDot and appleDot:IsA("Frame") then
			appleDot.BackgroundColor3 = Color3.fromRGB(92, 198, 102)
		end
	end
	local restingCFrame = root.CFrame
	local hop = TweenService:Create(root, TweenInfo.new(0.17, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = restingCFrame * CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.rad(-7)),
	})
	local land = TweenService:Create(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = restingCFrame,
	})
	hop.Completed:Once(function()
		land:Play()
	end)
	hop:Play()
end

local function setCustomerReaction(customer: Model, text: string, textColor: Color3, dotColor: Color3)
	local billboard = customer:FindFirstChild("OrderBillboard", true)
	if not billboard or not billboard:IsA("BillboardGui") then
		return
	end
	local orderText = billboard:FindFirstChild("OrderText", true)
	if orderText and orderText:IsA("TextLabel") then
		orderText.Text = text
		orderText.TextColor3 = textColor
	end
	local appleDot = billboard:FindFirstChild("AppleDot", true)
	if appleDot and appleDot:IsA("Frame") then
		appleDot.BackgroundColor3 = dotColor
	end
end

local function animateQueueRipple(kind: "Served" | "WrongApple", skipCustomer: Model?)
	local reacted = 0
	for queueIndex, waitingCustomer in queue do
		if waitingCustomer ~= skipCustomer and waitingCustomer.Parent then
			reacted += 1
			if reacted > 5 then
				break
			end
			local reactionIndex = reacted
			task.delay((reactionIndex - 1) * 0.055, function()
				local root = waitingCustomer.PrimaryPart
				if not root or not root.Parent or serving and queueIndex == 1 then
					return
				end
				local serial = (tonumber(waitingCustomer:GetAttribute("GroupReactionSerial")) or 0) + 1
				waitingCustomer:SetAttribute("GroupReactionSerial", serial)
				waitingCustomer:SetAttribute("GroupReactionKind", kind)
				local rest = root.CFrame
				local direction = if reactionIndex % 2 == 0 then -1 else 1
				local offset = if kind == "Served"
					then CFrame.new(0, 0.18, 0) * CFrame.Angles(0, 0, math.rad(4 * direction))
					else CFrame.new(0, 0.05, 0.12) * CFrame.Angles(0, math.rad(3 * direction), math.rad(5 * direction))
				local react = TweenService:Create(root, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					CFrame = rest * offset,
				})
				local settle = TweenService:Create(root, TweenInfo.new(0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					CFrame = rest,
				})
				react.Completed:Once(function()
					if waitingCustomer:GetAttribute("GroupReactionSerial") == serial then
						settle:Play()
					end
				end)
				react:Play()
			end)
		end
	end
end

local function movePartOnArc(
	part: BasePart,
	from: CFrame,
	to: CFrame,
	duration: number,
	height: number,
	spinDegrees: number
)
	local startedAt = os.clock()
	while part.Parent and os.clock() - startedAt < duration do
		local alpha = math.clamp((os.clock() - startedAt) / duration, 0, 1)
		local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local position = from.Position:Lerp(to.Position, eased)
			+ Vector3.new(0, math.sin(math.pi * eased) * height, 0)
		local rotation = from.Rotation:Lerp(to.Rotation, eased)
		part.CFrame = CFrame.new(position) * rotation * CFrame.Angles(0, math.rad(spinDegrees * eased), 0)
		RunService.Heartbeat:Wait()
	end
	if part.Parent then
		part.CFrame = to
	end
end

local function animateWrongAppleBounce(player: Player, customer: Model, orderId: string)
	if player:GetAttribute("WrongAppleInFlight") == true then
		return
	end
	local character = player.Character
	local original = character and character:FindFirstChild("HeldApple")
	local root = customer.PrimaryPart
	local visual = customer:FindFirstChild("CustomerShibaV4Visual")
	local rejectTarget = (visual and visual:FindFirstChild("Paw_R", true)) or customer:FindFirstChild("Muzzle") or root
	if not original or not original:IsA("BasePart") or not root or not rejectTarget or not rejectTarget:IsA("BasePart") then
		return
	end

	player:SetAttribute("WrongAppleInFlight", true)
	player:SetAttribute("LastWrongAppleType", tostring(original:GetAttribute("AppleType") or ""))
	bumpPlayerSerial(player, "WrongAppleSerial")
	feedbackEvent:FireClient(player, "Wrong")

	local hiddenTransparency: { [BasePart]: number } = {}
	hiddenTransparency[original] = original.Transparency
	original.Transparency = 1
	for _, descendant in original:GetDescendants() do
		if descendant:IsA("BasePart") then
			hiddenTransparency[descendant] = descendant.Transparency
			descendant.Transparency = 1
		end
	end

	local proxy = Instance.new("Part")
	proxy.Name = "RejectedApple"
	proxy.Shape = Enum.PartType.Ball
	proxy.Size = original.Size
	proxy.Color = original.Color
	proxy.Material = original.Material
	proxy.Reflectance = original.Reflectance
	proxy.Anchored = true
	proxy.CanCollide = false
	proxy.CanTouch = false
	proxy.CanQuery = false
	proxy.CFrame = original.CFrame
	proxy.Parent = customer

	local rest = root.CFrame
	local flinch = TweenService:Create(root, TweenInfo.new(0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = rest * CFrame.new(0, 0.12, 0.34) * CFrame.Angles(0, math.rad(10), math.rad(6)),
	})
	local shake = TweenService:Create(root, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		CFrame = rest * CFrame.Angles(0, math.rad(-9), math.rad(-5)),
	})
	local settle = TweenService:Create(root, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = rest,
	})
	flinch.Completed:Once(function()
		shake:Play()
	end)
	shake.Completed:Once(function()
		settle:Play()
	end)
	flinch:Play()

	setCustomerReaction(customer, Copy.Messages.WrongAppleReaction, Color3.fromRGB(184, 63, 55), Color3.fromRGB(232, 116, 79))
	animateQueueRipple("WrongApple", customer)
	local start = proxy.CFrame
	local contact = rejectTarget.CFrame * CFrame.new(0, 0.08, -0.48)
	movePartOnArc(proxy, start, contact, shopConfig.WrongAppleOutDuration, shopConfig.WrongAppleArcHeight * 0.45, 28)
	movePartOnArc(proxy, contact, start, shopConfig.WrongAppleReturnDuration, shopConfig.WrongAppleArcHeight, -54)
	proxy:Destroy()

	for part, transparency in hiddenTransparency do
		if part.Parent then
			part.Transparency = transparency
		end
	end
	local order = AppleCatalog.get(orderId)
	setCustomerReaction(customer, order.ShortName, Color3.fromRGB(75, 44, 29), order.Color)
	player:SetAttribute("WrongAppleInFlight", false)
end

local function spawnAppleCrumb(customer: Model, position: Vector3, color: Color3, index: number)
	local crumb = Instance.new("Part")
	crumb.Name = "AppleCrumb"
	crumb.Shape = Enum.PartType.Ball
	crumb.Size = Vector3.new(0.12, 0.12, 0.12)
	crumb.Color = color
	crumb.Material = Enum.Material.SmoothPlastic
	crumb.Anchored = true
	crumb.CanCollide = false
	crumb.CanTouch = false
	crumb.CanQuery = false
	crumb.Position = position
	crumb.Parent = customer
	local direction = if index % 2 == 0 then -1 else 1
	TweenService:Create(crumb, TweenInfo.new(0.36, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = position + Vector3.new(0.28 * direction, 0.34 + index * 0.04, -0.08),
		Transparency = 1,
		Size = Vector3.new(0.05, 0.05, 0.05),
	}):Play()
	Debris:AddItem(crumb, 0.42)
end

local function animateAppleEnjoyment(customer: Model)
	task.wait(0.12)
	local apple = customer:FindFirstChild("ReceivedApple")
	local visual = customer:FindFirstChild("CustomerShibaV4Visual")
	local mouthAttachment = visual and visual:FindFirstChild("ATTACH_Mouth", true)
	local muzzle = (visual and visual:FindFirstChild("Muzzle", true)) or customer:FindFirstChild("Muzzle")
	if not apple or not apple:IsA("BasePart") then
		return
	end

	local weld = apple:FindFirstChild("CustomerAppleWeld")
	if weld then
		weld:Destroy()
	end
	apple.Anchored = true
	local function mouthCFrame(): CFrame
		if mouthAttachment and mouthAttachment:IsA("Attachment") then
			return mouthAttachment.WorldCFrame
		end
		if muzzle and muzzle:IsA("BasePart") then
			return muzzle.CFrame * CFrame.new(0, -0.06, -0.46)
		end
		return apple.CFrame
	end

	movePartOnArc(apple, apple.CFrame, mouthCFrame(), shopConfig.EnjoymentApproachDuration, 0.16, 22)
	setCustomerReaction(customer, Copy.Messages.EnjoyedApple, Color3.fromRGB(42, 126, 68), Color3.fromRGB(92, 198, 102))
	for bite = 1, 3 do
		if not apple.Parent then
			return
		end
		local biteTween = TweenService:Create(apple, TweenInfo.new(shopConfig.EnjoymentBiteDuration, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {
			CFrame = mouthCFrame() * CFrame.Angles(0, 0, math.rad(if bite % 2 == 0 then -10 else 10)),
			Size = apple.Size * 0.68,
		})
		biteTween:Play()
		biteTween.Completed:Wait()
		spawnAppleCrumb(customer, apple.Position, apple.Color, bite)
	end
	apple:Destroy()
	customer:SetAttribute("EnjoymentComplete", true)
end

local function animateAppleHandoff(player: Player, customer: Model, onCaught: () -> ())
	local character = player.Character
	local heldApple = character and character:FindFirstChild("HeldApple")
	local visual = customer:FindFirstChild("CustomerShibaV4Visual")
	local rightPaw = visual and visual:FindFirstChild("Paw_R", true)
	local leftPaw = visual and visual:FindFirstChild("Paw_L", true)
	local target = if rightPaw and rightPaw:IsA("BasePart") then rightPaw else customer:FindFirstChild("Muzzle") or customer.PrimaryPart
	if not heldApple or not heldApple:IsA("BasePart") or not target or not target:IsA("BasePart") then
		removeHeldApple(player)
		onCaught()
		return
	end

	local handWeld = heldApple:FindFirstChildOfClass("WeldConstraint")
	if handWeld then
		handWeld:Destroy()
	end
	-- The server has already consumed the held inventory state. Move the visual
	-- out of the character immediately so a fast next pickup cannot delete the
	-- apple that is visibly traveling to the customer.
	heldApple.Name = "HandoffApple"
	heldApple.Parent = customer
	heldApple.Anchored = true

	local startCFrame = heldApple.CFrame
	local startPosition = startCFrame.Position
	local root = customer.PrimaryPart
	local receiveCFrame = if rightPaw and rightPaw:IsA("BasePart") and leftPaw and leftPaw:IsA("BasePart")
		then CFrame.new(rightPaw.Position:Lerp(leftPaw.Position, 0.5)) * root.CFrame.Rotation * CFrame.new(0, 0.08, -0.22)
		elseif root
		then root.CFrame * CFrame.new(0, 0.42, -1.05) * CFrame.Angles(0, 0, math.rad(-5))
		else target.CFrame * CFrame.new(0, 0.2, -0.2)
	local targetPosition = receiveCFrame.Position
	local midpoint = startPosition:Lerp(targetPosition, 0.5)
	local apex = midpoint + Vector3.new(0, shopConfig.HandoffArcHeight, 0)
	local duration = shopConfig.HandoffDuration
	local startedAt = os.clock()

	while heldApple.Parent and os.clock() - startedAt < duration do
		local elapsed = os.clock() - startedAt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local firstLeg = startPosition:Lerp(apex, eased)
		local secondLeg = apex:Lerp(targetPosition, eased)
		local position = firstLeg:Lerp(secondLeg, eased)
		local rotation = startCFrame.Rotation:Lerp(receiveCFrame.Rotation, eased)
		local handoffTilt = math.sin(math.pi * eased) * shopConfig.HandoffSpinDegrees
		heldApple.CFrame = CFrame.new(position) * rotation * CFrame.Angles(0, 0, math.rad(handoffTilt))
		RunService.Heartbeat:Wait()
	end

	if heldApple.Parent then
		heldApple.CFrame = receiveCFrame
		if root then
			local outline = heldApple:FindFirstChild("HeldAppleOutline")
			if outline then
				outline:Destroy()
			end

			heldApple.Name = "ReceivedApple"
			heldApple.Size = Vector3.new(1.5, 1.02, 1.5)
			heldApple.CFrame = receiveCFrame
			heldApple.Parent = customer
			heldApple.Anchored = false

			local customerWeld = Instance.new("WeldConstraint")
			customerWeld.Name = "CustomerAppleWeld"
			customerWeld.Part0 = if rightPaw and rightPaw:IsA("BasePart") then rightPaw else root
			customerWeld.Part1 = heldApple
			customerWeld.Parent = heldApple
			TweenService:Create(heldApple, TweenInfo.new(shopConfig.HandoffSettleTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = Vector3.new(1.3, 1.3, 1.3),
			}):Play()
		else
			heldApple:Destroy()
		end
	end

	onCaught()
end

local function setMessageForAll(message: string)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("ShopMessage", message)
	end
end

local function endShift(result: string, message: string)
	if shiftState ~= "Active" then
		return
	end

	shiftState = result
	shiftPayoutAmount = shiftConfig.PayoutBase + (shiftServed * shopConfig.ServeReward)
	if result == "Won" then
		shiftPayoutAmount += shiftConfig.PayoutClearBonus
	end
	shiftPayoutReady = shiftOwner ~= nil
	shiftPayoutCollected = false
	frontCustomer = nil
	frontPatienceEndsAt = 0
	frontPatienceRemaining = 0
	for _, prompt in applePrompts do
		prompt.Enabled = false
	end
	for _, player in Players:GetPlayers() do
		player:SetAttribute("HasApple", false)
		player:SetAttribute("HeldAppleType", "")
		player:SetAttribute("HandoffInFlight", false)
		player:SetAttribute("WrongAppleInFlight", false)
		removeHeldApple(player)
	end
	setMessageForAll(message)
	publishShiftAttributes()
	refreshQueue()
	if shiftOwner then
		feedbackEvent:FireClient(shiftOwner, result)
		feedbackEvent:FireClient(shiftOwner, "PayoutReady", shiftPayoutAmount, result)
	end
	spawnShiftPayout(result)
	emitLifecycle(GameService.LifecycleNames.ShiftEnded, shiftOwner)
end

local spawnCustomer: () -> ()

spawnCustomer = function()
	if #queue >= shopConfig.MaximumQueueSize then
		return
	end
	if shiftState == "Active" and shiftCustomerSpawned >= shopConfig.FirstShiftPopulationCap then
		return
	end

	local customer = createCustomer()
	table.insert(queue, customer)
	if shiftState == "Active" then
		shiftCustomerSpawned += 1
	end

	local prompt = customer:FindFirstChild("ServePrompt", true) :: ProximityPrompt?
	if prompt then
		prompt.Triggered:Connect(function(player)
			if shiftState ~= "Active" or shiftOwner ~= player then
				player:SetAttribute("ShopMessage", if shiftState == "Active" then Copy.Messages.ShiftInProgress else waitingMessage())
				return
			end

			if serving or queue[1] ~= customer then
				player:SetAttribute("ShopMessage", Copy.Messages.ServeReadyDogeFirst)
				return
			end

			if player:GetAttribute("HasApple") ~= true then
				local order = AppleCatalog.get(customer:GetAttribute("OrderType") :: string?)
				player:SetAttribute("ShopMessage", string.format(Copy.Messages.NeedsApple, order.DisplayName))
				return
			end

			local order = AppleCatalog.get(customer:GetAttribute("OrderType") :: string?)
			if player:GetAttribute("HeldAppleType") ~= order.Id then
				player:SetAttribute("ShopMessage", string.format(Copy.Messages.WrongApple, order.DisplayName))
				task.spawn(animateWrongAppleBounce, player, customer, order.Id)
				return
			end

			serving = true
			frontCustomer = nil
			frontPatienceEndsAt = 0
			frontPatienceRemaining = 0
			player:SetAttribute("LastHandoffAppleType", order.Id)
			player:SetAttribute("HandoffInFlight", true)
			bumpPlayerSerial(player, "HandoffSerial")
			player:SetAttribute("HasApple", false)
			player:SetAttribute("HeldAppleType", "")
			player:SetAttribute("ShopMessage", Copy.Messages.Sending)
			prompt.Enabled = false
			local patienceRing = customer:FindFirstChild("PatienceRing", true)
			if patienceRing and patienceRing:IsA("Frame") then
				patienceRing.Visible = false
			end

			local activeRun = runSerial
			task.spawn(animateAppleHandoff, player, customer, function()
				player:SetAttribute("HandoffInFlight", false)
				bumpPlayerSerial(player, "HandoffCompletedSerial")
				if activeRun ~= runSerial or shiftOwner ~= player or shiftState ~= "Active" then
					local staleIndex = table.find(queue, customer)
					if staleIndex then
						table.remove(queue, staleIndex)
					end
					destroyCustomer(customer)
					if activeRun == runSerial then
						serving = false
						refreshQueue()
					end
					return
				end

				player:SetAttribute("ShopMessage", Copy.Messages.Served)
				awardServe(player)
				CustomerPresentationService.PlayHandoff(customer)
				task.spawn(animateAppleEnjoyment, customer)
				feedbackEvent:FireClient(player, "Serve")
				celebrateCustomer(customer)
				animateQueueRipple("Served", customer)

				task.delay(shopConfig.ServeCelebrationTime, function()
					if activeRun ~= runSerial then
						destroyCustomer(customer)
						return
					end
					if queue[1] == customer then
						table.remove(queue, 1)
					end
					serving = false
					CustomerPresentationService.PlayExit(customer, "TurnLeave")
					tweenCustomer(customer, customerExit.CFrame, function()
						destroyCustomer(customer)
					end)

					if shiftServed >= shiftConfig.TargetServed then
						endShift("Won", Copy.Messages.ShiftWon)
						return
					end

					if os.clock() >= shiftEndsAt then
						endShift("Lost", Copy.Messages.ShiftLostTime)
						return
					end

					refreshQueue()
					player:SetAttribute("ShopMessage", Copy.Messages.TakeApple)

				end)
			end)
		end)
	end

	refreshQueue()
end

local function clearQueue()
	for _, customer in queue do
		destroyCustomer(customer)
	end
	table.clear(queue)
	frontCustomer = nil
	frontPatienceEndsAt = 0
	frontPatienceRemaining = 0
end

local function resetPlayerStats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local served = leaderstats:FindFirstChild("Served")
		if served and served:IsA("IntValue") then
			served.Value = 0
		end
	end
	player:SetAttribute("HasApple", false)
	player:SetAttribute("HeldAppleType", "")
	removeHeldApple(player)
end

local function startShift(player: Player)
	if shiftState == "Active" then
		player:SetAttribute("ShopMessage", Copy.Messages.ShiftInProgress)
		return
	end
	if shiftPayoutReady then
		player:SetAttribute("ShopMessage", Copy.Messages.CollectPayFirst)
		feedbackEvent:FireClient(player, "PayoutRequired", shiftPayoutAmount)
		return
	end

	runSerial += 1
	clearPayoutModel()
	removeHeldCash(player)
	shiftPayoutAmount = 0
	shiftPayoutCollected = false
	shiftState = "Active"
	shiftOwner = player
	shiftServed = 0
	shiftMissed = 0
	shiftCustomerSpawned = 0
	shiftEndsAt = os.clock() + shiftConfig.DurationSeconds
	shiftTimeRemaining = shiftConfig.DurationSeconds
	serving = false
	clearQueue()
	resetPlayerStats(player)

	for _, currentPlayer in Players:GetPlayers() do
		currentPlayer:SetAttribute("ShopMessage", if currentPlayer == player then Copy.Messages.ShiftStarted else Copy.Messages.ShiftInProgress)
	end
	publishShiftAttributes()
	for _, prompt in applePrompts do
		prompt.Enabled = true
	end

	for _ = 1, shopConfig.StartingQueueSize do
		spawnCustomer()
	end
	refreshQueue()
	publishShiftAttributes()
	feedbackEvent:FireClient(player, "Started")
	emitLifecycle(GameService.LifecycleNames.ShiftStarted, player)
end

local function missFrontCustomer()
	if shiftState ~= "Active" or serving then
		return
	end

	local customer = queue[1]
	if not customer then
		return
	end

	table.remove(queue, 1)
	frontCustomer = nil
	frontPatienceEndsAt = 0
	frontPatienceRemaining = 0
	shiftMissed += 1

	local orderText = customer:FindFirstChild("OrderText", true)
	if orderText and orderText:IsA("TextLabel") then
		orderText.Text = Copy.Prompts.Impatient
		orderText.TextColor3 = Color3.fromRGB(192, 54, 49)
	end

	setMessageForAll(Copy.Messages.MissedCustomer)
	publishShiftAttributes()
	if shiftOwner then
		feedbackEvent:FireClient(shiftOwner, "Miss")
	end
	emitLifecycle(GameService.LifecycleNames.CustomerMissed, shiftOwner)
	CustomerPresentationService.PlayExit(customer, "Run")
	tweenCustomer(customer, customerExit.CFrame, function()
		destroyCustomer(customer)
	end)

	if shiftMissed >= shiftConfig.MaximumMissed then
		endShift("Lost", Copy.Messages.ShiftLostMisses)
		return
	end

	refreshQueue()
	if shiftOwner then
		shiftOwner:SetAttribute("ShopMessage", Copy.Messages.TakeApple)
	end
end

local function runShiftClock()
	task.spawn(function()
		while started do
			task.wait(shiftConfig.TickRateSeconds)
			if shiftState ~= "Active" then
				continue
			end

			local now = os.clock()
			local timeRemaining = math.max(0, math.ceil(shiftEndsAt - now))
			shiftTimeRemaining = timeRemaining
			for _, player in Players:GetPlayers() do
				player:SetAttribute("ShiftTimeRemaining", timeRemaining)
			end

			if now >= shiftEndsAt then
				if not serving then
					endShift("Lost", Copy.Messages.ShiftLostTime)
				end
				continue
			end

			if frontCustomer and frontPatienceEndsAt > 0 and not serving then
				local remaining = math.max(0, frontPatienceEndsAt - now)
				frontPatienceRemaining = math.ceil(remaining)
				updatePatiencePresentation(frontCustomer, remaining)
				for _, player in Players:GetPlayers() do
					player:SetAttribute("FrontPatienceRemaining", frontPatienceRemaining)
				end
				if remaining <= 0 then
					missFrontCustomer()
				end
			end
		end
	end)
end

local STRUCTURAL_COLLISION_NAMES = table.freeze({
	ShopFloor = true,
	BackWall = true,
	LeftWall = true,
	RightWall = true,
	Awning = true,
	Roof = true,
	Counter = true,
	CounterTop = true,
	AppleCrate = true,
	HoneygoldAppleCrate = true,
	Floor = true,
	ShelfUpper = true,
	ShelfLower = true,
	Post = true,
	PlotPostX = true,
	PlotPostZ = true,
	ReservedPad = true,
})

local function enforceHonestStructuralCollision()
	local repaired = 0
	for _, root in {
		shop,
		Workspace:FindFirstChild("PipilabuMarketVillagePrototype"),
	} do
		if root then
			for _, descendant in root:GetDescendants() do
				if descendant:IsA("BasePart") and STRUCTURAL_COLLISION_NAMES[descendant.Name] == true then
					if not descendant.CanCollide then
						descendant.CanCollide = true
						repaired += 1
					end
					descendant.CanQuery = true
				end
			end
		end
	end
	shop:SetAttribute("StructuralCollisionRepairs", repaired)
end

local function ensureQueueCapacity()
	local spots = sortedQueueSpots()
	for index = #spots + 1, shopConfig.MaximumQueueSize do
		local spot = Instance.new("Part")
		spot.Name = string.format("Spot_%02d", index)
		spot.Size = Vector3.new(3.2, 0.08, 2.6)
		spot.Anchored = true
		spot.Transparency = 1
		spot.CanCollide = false
		spot.CanTouch = false
		spot.CanQuery = false
		spot:SetAttribute("Owner", "Jon and Leo Development")
		spot:SetAttribute("RuntimeQueueExtension", true)
		spot.Parent = queueSpots
	end
end

local function normalizePlayerReadableQueueLane()
	ensureQueueCapacity()
	local spots = sortedQueueSpots()
	local laneY = if spots[1] then spots[1].Position.Y else 0.54
	for index, spot in spots do
		-- Runtime extensions are born at the origin in older saved places. Every
		-- queue target must inherit the authored service-plane height or the
		-- expanded half of the line sinks below the first four customers.
		spot.CFrame = CFrame.new((index - 1) * shopConfig.QueueSpacingStuds, laneY, 1)
	end
	local spawnX = shopConfig.MaximumQueueSize * shopConfig.QueueSpacingStuds
	customerSpawn.CFrame = CFrame.new(spawnX, laneY, 1)
	customerExit.CFrame = CFrame.new(-15, laneY, 1)
	local path = shop:FindFirstChild("CustomerPath")
	if path and path:IsA("BasePart") then
		local centerX = (spawnX - 15) * 0.5
		path.Size = Vector3.new(spawnX + 19, path.Size.Y, path.Size.Z)
		path.Position = Vector3.new(centerX, path.Position.Y, 1)
	end
	shop:SetAttribute("QueueScreenDirection", "LeftToRightFromShopkeeper")
	shop:SetAttribute("VisibleQueueCapacity", shopConfig.MaximumQueueSize)
	shop:SetAttribute("QueueSpacingStuds", shopConfig.QueueSpacingStuds)
	shop:SetAttribute("FirstShiftPopulationCap", shopConfig.FirstShiftPopulationCap)
end

local function bindWorld()
	shop = Workspace:WaitForChild("DogeAppleShop") :: Folder
	customersFolder = shop:WaitForChild("Customers") :: Folder
	queueSpots = shop:WaitForChild("QueueSpots") :: Folder
	customerSpawn = shop:WaitForChild("CustomerSpawn") :: BasePart
	customerExit = shop:WaitForChild("CustomerExit") :: BasePart
	normalizePlayerReadableQueueLane()
	enforceHonestStructuralCollision()
	local rubyCrate = shop:WaitForChild("AppleCrate") :: BasePart
	rubyCrate:SetAttribute("AppleType", "Ruby")

	local honeygold = shop:FindFirstChild("HoneygoldAppleCrate")
	if not honeygold or not honeygold:IsA("BasePart") then
		if honeygold then
			honeygold:Destroy()
		end
		local cloned = rubyCrate:Clone()
		cloned.Name = "HoneygoldAppleCrate"
		cloned.CFrame = rubyCrate.CFrame * CFrame.new(18, 0, 0)
		cloned:SetAttribute("AppleType", "Honeygold")
		local inheritedPrompt = cloned:FindFirstChild("TakeApplePrompt")
		if inheritedPrompt then
			inheritedPrompt:Destroy()
		end
		cloned.Parent = shop
		honeygold = cloned

		for index = 1, 8 do
			local display = Instance.new("Part")
			display.Name = string.format("HoneygoldDisplay_%02d", index)
			display.Shape = Enum.PartType.Ball
			display.Size = Vector3.new(1.05, 1.05, 1.05)
			display.Color = AppleCatalog.get("Honeygold").Color
			display.Material = Enum.Material.SmoothPlastic
			display.Anchored = true
			display.CanCollide = false
			display.CanTouch = false
			display.CanQuery = false
			local column = (index - 1) % 4
			local row = math.floor((index - 1) / 4)
			display.Position = cloned.Position + Vector3.new(-1.8 + column * 1.2, 1.7 + row * 0.55, -0.35 + row * 0.7)
			display.Parent = shop
		end
	end
	local honeygoldCrate = honeygold :: BasePart
	honeygoldCrate.CFrame = rubyCrate.CFrame * CFrame.new(18, 0, 0)

	table.clear(applePrompts)
	for _, crate in { rubyCrate, honeygoldCrate } do
		local definition = AppleCatalog.get(crate:GetAttribute("AppleType") :: string?)
		local oldLabel = crate:FindFirstChild("AppleTypeLabel")
		if oldLabel then
			oldLabel:Destroy()
		end
		local label = Instance.new("BillboardGui")
		label.Name = "AppleTypeLabel"
		label.AlwaysOnTop = false
		label.MaxDistance = 42
		label.Size = UDim2.fromOffset(120, 32)
		label.StudsOffset = Vector3.new(if definition.Id == "Ruby" then -1.15 else 1.15, 3.1, 0)
		label.Parent = crate
		local labelText = Instance.new("TextLabel")
		labelText.BackgroundColor3 = Color3.fromRGB(40, 35, 31)
		labelText.BackgroundTransparency = 0.08
		labelText.BorderSizePixel = 0
		labelText.Size = UDim2.fromScale(1, 1)
		labelText.Font = Enum.Font.BuilderSansBold
		labelText.Text = definition.ShortName
		labelText.TextColor3 = Color3.fromRGB(255, 247, 230)
		labelText.TextSize = 16
		labelText.Parent = label
		local labelCorner = Instance.new("UICorner")
		labelCorner.CornerRadius = UDim.new(0, 8)
		labelCorner.Parent = labelText
		local labelStroke = Instance.new("UIStroke")
		labelStroke.Color = definition.DarkColor
		labelStroke.Thickness = 2
		labelStroke.Parent = labelText

		local pickupHostName = if definition.Id == "Ruby" then "DisplayApple_01" else "HoneygoldDisplay_01"
		local candidateHost = shop:FindFirstChild(pickupHostName)
		local pickupHost = if candidateHost and candidateHost:IsA("BasePart") then candidateHost else crate
		for _, oldPromptParent in { crate, pickupHost } do
			local oldPrompt = oldPromptParent:FindFirstChild("TakeApplePrompt")
			if oldPrompt then
				oldPrompt:Destroy()
			end
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TakeApplePrompt"
		prompt.ActionText = string.format(Copy.Prompts.TakeAppleAction, definition.ShortName)
		prompt.ObjectText = string.format(Copy.Prompts.AppleCrate, definition.ShortName)
		prompt.HoldDuration = shopConfig.PromptHoldDuration
		prompt.MaxActivationDistance = shopConfig.PickupPromptDistance
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.Enabled = false
		prompt.Parent = pickupHost
		crate:SetAttribute("PickupPromptHost", pickupHost.Name)
		crate:SetAttribute("PickupReadyDuringShift", true)
		prompt.Triggered:Connect(function(player)
			takeApple(player, definition.Id)
		end)
		table.insert(applePrompts, prompt)
	end
end

function GameService.Start(config: ProjectConfig)
	if started then
		return
	end
	shopConfig = config.Shop
	shiftConfig = config.Shift
	assert(shiftConfig.DurationSeconds > 0, "Shift.DurationSeconds must be positive")
	assert(shiftConfig.TargetServed > 0, "Shift.TargetServed must be positive")
	assert(shopConfig.FirstShiftPopulationCap == shopConfig.StartingQueueSize, "level one population must equal its starting queue")
	assert(shiftConfig.TargetServed <= shopConfig.FirstShiftPopulationCap, "shift target cannot exceed the level-one population")
	assert(shiftConfig.MaximumMissed > 0, "Shift.MaximumMissed must be positive")
	assert(shiftConfig.CustomerPatienceSeconds > 0, "Shift.CustomerPatienceSeconds must be positive")
	assert(shiftConfig.TickRateSeconds > 0, "Shift.TickRateSeconds must be positive")
	assert(shiftConfig.PayoutBase > 0, "Shift.PayoutBase must be positive")
	assert(shiftConfig.PayoutClearBonus > 0, "Shift.PayoutClearBonus must be positive")
	assert(shopConfig.PromptHoldDuration >= 0, "Shop.PromptHoldDuration cannot be negative")
	assert(shopConfig.HandoffDuration > 0, "Shop.HandoffDuration must be positive")
	assert(shopConfig.HandoffArcHeight >= 0, "Shop.HandoffArcHeight cannot be negative")
	assert(shopConfig.HandoffSettleTime > 0, "Shop.HandoffSettleTime must be positive")
	assert(shopConfig.WrongAppleOutDuration > 0, "Shop.WrongAppleOutDuration must be positive")
	assert(shopConfig.WrongAppleReturnDuration > 0, "Shop.WrongAppleReturnDuration must be positive")
	assert(shopConfig.WrongAppleArcHeight >= 0, "Shop.WrongAppleArcHeight cannot be negative")
	assert(shopConfig.EnjoymentApproachDuration > 0, "Shop.EnjoymentApproachDuration must be positive")
	assert(shopConfig.EnjoymentBiteDuration > 0, "Shop.EnjoymentBiteDuration must be positive")
	started = true
	local existingFeedback = projectRoot:FindFirstChild("ShopFeedback")
	if existingFeedback and existingFeedback:IsA("RemoteEvent") then
		feedbackEvent = existingFeedback
	else
		feedbackEvent = Instance.new("RemoteEvent")
		feedbackEvent.Name = "ShopFeedback"
		feedbackEvent.Parent = projectRoot
	end
	local existingControl = projectRoot:FindFirstChild("ShopControl")
	if existingControl and existingControl:IsA("RemoteEvent") then
		controlEvent = existingControl
	else
		controlEvent = Instance.new("RemoteEvent")
		controlEvent.Name = "ShopControl"
		controlEvent.Parent = projectRoot
	end

	bindWorld()
	local customerActivation = CustomerPresentationService.Activate(config.CustomerPresentation)
	print(string.format("[PeepilabuCustomer] %s", customerActivation.Code))
	controlEvent.OnServerEvent:Connect(function(player, action)
		if action == "StartShift" then
			startShift(player)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		configurePlayer(player)
		player.CharacterAdded:Connect(function()
			if player:GetAttribute("HasApple") == true then
				task.defer(showHeldApple, player)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		if player == shiftOwner then
			runSerial += 1
			shiftState = "Waiting"
			shiftOwner = nil
			shiftEndsAt = 0
			shiftTimeRemaining = 0
			shiftServed = 0
			shiftMissed = 0
			shiftCustomerSpawned = 0
			serving = false
			for _, prompt in applePrompts do
				prompt.Enabled = false
			end
			setMessageForAll(waitingMessage())
			publishShiftAttributes()
			refreshQueue()
		end
	end)

	for _, player in Players:GetPlayers() do
		configurePlayer(player)
	end

	for _ = 1, shopConfig.StartingQueueSize do
		spawnCustomer()
	end
	runShiftClock()

	print(string.format("[JonAndLeo] Doge Apple Shop ready with %d customers; shift waits for explicit start", #queue))
end

return GameService
