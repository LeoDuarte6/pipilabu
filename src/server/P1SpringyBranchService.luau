--!strict

-- Optional, Studio-only Gate P1 prototype. The service owns the isolated
-- source and its authoritative state machine, but deliberately does not edit
-- GameService's current crate, inventory, queue, or Paw_R handoff.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local P1SpringyBranch = require(projectRoot:WaitForChild("P1SpringyBranch"))

type P1Config = {
	Enabled: boolean,
	StudioOnly: boolean,
	WorldName: string,
	OriginX: number,
	OriginY: number,
	OriginZ: number,
	InteractionHoldDuration: number,
	TensionUpdateHz: number,
	MaxBranchBendDegrees: number,
	RecoverySettleSeconds: number,
	Tuning: P1SpringyBranch.Tuning,
}

export type CarryAdapter = {
	CanReceiveRuby: (player: Player) -> boolean,
	AttachRubyToPlayer: (player: Player, ruby: BasePart) -> boolean,
	DetachRubyFromPlayer: (player: Player, ruby: BasePart) -> (),
	PrepareRubyForServe: (player: Player, ruby: BasePart) -> (),
}

local P1SpringyBranchService = {}
local OWNER = "Jon and Leo Development"
local FEATURE = "GateP1SpringyBranch"
local RUBY_COLOR = Color3.fromRGB(210, 49, 42)
local WOOD_COLOR = Color3.fromRGB(86, 58, 39)
local LEAF_COLOR = Color3.fromRGB(62, 112, 62)

local started = false
local config: P1Config?
local session: P1SpringyBranch.Session?
local carryAdapter: CarryAdapter?
local prototype: Folder?
local ground: BasePart?
local trunk: BasePart?
local branch: BasePart?
local branchRestCFrame: CFrame?
local branchAttachment: Attachment?
local ruby: BasePart?
local rubyAttachment: Attachment?
local spring: SpringConstraint?
local stemBeam: Beam?
local gripPrompt: ProximityPrompt?
local recoverPrompt: ProximityPrompt?
local activePlayer: Player?
local gripStartDistance = 0
local gripStartLateral = 0
local gripSide = Vector3.new(1, 0, 0)
local gripFacing = Vector3.new(0, 0, -1)
local sourceCFrame: CFrame?
local lastTensionUpdate = 0
local settleSerial = 0
local connections: { RBXScriptConnection } = {}

local function getConfig(): P1Config
	assert(config, "P1 springy branch has not started")
	return config :: P1Config
end

local function getSession(): P1SpringyBranch.Session
	assert(session, "P1 springy branch has not started")
	return session :: P1SpringyBranch.Session
end

local function getPrototype(): Folder
	assert(prototype, "P1 springy branch prototype is not built")
	return prototype :: Folder
end

local function getRuby(): BasePart
	assert(ruby, "P1 Ruby is not built")
	return ruby :: BasePart
end

local function getBranchAttachment(): Attachment
	assert(branchAttachment, "P1 branch attachment is not built")
	return branchAttachment :: Attachment
end

local function getPlayerRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end
	return nil
end

local function horizontalUnit(value: Vector3, fallback: Vector3): Vector3
	local horizontal = Vector3.new(value.X, 0, value.Z)
	if horizontal.Magnitude < 0.001 then
		return fallback
	end
	return horizontal.Unit
end

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function setStateAttributes()
	local activePrototype = prototype
	local activeSession = session
	if not activePrototype or not activeSession then
		return
	end

	local snapshot = activeSession.getSnapshot()
	activePrototype:SetAttribute("RubyState", snapshot.State)
	activePrototype:SetAttribute("PeakTension", snapshot.PeakTension)
	activePrototype:SetAttribute("LastTension", snapshot.LastTension)
	activePrototype:SetAttribute("DominantInput", snapshot.DominantInput)
	activePrototype:SetAttribute("ReleaseSpeed", snapshot.ReleaseSpeed or 0)
	activePrototype:SetAttribute("ActivePlayerUserId", if activePlayer then activePlayer.UserId else 0)
end

local function recordResult(result: P1SpringyBranch.Result)
	local activePrototype = prototype
	if not activePrototype then
		return
	end

	for _, event in result.Events do
		activePrototype:SetAttribute("LastEvent", event.Name)
		activePrototype:SetAttribute("EventSerial", event.Serial)
		activePrototype:SetAttribute("LastEventReason", event.Reason or "")
		activePrototype:SetAttribute("LastEventDominantInput", event.DominantInput)
		activePrototype:SetAttribute("LastEventPeakTension", event.PeakTension)
		activePrototype:SetAttribute("LastEventReleaseSpeed", event.ReleaseSpeed or 0)
	end
	setStateAttributes()
end

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = canCollide
	part.CanTouch = canCollide
	part.CanQuery = canCollide
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part:SetAttribute("Owner", OWNER)
	part:SetAttribute("Feature", FEATURE)
	part.Parent = parent
	return part
end

local function createTether()
	local activeBranchAttachment = getBranchAttachment()
	local activeRuby = getRuby()
	local activeConfig = getConfig()

	if spring then
		spring:Destroy()
	end
	if stemBeam then
		stemBeam:Destroy()
	end

	local activeRubyAttachment = rubyAttachment
	if not activeRubyAttachment or not activeRubyAttachment.Parent then
		activeRubyAttachment = Instance.new("Attachment")
		activeRubyAttachment.Name = "RubyStemAttachment"
		activeRubyAttachment.Parent = activeRuby
		rubyAttachment = activeRubyAttachment
	end
	activeRubyAttachment.Position = Vector3.new(0, activeRuby.Size.Y * 0.5, 0)

	local newSpring = Instance.new("SpringConstraint")
	newSpring.Name = "RubyStemSpring"
	newSpring.Attachment0 = activeBranchAttachment
	newSpring.Attachment1 = activeRubyAttachment
	newSpring.FreeLength = 1.15
	newSpring.Stiffness = activeConfig.Tuning.SpringStrength
	newSpring.Damping = activeConfig.Tuning.Damping
	newSpring.MaxForce = activeConfig.Tuning.MaxReleaseVelocity * 32
	newSpring.Visible = false
	newSpring.Parent = activeRuby
	spring = newSpring

	local newBeam = Instance.new("Beam")
	newBeam.Name = "RubyStem"
	newBeam.Attachment0 = activeBranchAttachment
	newBeam.Attachment1 = activeRubyAttachment
	newBeam.Color = ColorSequence.new(WOOD_COLOR)
	newBeam.Width0 = 0.12
	newBeam.Width1 = 0.09
	newBeam.FaceCamera = true
	newBeam.Parent = activeRuby
	stemBeam = newBeam

	activeRuby.Anchored = true
	activeRuby.CanCollide = false
	activeRuby.CanTouch = true
	activeRuby.CanQuery = true
	activeRuby:SetAttribute("StemTension", 0)
	activeRuby:SetAttribute("WobbleAmount", 0)
end

local function makeGripPrompt(parent: BasePart): ProximityPrompt
	local activeConfig = getConfig()
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GripRubyPrompt"
	prompt.ActionText = "Grip Ruby"
	prompt.ObjectText = "Springy Branch"
	prompt.HoldDuration = activeConfig.InteractionHoldDuration
	prompt.MaxActivationDistance = activeConfig.Tuning.BranchReachStuds
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Enabled = true
	prompt.Parent = parent
	return prompt
end

local function makeRecoverPrompt(parent: BasePart): ProximityPrompt
	local activeConfig = getConfig()
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RecoverRubyPrompt"
	prompt.ActionText = "Recover Ruby"
	prompt.ObjectText = "Ruby"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = activeConfig.Tuning.CatchForgivenessStuds
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Enabled = false
	prompt.Parent = parent
	return prompt
end

local function buildPrototype()
	local activeConfig = getConfig()
	local previous = Workspace:FindFirstChild(activeConfig.WorldName)
	if previous then
		assert(
			previous:GetAttribute("Feature") == FEATURE,
			string.format("Refusing to replace non-P1 Workspace.%s", activeConfig.WorldName)
		)
		previous:Destroy()
	end

	local origin = Vector3.new(activeConfig.OriginX, activeConfig.OriginY, activeConfig.OriginZ)
	local newPrototype = Instance.new("Folder")
	newPrototype.Name = activeConfig.WorldName
	newPrototype:SetAttribute("Owner", OWNER)
	newPrototype:SetAttribute("Feature", FEATURE)
	newPrototype:SetAttribute("PrototypeOnly", true)
	newPrototype:SetAttribute("GameplayAuthority", "P1SpringyBranchService")
	newPrototype:SetAttribute("PersistentInventory", false)
	newPrototype.Parent = Workspace
	prototype = newPrototype

	ground = makePart(
		newPrototype,
		"P1Ground",
		Vector3.new(14, 0.4, 12),
		CFrame.new(origin),
		Color3.fromRGB(114, 147, 78),
		Enum.Material.Grass,
		true
	)

	trunk = makePart(
		newPrototype,
		"SpringyTrunk",
		Vector3.new(0.9, 3.1, 0.9),
		CFrame.new(origin + Vector3.new(-2.1, 1.75, 0)),
		WOOD_COLOR,
		Enum.Material.Wood,
		true
	)

	local rest = CFrame.new(origin + Vector3.new(0, 3.35, 0)) * CFrame.Angles(0, 0, math.rad(-8))
	local newBranch = makePart(
		newPrototype,
		"SpringyBranch",
		Vector3.new(4.6, 0.42, 0.42),
		rest,
		WOOD_COLOR,
		Enum.Material.Wood,
		true
	)
	branch = newBranch
	branchRestCFrame = rest

	local newBranchAttachment = Instance.new("Attachment")
	newBranchAttachment.Name = "RubyStemAnchor"
	newBranchAttachment.Position = Vector3.new(newBranch.Size.X * 0.5 - 0.2, -0.08, 0)
	newBranchAttachment.Parent = newBranch
	branchAttachment = newBranchAttachment

	local applePosition = newBranchAttachment.WorldPosition + Vector3.new(0, -1.15, 0)
	local newRuby = makePart(
		newPrototype,
		"AttachedRuby",
		Vector3.new(1.35, 1.2, 1.35),
		CFrame.new(applePosition),
		RUBY_COLOR,
		Enum.Material.SmoothPlastic,
		false
	)
	newRuby.Shape = Enum.PartType.Ball
	newRuby.Anchored = true
	newRuby.CanTouch = true
	newRuby.CanQuery = true
	newRuby.Reflectance = 0.04
	newRuby.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.45, 0.35, 1, 1)
	newRuby:SetAttribute("AppleType", "Ruby")
	newRuby:SetAttribute("RubyState", "Attached")
	ruby = newRuby
	sourceCFrame = newRuby.CFrame

	local leaf = makePart(
		newRuby,
		"Leaf",
		Vector3.new(0.42, 0.08, 0.24),
		newRuby.CFrame * CFrame.new(0.26, 0.62, 0) * CFrame.Angles(0, 0, math.rad(24)),
		LEAF_COLOR,
		Enum.Material.SmoothPlastic,
		false
	)
	leaf.Anchored = false
	leaf.CanCollide = false
	leaf.CanTouch = false
	leaf.CanQuery = false
	leaf.Massless = true
	local leafWeld = Instance.new("WeldConstraint")
	leafWeld.Name = "LeafWeld"
	leafWeld.Part0 = newRuby
	leafWeld.Part1 = leaf
	leafWeld.Parent = leaf

	createTether()
	gripPrompt = makeGripPrompt(newRuby)
	recoverPrompt = makeRecoverPrompt(newRuby)
	newPrototype:SetAttribute("SourceCFrame", tostring(sourceCFrame))
	setStateAttributes()
end

local function bendBranch(sample: P1SpringyBranch.TensionSample)
	local activeBranch = branch
	local activeRuby = ruby
	local activeAttachment = branchAttachment
	local rest = branchRestCFrame
	if not activeBranch or not activeRuby or not activeAttachment or not rest then
		return
	end

	local activeConfig = getConfig()
	local bend = math.rad(activeConfig.MaxBranchBendDegrees * sample.Value)
	activeBranch.CFrame = rest * CFrame.Angles(0, 0, -bend)
	activeRuby.CFrame = CFrame.new(activeAttachment.WorldPosition + Vector3.new(0, -(1.15 + sample.Value * 0.55), 0))
	activeRuby:SetAttribute("StemTension", sample.Value)
	activeRuby:SetAttribute("WobbleAmount", sample.Value)
	activeRuby:SetAttribute("DominantInput", sample.Dominant)
end

local function settleBranch()
	local activeBranch = branch
	local activeRuby = ruby
	local rest = branchRestCFrame
	if not activeBranch or not activeRuby or not rest then
		return
	end

	settleSerial += 1
	local serial = settleSerial
	local startBranch = activeBranch.CFrame
	local startRuby = activeRuby.CFrame
	local startedAt = os.clock()
	local duration = 0.32
	task.spawn(function()
		while serial == settleSerial and activeBranch.Parent and activeRuby.Parent do
			local alpha = math.clamp((os.clock() - startedAt) / duration, 0, 1)
			local eased = 1 - (1 - alpha) ^ 3
			activeBranch.CFrame = startBranch:Lerp(rest, eased)
			if getSession().getSnapshot().State == "Attached" then
				activeRuby.CFrame = startRuby:Lerp(CFrame.new(getBranchAttachment().WorldPosition + Vector3.new(0, -1.15, 0)), eased)
			end
			if alpha >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		if serial == settleSerial and activeBranch.Parent then
			activeBranch.CFrame = rest
		end
	end)
end

local function attachRubyToDefaultHand(player: Player): boolean
	local activeRuby = getRuby()
	local character = player.Character
	if not character then
		return false
	end

	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or character:FindFirstChild("HumanoidRootPart")
	if not hand or not hand:IsA("BasePart") then
		return false
	end

	local oldCarryWeld = activeRuby:FindFirstChild("P1CarryWeld")
	if oldCarryWeld then
		oldCarryWeld:Destroy()
	end
	activeRuby.Name = "P1HeldRuby"
	activeRuby.Parent = character
	activeRuby.Anchored = false
	activeRuby.CanCollide = false
	activeRuby.CFrame = hand.CFrame * CFrame.new(0, -0.15, -0.78)
	local carryWeld = Instance.new("WeldConstraint")
	carryWeld.Name = "P1CarryWeld"
	carryWeld.Part0 = hand
	carryWeld.Part1 = activeRuby
	carryWeld.Parent = activeRuby
	return true
end

local dropRuby: () -> ()

local function removeDefaultCarryWeld()
	local activeRuby = ruby
	if not activeRuby then
		return
	end
	local oldCarryWeld = activeRuby:FindFirstChild("P1CarryWeld")
	if oldCarryWeld then
		oldCarryWeld:Destroy()
	end
end

local function gripInput(player: Player): P1SpringyBranch.TensionInput?
	local activeAttachment = branchAttachment
	local rootPart = getPlayerRoot(player)
	if not activeAttachment or not rootPart then
		return nil
	end

	local relative = rootPart.Position - activeAttachment.WorldPosition
	local currentDistance = relative.Magnitude
	local pullDistance = math.max(0, currentDistance - gripStartDistance)
	local currentFacing = horizontalUnit(rootPart.CFrame.LookVector, gripFacing)
	local facingDot = math.clamp(gripFacing:Dot(currentFacing), -1, 1)
	local facingAngle = math.deg(math.acos(facingDot))
	local lateral = math.abs(relative:Dot(gripSide) - gripStartLateral)
	local twistDegrees = math.max(facingAngle, lateral * 24)

	return {
		PullDistanceStuds = pullDistance,
		TwistDegrees = twistDegrees,
	}
end

local function beginGrip(player: Player)
	local activeSession = getSession()
	if activePlayer and activePlayer ~= player then
		return
	end

	local rootPart = getPlayerRoot(player)
	local activeAttachment = branchAttachment
	if not rootPart or not activeAttachment then
		return
	end

	local relative = rootPart.Position - activeAttachment.WorldPosition
	local distance = relative.Magnitude
	local result = activeSession.beginGrip(distance, spring ~= nil)
	if not result.Accepted then
		return
	end

	activePlayer = player
	gripStartDistance = distance
	gripFacing = horizontalUnit(rootPart.CFrame.LookVector, Vector3.new(0, 0, -1))
	gripSide = Vector3.new(-gripFacing.Z, 0, gripFacing.X)
	gripStartLateral = relative:Dot(gripSide)
	lastTensionUpdate = 0
	local prompt = gripPrompt
	if prompt then
		prompt.ActionText = "Pull / Twist"
	end
	local activeRuby = ruby
	if activeRuby then
		activeRuby:SetAttribute("GripUserId", player.UserId)
	end
	recordResult(result)
end

local function releaseGrip(player: Player)
	if activePlayer ~= player then
		return
	end
	local result = getSession().releaseGrip()
	if not result.Accepted then
		return
	end
	activePlayer = nil
	local prompt = gripPrompt
	if prompt then
		prompt.ActionText = "Grip Ruby"
	end
	local activeRuby = ruby
	if activeRuby then
		activeRuby:SetAttribute("GripUserId", 0)
	end
	recordResult(result)
	settleBranch()
end

local function detachRuby(player: Player, result: P1SpringyBranch.Result)
	local activeRuby = getRuby()
	local activeAttachment = getBranchAttachment()
	local rootPart = getPlayerRoot(player)
	local away = if rootPart then rootPart.Position - activeAttachment.WorldPosition else activeAttachment.WorldCFrame.LookVector
	local direction = Vector3.new(away.X, math.max(away.Y, 0.2), away.Z)
	if direction.Magnitude < 0.001 then
		direction = Vector3.new(0, 0.2, -1)
	end
	direction = direction.Unit

	if spring then
		spring:Destroy()
		spring = nil
	end
	if stemBeam then
		stemBeam:Destroy()
		stemBeam = nil
	end
	activeRuby.Anchored = false
	activeRuby.CanCollide = true
	activeRuby.CanTouch = true
	activeRuby.CanQuery = true
	activeRuby.AssemblyLinearVelocity = direction * (result.ReleaseSpeed or 0)
	activeRuby.AssemblyAngularVelocity = Vector3.new(0, 5, -4) * math.clamp(result.ReleaseSpeed or 0, 0, 18) / 18
	activeRuby:SetAttribute("RubyState", "DetachedAirborne")
	activeRuby:SetAttribute("StemTension", result.PeakTension)
	activeRuby:SetAttribute("WobbleAmount", result.PeakTension)
	local prompt = gripPrompt
	if prompt then
		prompt.Enabled = false
	end
	local recovery = recoverPrompt
	if recovery then
		recovery.Enabled = false
	end
	recordResult(result)
	settleBranch()
end

local function catchRuby(player: Player)
	if activePlayer ~= player then
		return
	end
	if carryAdapter and not carryAdapter.CanReceiveRuby(player) then
		return
	end

	local rootPart = getPlayerRoot(player)
	local activeRuby = getRuby()
	if not rootPart or (rootPart.Position - activeRuby.Position).Magnitude > getConfig().Tuning.CatchForgivenessStuds then
		return
	end

	local result = getSession().catchRuby()
	if not result.Accepted then
		return
	end

	activeRuby:SetAttribute("RubyState", "Held")
	activeRuby.CanCollide = false
	activeRuby.Anchored = false
	local attached = false
	if carryAdapter then
		attached = carryAdapter.AttachRubyToPlayer(player, activeRuby)
	end
	if not attached then
		attached = attachRubyToDefaultHand(player)
	end
	if not attached then
		dropRuby()
		return
	end

	local recovery = recoverPrompt
	if recovery then
		recovery.Enabled = false
	end
	recordResult(result)
end

dropRuby = function()
	local activeRuby = getRuby()
	local currentState = getSession().getSnapshot().State
	if currentState ~= "DetachedAirborne" and currentState ~= "Held" then
		return
	end
	local wasHeld = currentState == "Held"
	removeDefaultCarryWeld()
	if wasHeld and carryAdapter and activePlayer then
		-- The adapter owns its own hand weld and may no-op for the isolated
		-- prototype. The state transition remains authoritative here.
		carryAdapter.DetachRubyFromPlayer(activePlayer, activeRuby)
	end
	activeRuby.Parent = getPrototype()
	activeRuby.Name = "DroppedRuby"
	activeRuby.Anchored = false
	activeRuby.CanCollide = true
	activeRuby.CanTouch = true
	activeRuby.CanQuery = true
	activeRuby:SetAttribute("Grounded", false)
	local result = getSession().dropRuby()
	if not result.Accepted then
		return
	end
	activePlayer = nil
	activeRuby:SetAttribute("RubyState", "RecoverableGround")
	recordResult(result)
	local activeConfig = getConfig()
	task.delay(activeConfig.RecoverySettleSeconds, function()
		if not activeRuby.Parent or getSession().getSnapshot().State ~= "RecoverableGround" then
			return
		end
		activeRuby:SetAttribute("Grounded", true)
		local recovery = recoverPrompt
		if recovery then
			recovery.Enabled = true
		end
	end)
end

local function recoverRuby(player: Player)
	local activeRuby = getRuby()
	if activeRuby:GetAttribute("Grounded") ~= true then
		return
	end
	local rootPart = getPlayerRoot(player)
	if not rootPart then
		return
	end
	local distance = (rootPart.Position - activeRuby.Position).Magnitude
	local result = getSession().recoverRuby(distance, true)
	if not result.Accepted then
		return
	end
	activePlayer = player
	activeRuby:SetAttribute("Grounded", false)
	activeRuby:SetAttribute("RubyState", "Held")
	local recovery = recoverPrompt
	if recovery then
		recovery.Enabled = false
	end
	local attached = false
	if carryAdapter then
		attached = carryAdapter.AttachRubyToPlayer(player, activeRuby)
	end
	if not attached then
		attached = attachRubyToDefaultHand(player)
	end
	if not attached then
		dropRuby()
		return
	end
	recordResult(result)
end

local function resetRubyToSource()
	local activeRuby = getRuby()
	local activeSource = sourceCFrame
	assert(activeSource, "P1 source CFrame is missing")
	removeDefaultCarryWeld()
	activeRuby.Parent = getPrototype()
	activeRuby.Name = "AttachedRuby"
	activeRuby.CFrame = activeSource
	activeRuby.AssemblyLinearVelocity = Vector3.zero
	activeRuby.AssemblyAngularVelocity = Vector3.zero
	activeRuby:SetAttribute("Grounded", false)
	activeRuby:SetAttribute("RubyState", "Attached")
	activeRuby:SetAttribute("GripUserId", 0)
	createTether()
	local prompt = gripPrompt
	if prompt then
		prompt.Enabled = true
		prompt.ActionText = "Grip Ruby"
	end
	local recovery = recoverPrompt
	if recovery then
		recovery.Enabled = false
	end
	activePlayer = nil
	setStateAttributes()
end

local function handleRubyTouched(hit: BasePart)
	local currentState = getSession().getSnapshot().State
	local player = playerFromHit(hit)
	if currentState == "DetachedAirborne" and player then
		catchRuby(player)
		return
	end
	if currentState == "DetachedAirborne" and hit:IsDescendantOf(getPrototype()) and hit ~= getRuby() then
		dropRuby()
	end
end

local function handleHeartbeat()
	local activeSession = getSession()
	local snapshot = activeSession.getSnapshot()
	local now = os.clock()
	local activeConfig = getConfig()

	if snapshot.State == "Gripped" and activePlayer then
		-- Triggered performs Roblox's server-side prompt distance validation, but
		-- the grip persists across heartbeats. Revalidate reach continuously so a
		-- player cannot begin legitimately and then pull the branch from afar.
		local rootPart = getPlayerRoot(activePlayer)
		local activeAttachment = branchAttachment
		if not rootPart
			or not activeAttachment
			or (rootPart.Position - activeAttachment.WorldPosition).Magnitude > activeConfig.Tuning.BranchReachStuds + 0.5
		then
			releaseGrip(activePlayer)
			return
		end

		local updatePeriod = 1 / activeConfig.TensionUpdateHz
		if now - lastTensionUpdate >= updatePeriod then
			lastTensionUpdate = now
			local input = gripInput(activePlayer)
			if input then
				local result = activeSession.updateGrip(input)
				if result.Accepted then
					if result.Sample then
						bendBranch(result.Sample)
					end
					recordResult(result)
					if result.State == "DetachedAirborne" then
						detachRuby(activePlayer, result)
					end
				end
			end
		end
	elseif snapshot.State == "RecoverableGround" then
		local activeRuby = getRuby()
		local activeSource = sourceCFrame
		if activeRuby:GetAttribute("Grounded") == true and activeSource then
			local outsideRecovery = (activeRuby.Position - activeSource.Position).Magnitude > activeConfig.Tuning.RecoveryDistanceStuds
			local settled = activeRuby.AssemblyLinearVelocity.Magnitude < 0.35
			if outsideRecovery and settled then
				local result = activeSession.recoverOutOfBounds(true, true)
				if result.Accepted then
					recordResult(result)
					resetRubyToSource()
				end
			end
		end
	end
end

function P1SpringyBranchService.BindCarryAdapter(adapter: CarryAdapter?)
	carryAdapter = adapter
end

function P1SpringyBranchService.TryServe(player: Player): (boolean, string?)
	if not started then
		return false, "P1Disabled"
	end
	if activePlayer ~= player then
		return false, "NotActivePlayer"
	end

	local activeRuby = getRuby()
	local result = getSession().serveRuby()
	if not result.Accepted then
		return false, result.Reason
	end
	if carryAdapter then
		carryAdapter.PrepareRubyForServe(player, activeRuby)
	end
	activeRuby:SetAttribute("RubyState", "Served")
	recordResult(result)
	return true, nil
end

function P1SpringyBranchService.GetSnapshot()
	if not started or not session then
		return nil
	end
	return session.getSnapshot()
end

function P1SpringyBranchService.Start(requestedConfig: P1Config?): string
	if started then
		return "AlreadyStarted"
	end

	local activeConfig = requestedConfig
	if not activeConfig or not activeConfig.Enabled then
		return "Disabled"
	end
	if activeConfig.StudioOnly and not RunService:IsStudio() then
		return "StudioOnly"
	end
	assert(activeConfig.TensionUpdateHz > 0, "P1 TensionUpdateHz must be positive")
	assert(activeConfig.RecoverySettleSeconds > 0, "P1 RecoverySettleSeconds must be positive")

	config = activeConfig
	session = P1SpringyBranch.newSession(activeConfig.Tuning)
	buildPrototype()
	started = true

	local prompt = gripPrompt
	assert(prompt, "P1 grip prompt was not created")
	prompt.Triggered:Connect(beginGrip)
	prompt.TriggerEnded:Connect(releaseGrip)

	local recovery = recoverPrompt
	assert(recovery, "P1 recovery prompt was not created")
	recovery.Triggered:Connect(recoverRuby)

	local activeRuby = ruby
	assert(activeRuby, "P1 Ruby was not created")
	table.insert(connections, activeRuby.Touched:Connect(handleRubyTouched))
	table.insert(connections, RunService.Heartbeat:Connect(handleHeartbeat))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player)
		if activePlayer ~= player then
			return
		end
		local currentState = getSession().getSnapshot().State
		if currentState ~= "Served" and currentState ~= "Abandoned" then
			local result = getSession().abandon("PlayerRemoving")
			recordResult(result)
		end
		activePlayer = nil
	end))

	return "Ready"
end

return P1SpringyBranchService
