--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

type ShopConfig = {
	StartingQueueSize: number,
	MaximumQueueSize: number,
	ServeReward: number,
	CustomerRespawnDelay: number,
	CustomerMoveTime: number,
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
	apple.Size = Vector3.new(1.15, 1.15, 1.15)
	apple.Color = Color3.fromRGB(210, 42, 42)
	apple.Material = Enum.Material.SmoothPlastic
	apple.CanCollide = false
	apple.CanTouch = false
	apple.CanQuery = false
	apple.Massless = true
	apple.CFrame = hand.CFrame * CFrame.new(0, -0.9, 0)
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
	stem.CFrame = apple.CFrame * CFrame.new(0, 0.68, 0)
	stem.Parent = apple

	local stemWeld = Instance.new("WeldConstraint")
	stemWeld.Part0 = apple
	stemWeld.Part1 = stem
	stemWeld.Parent = stem
end

local function takeApple(player: Player)
	if player:GetAttribute("HasApple") == true then
		player:SetAttribute("ShopMessage", "Your paws are full - serve the front Doge")
		return
	end

	player:SetAttribute("HasApple", true)
	player:SetAttribute("ShopMessage", "Apple ready - serve the front Doge")
	showHeldApple(player)
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

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ServePrompt"
	prompt.ActionText = "Give Apple"
	prompt.ObjectText = "Waiting Doge"
	prompt.HoldDuration = 0.1
	prompt.MaxActivationDistance = shopConfig.ServePromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = head

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
			player:SetAttribute("ShopMessage", "Good fruit, gladly given")
			removeHeldApple(player)
			awardServe(player)

			table.remove(queue, 1)
			refreshQueue()
			tweenCustomer(customer, customerExit.CFrame, function()
				customer:Destroy()
			end)

			task.delay(shopConfig.CustomerRespawnDelay, function()
				serving = false
				spawnCustomer()
				refreshQueue()
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
	applePrompt.Triggered:Connect(takeApple)
end

function GameService.Start(config: ProjectConfig)
	if started then
		return
	end
	started = true
	shopConfig = config.Shop

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
