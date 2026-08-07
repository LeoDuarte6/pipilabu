--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

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

type ProjectConfig = {
	ProjectName: string,
	DevelopmentVersion: string,
	Shop: ShopConfig,
}

local GameService = {}

local started = false
local customerSerial = 0
local queue: { Model } = {}
local serving = false

local shop: Folder
local customersFolder: Folder
local queueSpots: Folder
local customerSpawn: BasePart
local customerExit: BasePart
local appleCrate: BasePart
local shopConfig: ShopConfig
local feedbackEvent: RemoteEvent

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
	player:SetAttribute("ShopMessage", "Take one apple from the crate")
	player:SetAttribute("QueueSize", #queue)
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
	if player:GetAttribute("HasApple") == true then
		player:SetAttribute("ShopMessage", "Your paws are full - serve the front Doge")
		return
	end

	player:SetAttribute("HasApple", true)
	player:SetAttribute("ShopMessage", "Apple ready - serve the front Doge")
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
	prompt.ActionText = "Give Apple"
	prompt.ObjectText = "Waiting Doge"
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
	orderBillboard.Size = UDim2.fromOffset(126, 44)
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
	appleDot.Position = UDim2.new(0, 12, 0.5, 0)
	appleDot.Size = UDim2.fromOffset(32, 32)
	appleDot.Parent = card

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = appleDot

	local orderText = Instance.new("TextLabel")
	orderText.Name = "OrderText"
	orderText.BackgroundTransparency = 1
	orderText.Font = Enum.Font.GothamBold
	orderText.Position = UDim2.fromOffset(52, 0)
	orderText.Size = UDim2.new(1, -60, 1, 0)
	orderText.Text = "APPLE"
	orderText.TextColor3 = Color3.fromRGB(75, 44, 29)
	orderText.TextScaled = true
	orderText.Parent = card

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

local function refreshQueue()
	local spots = sortedQueueSpots()
	for index, customer in queue do
		local spot = spots[index]
		if spot then
			tweenCustomer(customer, spot.CFrame)
		end

		local prompt = customer:FindFirstChild("ServePrompt", true)
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = index == 1 and not serving
			prompt.ObjectText = if index == 1 then "Front Doge" else string.format("Waiting Doge #%d", index)
		end

		local billboard = customer:FindFirstChild("OrderBillboard", true)
		if billboard and billboard:IsA("BillboardGui") then
			billboard.Enabled = index == 1
			local orderText = billboard:FindFirstChild("OrderText", true)
			if orderText and orderText:IsA("TextLabel") then
				orderText.Text = "APPLE"
				orderText.TextColor3 = Color3.fromRGB(75, 44, 29)
			end
		end
	end

	for _, player in Players:GetPlayers() do
		player:SetAttribute("QueueSize", #queue)
	end
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
			orderText.Text = "THANK YOU!"
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
		heldApple:Destroy()
	end

	onCaught()
end

local function spawnCustomer()
	if #queue >= shopConfig.MaximumQueueSize then
		return
	end

	local customer = createCustomer()
	table.insert(queue, customer)

	local prompt = customer:FindFirstChild("ServePrompt", true) :: ProximityPrompt?
	if prompt then
		prompt.Triggered:Connect(function(player)
			if serving or queue[1] ~= customer then
				player:SetAttribute("ShopMessage", "Serve the Doge at the front of the line first")
				return
			end

			if player:GetAttribute("HasApple") ~= true then
				player:SetAttribute("ShopMessage", "This Doge ordered an apple - visit the crate")
				return
			end

			serving = true
			player:SetAttribute("HasApple", false)
			player:SetAttribute("ShopMessage", "Send it with care")
			prompt.Enabled = false

			task.spawn(animateAppleHandoff, player, customer, function()
				player:SetAttribute("ShopMessage", "Good fruit, gladly given")
				awardServe(player)
				feedbackEvent:FireClient(player, "Serve")
				celebrateCustomer(customer)

				task.delay(shopConfig.ServeCelebrationTime, function()
					if queue[1] == customer then
						table.remove(queue, 1)
					end
					serving = false
					refreshQueue()
					tweenCustomer(customer, customerExit.CFrame, function()
						customer:Destroy()
					end)

					task.delay(shopConfig.CustomerRespawnDelay, function()
						spawnCustomer()
						refreshQueue()
					end)
				end)
			end)
		end)
	end

	refreshQueue()
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

	local applePrompt = prompt :: ProximityPrompt
	applePrompt.ActionText = "Take One Apple"
	applePrompt.ObjectText = "Apple Crate"
	applePrompt.HoldDuration = 0.1
	applePrompt.MaxActivationDistance = shopConfig.PickupPromptDistance
	applePrompt.RequiresLineOfSight = false
	applePrompt.KeyboardKeyCode = Enum.KeyCode.E
	applePrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	applePrompt.Triggered:Connect(takeApple)
end

function GameService.Start(config: ProjectConfig)
	if started then
		return
	end
	started = true
	shopConfig = config.Shop
	local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
	local existingFeedback = projectRoot:FindFirstChild("ShopFeedback")
	if existingFeedback and existingFeedback:IsA("RemoteEvent") then
		feedbackEvent = existingFeedback
	else
		feedbackEvent = Instance.new("RemoteEvent")
		feedbackEvent.Name = "ShopFeedback"
		feedbackEvent.Parent = projectRoot
	end

	bindWorld()

	Players.PlayerAdded:Connect(function(player)
		configurePlayer(player)
		player.CharacterAdded:Connect(function()
			if player:GetAttribute("HasApple") == true then
				task.defer(showHeldApple, player)
			end
		end)
	end)

	for _, player in Players:GetPlayers() do
		configurePlayer(player)
	end

	for _ = 1, shopConfig.StartingQueueSize do
		spawnCustomer()
	end

	print(string.format("[JonAndLeo] Doge Apple Shop ready with %d customers", #queue))
end

return GameService
