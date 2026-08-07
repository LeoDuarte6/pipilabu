--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Copy = require(projectRoot:WaitForChild("Copy"))

type ShopConfig = {
	StartingQueueSize: number,
	MaximumQueueSize: number,
	ServeReward: number,
	CustomerRespawnDelay: number,
	CustomerMoveTime: number,
	ServeCelebrationTime: number,
	PickupPromptDistance: number,
	ServePromptDistance: number,
}

type ShiftConfig = {
	DurationSeconds: number,
	TargetServed: number,
	MaximumMissed: number,
	CustomerPatienceSeconds: number,
	TickRateSeconds: number,
}

type ProjectConfig = {
	ProjectName: string,
	DevelopmentVersion: string,
	Shop: ShopConfig,
	Shift: ShiftConfig,
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
local runSerial = 0
local frontCustomer: Model? = nil
local frontPatienceEndsAt = 0
local frontPatienceRemaining = 0

local shop: Folder
local customersFolder: Folder
local queueSpots: Folder
local customerSpawn: BasePart
local customerExit: BasePart
local appleCrate: BasePart
local shopConfig: ShopConfig
local shiftConfig: ShiftConfig
local feedbackEvent: RemoteEvent
local controlEvent: RemoteEvent
local applePrompt: ProximityPrompt

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
	player:SetAttribute("ShiftMaximumMissed", shiftConfig.MaximumMissed)
	player:SetAttribute("FrontPatienceRemaining", frontPatienceRemaining)
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

local function configurePlayer(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coins = getOrCreateValue(leaderstats, "IntValue", "Coins") :: IntValue
	local served = getOrCreateValue(leaderstats, "IntValue", "Served") :: IntValue
	coins.Value = 0
	served.Value = 0

	player:SetAttribute("HasApple", false)
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

	local apple = Instance.new("Part")
	apple.Name = "HeldApple"
	apple.Shape = Enum.PartType.Ball
	apple.Size = Vector3.new(1.3, 1.3, 1.3)
	apple.Color = Color3.fromRGB(210, 42, 42)
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

local function takeApple(player: Player)
	if shiftState ~= "Active" or shiftOwner ~= player then
		player:SetAttribute("ShopMessage", if shiftState == "Active" then Copy.Messages.ShiftInProgress else waitingMessage())
		return
	end

	if player:GetAttribute("HasApple") == true then
		player:SetAttribute("ShopMessage", Copy.Messages.PawsFull)
		return
	end

	player:SetAttribute("HasApple", true)
	player:SetAttribute("ShopMessage", Copy.Messages.AppleReady)
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

local function createCustomer(): Model
	customerSerial += 1

	local model = Instance.new("Model")
	model.Name = string.format("DogeCustomer_%02d", customerSerial)
	model:SetAttribute("QueueNumber", customerSerial)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 3, 2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
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
	prompt.HoldDuration = 0.1
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
	orderBillboard.Size = UDim2.fromOffset(150, 66)
	orderBillboard.StudsOffset = Vector3.new(0, 1.45, 0)
	orderBillboard.Parent = head

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.BackgroundColor3 = Color3.fromRGB(248, 240, 222)
	card.BackgroundTransparency = 0.04
	card.BorderSizePixel = 0
	card.Size = UDim2.fromScale(1, 1)
	card.Parent = orderBillboard

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 14)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(82, 58, 43)
	cardStroke.Thickness = 1.5
	cardStroke.Parent = card

	local appleDot = Instance.new("Frame")
	appleDot.Name = "AppleDot"
	appleDot.AnchorPoint = Vector2.new(0, 0.5)
	appleDot.BackgroundColor3 = Color3.fromRGB(216, 48, 45)
	appleDot.BorderSizePixel = 0
	appleDot.Position = UDim2.fromOffset(10, 21)
	appleDot.Size = UDim2.fromOffset(28, 28)
	appleDot.Parent = card

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = appleDot

	local orderText = Instance.new("TextLabel")
	orderText.Name = "OrderText"
	orderText.BackgroundTransparency = 1
	orderText.Font = Enum.Font.GothamBold
	orderText.Position = UDim2.fromOffset(46, 4)
	orderText.Size = UDim2.new(1, -54, 0, 34)
	orderText.Text = Copy.Prompts.OrderApple
	orderText.TextColor3 = Color3.fromRGB(75, 44, 29)
	orderText.TextScaled = true
	orderText.Parent = card

	local patienceTrack = Instance.new("Frame")
	patienceTrack.Name = "PatienceTrack"
	patienceTrack.BackgroundColor3 = Color3.fromRGB(101, 88, 74)
	patienceTrack.BorderSizePixel = 0
	patienceTrack.ClipsDescendants = true
	patienceTrack.Position = UDim2.fromOffset(10, 45)
	patienceTrack.Size = UDim2.new(1, -20, 0, 13)
	patienceTrack.Parent = card

	local patienceCorner = Instance.new("UICorner")
	patienceCorner.CornerRadius = UDim.new(1, 0)
	patienceCorner.Parent = patienceTrack

	local patienceFill = Instance.new("Frame")
	patienceFill.Name = "PatienceFill"
	patienceFill.BackgroundColor3 = Color3.fromRGB(91, 190, 105)
	patienceFill.BorderSizePixel = 0
	patienceFill.Size = UDim2.fromScale(1, 1)
	patienceFill.Parent = patienceTrack

	local patienceFillCorner = Instance.new("UICorner")
	patienceFillCorner.CornerRadius = UDim.new(1, 0)
	patienceFillCorner.Parent = patienceFill

	local patienceText = Instance.new("TextLabel")
	patienceText.Name = "PatienceText"
	patienceText.BackgroundTransparency = 1
	patienceText.Font = Enum.Font.GothamBold
	patienceText.Size = UDim2.fromScale(1, 1)
	patienceText.Text = string.format(Copy.Prompts.Patience, shiftConfig.CustomerPatienceSeconds)
	patienceText.TextColor3 = Color3.fromRGB(255, 255, 255)
	patienceText.TextSize = 9
	patienceText.TextStrokeTransparency = 0.55
	patienceText.ZIndex = 2
	patienceText.Parent = patienceTrack

	model.Parent = customersFolder
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
	local fill = customer:FindFirstChild("PatienceFill", true)
	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.fromScale(ratio, 1)
		fill.BackgroundColor3 = if ratio > 0.5
			then Color3.fromRGB(91, 190, 105)
			elseif ratio > 0.25 then Color3.fromRGB(232, 173, 65)
			else Color3.fromRGB(220, 72, 65)
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
			billboard.Enabled = index == 1
			local patienceTrack = billboard:FindFirstChild("PatienceTrack", true)
			if patienceTrack and patienceTrack:IsA("Frame") then
				patienceTrack.Visible = index == 1 and shiftState == "Active" and not serving
			end
			local orderText = billboard:FindFirstChild("OrderText", true)
			if orderText and orderText:IsA("TextLabel") then
				orderText.Text = Copy.Prompts.OrderApple
				orderText.TextColor3 = Color3.fromRGB(75, 44, 29)
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

	local coins = leaderstats:FindFirstChild("Coins")
	local served = leaderstats:FindFirstChild("Served")
	if coins and coins:IsA("IntValue") then
		coins.Value += shopConfig.ServeReward
	end
	if served and served:IsA("IntValue") then
		served.Value += 1
	end
	shiftServed += 1
	publishShiftAttributes()
	emitLifecycle(GameService.LifecycleNames.CustomerServed, player)
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

local function animateAppleHandoff(player: Player, customer: Model, onCaught: () -> ())
	local character = player.Character
	local heldApple = character and character:FindFirstChild("HeldApple")
	local target = customer:FindFirstChild("Muzzle") or customer.PrimaryPart
	if not heldApple or not heldApple:IsA("BasePart") or not target or not target:IsA("BasePart") then
		removeHeldApple(player)
		onCaught()
		return
	end

	local handWeld = heldApple:FindFirstChildOfClass("WeldConstraint")
	if handWeld then
		handWeld:Destroy()
	end
	heldApple.Anchored = true

	local startCFrame = heldApple.CFrame
	local startPosition = startCFrame.Position
	local targetPosition = target.Position + Vector3.new(0, 0.2, -0.2)
	local midpoint = startPosition:Lerp(targetPosition, 0.5)
	local apex = midpoint + Vector3.new(0, 2.2, 0)
	local duration = 0.35
	local startedAt = os.clock()

	while heldApple.Parent and os.clock() - startedAt < duration do
		local elapsed = os.clock() - startedAt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		local firstLeg = startPosition:Lerp(apex, eased)
		local secondLeg = apex:Lerp(targetPosition, eased)
		local position = firstLeg:Lerp(secondLeg, eased)
		heldApple.CFrame = CFrame.new(position) * startCFrame.Rotation * CFrame.Angles(0, 0, math.rad(280 * eased))
		RunService.Heartbeat:Wait()
	end

	if heldApple.Parent then
		heldApple.CFrame = CFrame.new(targetPosition) * startCFrame.Rotation
		local catchSquash = TweenService:Create(heldApple, TweenInfo.new(0.07, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = Vector3.new(1.48, 1.15, 1.48),
		})
		catchSquash:Play()
		catchSquash.Completed:Wait()

		local root = customer.PrimaryPart
		if root then
			local outline = heldApple:FindFirstChild("HeldAppleOutline")
			if outline then
				outline:Destroy()
			end

			heldApple.Name = "ReceivedApple"
			heldApple.Size = Vector3.new(1.3, 1.3, 1.3)
			heldApple.CFrame = root.CFrame * CFrame.new(0, 0.45, -1.28) * CFrame.Angles(0, 0, math.rad(-8))
			heldApple.Parent = customer
			heldApple.Anchored = false

			local customerWeld = Instance.new("WeldConstraint")
			customerWeld.Name = "CustomerAppleWeld"
			customerWeld.Part0 = root
			customerWeld.Part1 = heldApple
			customerWeld.Parent = heldApple
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
	frontCustomer = nil
	frontPatienceEndsAt = 0
	frontPatienceRemaining = 0
	applePrompt.Enabled = false
	for _, player in Players:GetPlayers() do
		player:SetAttribute("HasApple", false)
		removeHeldApple(player)
	end
	setMessageForAll(message)
	publishShiftAttributes()
	refreshQueue()
	if shiftOwner then
		feedbackEvent:FireClient(shiftOwner, result)
	end
	emitLifecycle(GameService.LifecycleNames.ShiftEnded, shiftOwner)
end

local spawnCustomer: () -> ()

spawnCustomer = function()
	if #queue >= shopConfig.MaximumQueueSize then
		return
	end

	local customer = createCustomer()
	table.insert(queue, customer)

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
				player:SetAttribute("ShopMessage", Copy.Messages.NeedsApple)
				return
			end

			serving = true
			frontCustomer = nil
			frontPatienceEndsAt = 0
			frontPatienceRemaining = 0
			player:SetAttribute("HasApple", false)
			player:SetAttribute("ShopMessage", Copy.Messages.Sending)
			prompt.Enabled = false
			local patienceTrack = customer:FindFirstChild("PatienceTrack", true)
			if patienceTrack and patienceTrack:IsA("Frame") then
				patienceTrack.Visible = false
			end

			local activeRun = runSerial
			task.spawn(animateAppleHandoff, player, customer, function()
				if activeRun ~= runSerial or shiftOwner ~= player or shiftState ~= "Active" then
					local staleIndex = table.find(queue, customer)
					if staleIndex then
						table.remove(queue, staleIndex)
					end
					customer:Destroy()
					if activeRun == runSerial then
						serving = false
						refreshQueue()
					end
					return
				end

				player:SetAttribute("ShopMessage", Copy.Messages.Served)
				awardServe(player)
				feedbackEvent:FireClient(player, "Serve")
				celebrateCustomer(customer)

				task.delay(shopConfig.ServeCelebrationTime, function()
					if activeRun ~= runSerial then
						customer:Destroy()
						return
					end
					if queue[1] == customer then
						table.remove(queue, 1)
					end
					serving = false
					tweenCustomer(customer, customerExit.CFrame, function()
						customer:Destroy()
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

					task.delay(shopConfig.CustomerRespawnDelay, function()
						if activeRun ~= runSerial or shiftState ~= "Active" then
							return
						end
						spawnCustomer()
						refreshQueue()
					end)
				end)
			end)
		end)
	end

	refreshQueue()
end

local function clearQueue()
	for _, customer in queue do
		customer:Destroy()
	end
	table.clear(queue)
	frontCustomer = nil
	frontPatienceEndsAt = 0
	frontPatienceRemaining = 0
end

local function resetPlayerStats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		local served = leaderstats:FindFirstChild("Served")
		if coins and coins:IsA("IntValue") then
			coins.Value = 0
		end
		if served and served:IsA("IntValue") then
			served.Value = 0
		end
	end
	player:SetAttribute("HasApple", false)
	removeHeldApple(player)
end

local function startShift(player: Player)
	if shiftState == "Active" then
		player:SetAttribute("ShopMessage", Copy.Messages.ShiftInProgress)
		return
	end

	runSerial += 1
	shiftState = "Active"
	shiftOwner = player
	shiftServed = 0
	shiftMissed = 0
	shiftEndsAt = os.clock() + shiftConfig.DurationSeconds
	shiftTimeRemaining = shiftConfig.DurationSeconds
	serving = false
	clearQueue()
	resetPlayerStats(player)

	for _, currentPlayer in Players:GetPlayers() do
		currentPlayer:SetAttribute("ShopMessage", if currentPlayer == player then Copy.Messages.ShiftStarted else Copy.Messages.ShiftInProgress)
	end
	publishShiftAttributes()
	applePrompt.Enabled = true

	for _ = 1, shopConfig.StartingQueueSize do
		spawnCustomer()
	end
	refreshQueue()
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
	tweenCustomer(customer, customerExit.CFrame, function()
		customer:Destroy()
	end)

	if shiftMissed >= shiftConfig.MaximumMissed then
		endShift("Lost", Copy.Messages.ShiftLostMisses)
		return
	end

	local activeRun = runSerial
	refreshQueue()
	task.delay(shopConfig.CustomerRespawnDelay, function()
		if activeRun ~= runSerial or shiftState ~= "Active" then
			return
		end
		spawnCustomer()
		refreshQueue()
	end)
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

local function bindWorld()
	shop = Workspace:WaitForChild("DogeAppleShop") :: Folder
	customersFolder = shop:WaitForChild("Customers") :: Folder
	queueSpots = shop:WaitForChild("QueueSpots") :: Folder
	customerSpawn = shop:WaitForChild("CustomerSpawn") :: BasePart
	customerExit = shop:WaitForChild("CustomerExit") :: BasePart
	appleCrate = shop:WaitForChild("AppleCrate") :: BasePart

	local prompt = appleCrate:FindFirstChild("TakeApplePrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TakeApplePrompt"
		prompt.Parent = appleCrate
	end

	applePrompt = prompt :: ProximityPrompt
	applePrompt.ActionText = Copy.Prompts.TakeAppleAction
	applePrompt.ObjectText = Copy.Prompts.AppleCrate
	applePrompt.HoldDuration = 0.1
	applePrompt.MaxActivationDistance = shopConfig.PickupPromptDistance
	applePrompt.RequiresLineOfSight = false
	applePrompt.KeyboardKeyCode = Enum.KeyCode.E
	applePrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	applePrompt.Enabled = false
	applePrompt.Triggered:Connect(takeApple)
end

function GameService.Start(config: ProjectConfig)
	if started then
		return
	end
	shopConfig = config.Shop
	shiftConfig = config.Shift
	assert(shiftConfig.DurationSeconds > 0, "Shift.DurationSeconds must be positive")
	assert(shiftConfig.TargetServed > 0, "Shift.TargetServed must be positive")
	assert(shiftConfig.MaximumMissed > 0, "Shift.MaximumMissed must be positive")
	assert(shiftConfig.CustomerPatienceSeconds > 0, "Shift.CustomerPatienceSeconds must be positive")
	assert(shiftConfig.TickRateSeconds > 0, "Shift.TickRateSeconds must be positive")
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
			serving = false
			applePrompt.Enabled = false
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
