--!strict

-- Immediate local manipulation for the Studio-only Physics Lab. The pointer
-- owns the held pose every rendered frame, so moving the character/camera also
-- moves the object instead of leaving it stranded on a world-space plane.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

type DragTarget = BasePart | Model

local LAB_NAME = "PipiLabuPhysicsLab"
local activeTarget: DragTarget? = nil
local dragMode = "Translate"
local dragDepth = 8
local startPointer = Vector2.zero
local startPivot = CFrame.identity
local lastTargetPosition: Vector3? = nil
local cleanProgress = 0
local soapFill = 0
local lastSoapDropAt = 0
local pluckRequested = false
local soapReported = false
local lastWashReportAt = 0

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.IgnoreWater = true
local sensorRaycastParams = RaycastParams.new()
sensorRaycastParams.FilterType = Enum.RaycastFilterType.Include
sensorRaycastParams.IgnoreWater = true

local function viewportPointer(): Vector2
	return UserInputService:GetMouseLocation()
end

local function pointerRay(): Ray?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local pointer = viewportPointer()
	return camera:ViewportPointToRay(pointer.X, pointer.Y)
end

local function currentLab(): Instance?
	return Workspace:FindFirstChild(LAB_NAME)
end

local function resolveTarget(instance: Instance): DragTarget?
	local lab = currentLab()
	if not lab then
		return nil
	end
	local proxyName = instance:GetAttribute("ClientDragProxy")
	if type(proxyName) == "string" then
		local proxy = lab:FindFirstChild(proxyName)
		if proxy and proxy:IsA("BasePart") and proxy:GetAttribute("ClientControlledDrag") == true then
			return proxy
		end
	end

	local cursor: Instance? = instance
	while cursor and cursor ~= lab do
		if (cursor:IsA("BasePart") or cursor:IsA("Model")) and cursor:GetAttribute("ClientControlledDrag") == true then
			return cursor
		end
		cursor = cursor.Parent
	end
	return nil
end

local function targetFromPointer(): (DragTarget?, Vector3?)
	local lab = currentLab()
	local ray = pointerRay()
	if not lab or not ray then
		return nil, nil
	end
	raycastParams.FilterDescendantsInstances = { lab }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 256, raycastParams)
	if not hit then
		return nil, nil
	end
	return resolveTarget(hit.Instance), hit.Position
end

local function targetPosition(target: DragTarget): Vector3
	return target:GetPivot().Position
end

local function isJourneyApple(target: DragTarget): boolean
	return target:IsA("BasePart") and target:GetAttribute("LabRole") == "JourneyApple"
end

local function insideSensor(sensor: BasePart, worldPosition: Vector3, verticalAllowance: number): boolean
	local localPosition = sensor.CFrame:PointToObjectSpace(worldPosition)
	local half = sensor.Size * 0.5
	return math.abs(localPosition.X) <= half.X
		and math.abs(localPosition.Z) <= half.Z
		and math.abs(localPosition.Y) <= verticalAllowance
end

local function setTargetActive(target: DragTarget, active: boolean)
	target:SetAttribute("DragActive", active)
	if target:IsA("BasePart") then
		target.AssemblyLinearVelocity = Vector3.zero
		target.AssemblyAngularVelocity = Vector3.zero
	end
end

local function setPluckLabel(text: string)
	local lab = currentLab()
	local branch = lab and lab:FindFirstChild("SpringBranch")
	local gui = branch and branch:FindFirstChild("PluckStatus")
	local label = gui and gui:FindFirstChild("Text")
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function makePopRing(position: Vector3)
	local lab = currentLab()
	if not lab then
		return
	end
	local ring = Instance.new("Part")
	ring.Name = "LocalPluckPulse"
	ring.Shape = Enum.PartType.Ball
	ring.Size = Vector3.new(0.3, 0.3, 0.3)
	ring.Position = position
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 221, 137)
	ring.Transparency = 0.35
	ring.Parent = lab
	TweenService:Create(ring, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(2.5, 2.5, 2.5),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 0.32)

	local sound = Instance.new("Sound")
	sound.Name = "LocalPluckPop"
	sound.SoundId = "rbxassetid://7381723941"
	sound.Volume = 0.24
	sound.PlaybackSpeed = 1.12
	sound.Parent = ring
	sound:Play()
end

local function performPredictedPluck(target: DragTarget, tension: number)
	if not isJourneyApple(target) or target:GetAttribute("JourneyState") ~= "AttachedDirty" or pluckRequested then
		return
	end
	pluckRequested = true
	target:SetAttribute("PluckPredicted", true)
	target:SetAttribute("StemTension", 1)
	setPluckLabel("A  |  POP! • RELEASE OR TOSS")
	makePopRing(targetPosition(target))

	for _, descendant in target:GetDescendants() do
		if descendant:IsA("Beam") then
			descendant.Enabled = false
		end
	end
	local lab = currentLab()
	local event = lab and lab:FindFirstChild("PhysicsLabEvent")
	if event and event:IsA("RemoteEvent") then
		event:FireServer("Pluck", target, tension)
	end
end

local function beginDrag()
	local target, hitPosition = targetFromPointer()
	local camera = Workspace.CurrentCamera
	if not target or not hitPosition or not camera then
		return
	end
	activeTarget = target
	dragMode = tostring(target:GetAttribute("ClientDragMode") or "Translate")
	startPointer = viewportPointer()
	startPivot = target:GetPivot()
	dragDepth = math.max(2, (hitPosition - camera.CFrame.Position):Dot(camera.CFrame.LookVector))
	lastTargetPosition = targetPosition(target)
	pluckRequested = target:GetAttribute("PluckPredicted") == true or target:GetAttribute("Plucked") == true
	if isJourneyApple(target) then
		cleanProgress = tonumber(target:GetAttribute("CleanProgress")) or 0
	end
	local lab = currentLab()
	local sensor = lab and lab:FindFirstChild("WashWaterSensor")
	if target.Name == "SoapBottle" and sensor and sensor:IsA("BasePart") then
		soapFill = tonumber(sensor:GetAttribute("SoapFill")) or 0
		soapReported = sensor:GetAttribute("Soapy") == true
	end
	setTargetActive(target, true)
end

local function finishDrag()
	local target = activeTarget
	if target then
		if isJourneyApple(target) and target:GetAttribute("JourneyState") == "AttachedDirty" and target:GetAttribute("PluckPredicted") ~= true then
			local rest = target:GetAttribute("PluckRestPosition")
			if typeof(rest) == "Vector3" then
				local rebound = TweenService:Create(target, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					CFrame = CFrame.new(rest) * startPivot.Rotation,
				})
				rebound:Play()
			end
			target:SetAttribute("StemTension", 0)
			setPluckLabel("A  |  GRAB APPLE • PULL")
		end
		setTargetActive(target, false)
		if target.Name == "SoapBottle" then
			target:SetAttribute("Pouring", false)
		end
		if isJourneyApple(target) and target:GetAttribute("JourneyState") == "Clean" then
			local lab = currentLab()
			local crate = lab and lab:FindFirstChild("PhysicsCrate")
			local crateSensor = crate and crate:FindFirstChild("CrateInteriorSensor")
			local event = lab and lab:FindFirstChild("PhysicsLabEvent")
			if crateSensor and crateSensor:IsA("BasePart") and insideSensor(crateSensor, targetPosition(target), 1.4) and event and event:IsA("RemoteEvent") then
				target:SetAttribute("JourneyState", "Crating")
				target.Anchored = false
				event:FireServer("Crate", target, targetPosition(target))
			end
		end
	end
	local lab = currentLab()
	local sensor = lab and lab:FindFirstChild("WashWaterSensor")
	if sensor and sensor:IsA("BasePart") then
		sensor:SetAttribute("SoapPouring", false)
	end
	activeTarget = nil
	lastTargetPosition = nil
	pluckRequested = false
end

local function pointerHitsSensor(sensor: BasePart): boolean
	local ray = pointerRay()
	if not ray then
		return false
	end
	sensorRaycastParams.FilterDescendantsInstances = { sensor }
	return Workspace:Raycast(ray.Origin, ray.Direction * 256, sensorRaycastParams) ~= nil
end

local function updateDirt(lab: Instance, transparency: number)
	for _, child in lab:GetChildren() do
		if child:IsA("BasePart") and string.match(child.Name, "^JourneyDirt_") then
			child.LocalTransparencyModifier = transparency
		end
	end
end

local function makeSoapDrop(lab: Instance, position: Vector3)
	local drop = Instance.new("Part")
	drop.Name = "LocalSoapDrop"
	drop.Shape = Enum.PartType.Ball
	drop.Size = Vector3.new(0.13, 0.13, 0.13)
	drop.Position = position
	drop.Anchored = false
	drop.CanCollide = false
	drop.CanTouch = false
	drop.CanQuery = false
	drop.Color = Color3.fromRGB(247, 236, 194)
	drop.Material = Enum.Material.Glass
	drop.Transparency = 0.1
	drop.AssemblyLinearVelocity = Vector3.new(0, -5.5, 0)
	drop.Parent = lab
	Debris:AddItem(drop, 0.7)
end

local function updateInteractionPresentation(target: DragTarget, deltaTime: number)
	local lab = currentLab()
	if not lab then
		return
	end
	local sensor = lab:FindFirstChild("WashWaterSensor")
	if not sensor or not sensor:IsA("BasePart") then
		return
	end

	local position = targetPosition(target)
	local previous = lastTargetPosition or position
	local movement = (position - previous).Magnitude
	lastTargetPosition = position

	if isJourneyApple(target) and (target:GetAttribute("JourneyState") == "PluckedDirty" or target:GetAttribute("JourneyState") == "WashingDirty") and insideSensor(sensor, position, 1.35) then
		target:SetAttribute("JourneyState", "WashingDirty")
		if sensor:GetAttribute("Soapy") ~= true then
			return
		end
		cleanProgress = math.clamp(cleanProgress + movement * 0.18, 0, 1)
		target:SetAttribute("CleanProgress", cleanProgress)
		updateDirt(lab, cleanProgress)
		if os.clock() - lastWashReportAt >= 0.1 or cleanProgress >= 1 then
			lastWashReportAt = os.clock()
			local event = lab:FindFirstChild("PhysicsLabEvent")
			if event and event:IsA("RemoteEvent") then
				event:FireServer("WashProgress", target, cleanProgress)
			end
		end
		if cleanProgress >= 1 then
			target:SetAttribute("JourneyState", "Clean")
		end
	elseif target.Name == "SoapBottle" then
		local nozzle = lab:FindFirstChild("SoapNozzle")
		local nozzlePosition = if nozzle and nozzle:IsA("BasePart") then nozzle.Position else position
		local pouring = insideSensor(sensor, nozzlePosition, 4.5) or pointerHitsSensor(sensor)
		target:SetAttribute("Pouring", pouring)
		sensor:SetAttribute("SoapPouring", pouring)
		if pouring then
			soapFill = math.clamp(soapFill + deltaTime * 0.9, 0, 1)
			sensor:SetAttribute("SoapFill", soapFill)
			if os.clock() - lastSoapDropAt > 0.06 then
				lastSoapDropAt = os.clock()
				makeSoapDrop(lab, nozzlePosition)
			end
			if soapFill >= 0.35 then
				sensor:SetAttribute("Soapy", true)
				if not soapReported then
					soapReported = true
					local event = lab:FindFirstChild("PhysicsLabEvent")
					if event and event:IsA("RemoteEvent") then
						event:FireServer("SoapPour", target, soapFill)
					end
				end
				local surface = lab:FindFirstChild("WashWaterSurface")
				if surface then
					surface:SetAttribute("Soapy", true)
					for _, cell in surface:GetChildren() do
						if cell:IsA("BasePart") then
							cell.Color = Color3.fromRGB(183, 224, 222)
						end
					end
				end
			end
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	-- Studio can mark viewport mouse input processed even when the pointer is
	-- directly over a 3D lab prop. Honor that click only when our bounded lab
	-- raycast resolves a client-controlled target; unrelated UI clicks remain
	-- inert because beginDrag performs the same target check.
	if gameProcessed and select(1, targetFromPointer()) == nil then
		return
	end
	beginDrag()
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		finishDrag()
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	local target = activeTarget
	local ray = pointerRay()
	if not target or not target.Parent or not ray then
		return
	end

	if dragMode == "RotateHingeX" then
		local pointerDelta = viewportPointer() - startPointer
		local angle = math.clamp(-pointerDelta.Y * 0.012, math.rad(-4), math.rad(105))
		target:PivotTo(startPivot * CFrame.Angles(angle, 0, 0))
	elseif dragMode == "PluckSpring" then
		local desiredPosition = ray.Origin + ray.Direction * dragDepth
		local alreadyPlucked = target:GetAttribute("Plucked") == true or target:GetAttribute("PluckPredicted") == true
		if alreadyPlucked then
			target:PivotTo(CFrame.new(desiredPosition) * startPivot.Rotation)
		else
			local rest = target:GetAttribute("PluckRestPosition")
			local threshold = target:GetAttribute("PluckTravelThreshold")
			local maxTravel = target:GetAttribute("PluckMaxTravel")
			if typeof(rest) ~= "Vector3" or type(threshold) ~= "number" or type(maxTravel) ~= "number" then
				return
			end
			local delta = desiredPosition - rest
			local pointerTravel = delta.Magnitude
			local direction = if delta.Magnitude > 0.001 then delta.Unit else Vector3.zero
			local tension = math.clamp(pointerTravel / threshold, 0, 1)
			-- The pointer gets ahead of the fruit while the stem visibly stretches.
			-- This reduced-follow curve keeps the apple elastic instead of rigidly
			-- gluing it to the cursor, then releases only after a longer pull.
			local followRatio = 0.2 + 0.4 * (tension ^ 1.5)
			local appleTravel = math.min(pointerTravel * followRatio, maxTravel)
			target:PivotTo(CFrame.new(rest + direction * appleTravel) * startPivot.Rotation)
			target:SetAttribute("StemTension", tension)
			setPluckLabel(string.format("A  |  STRETCH %d%%", math.floor(tension * 100 + 0.5)))
			if tension >= 1 then
				performPredictedPluck(target, tension)
			end
		end
	else
		-- The held prop lives on a camera-facing plane at its picked depth. This
		-- keeps it under the pointer, follows camera/player movement, and allows
		-- vertical motion into the basin instead of trapping it at its spawn Y.
		local desiredPosition = ray.Origin + ray.Direction * dragDepth
		target:PivotTo(CFrame.new(desiredPosition) * startPivot.Rotation)
	end
	updateInteractionPresentation(target, deltaTime)
end)
