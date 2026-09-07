--!strict

-- Local responsive-water presentation for the Studio-only Physics Lab.
-- Server code still owns wash progress and soap state. This script only turns
-- cursor/object movement into a small spring surface so the basin is no longer
-- a motionless glass block.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

type CellState = {
	Part: BasePart,
	BaseCFrame: CFrame,
	Height: number,
	Velocity: number,
	Row: number,
	Column: number,
}

local LAB_NAME = "PipiLabuPhysicsLab"
local cells: { CellState } = {}
local cellByGrid: { [string]: CellState } = {}
local activeLab: Instance? = nil
local waterSensor: BasePart? = nil
local washApple: BasePart? = nil
local function viewportPointer(): Vector2
	return UserInputService:GetMouseLocation()
end

local lastPointer = viewportPointer()
local lastApplePosition: Vector3? = nil
local lastSoapPulseAt = 0

local function findJourneyApple(lab: Instance): BasePart?
	for _, child in lab:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("LabRole") == "JourneyApple" then
			return child
		end
	end
	return nil
end

local function gridKey(row: number, column: number): string
	return string.format("%d:%d", row, column)
end

local function clearBinding()
	for _, state in cells do
		if state.Part.Parent then
			state.Part.CFrame = state.BaseCFrame
		end
	end
	table.clear(cells)
	table.clear(cellByGrid)
	activeLab = nil
	waterSensor = nil
	washApple = nil
	lastApplePosition = nil
end

local function bindLab(lab: Instance)
	clearBinding()
	local sensor = lab:FindFirstChild("WashWaterSensor")
	local surface = lab:FindFirstChild("WashWaterSurface")
	if not sensor or not sensor:IsA("BasePart") or not surface then
		return
	end

	local newCells: { CellState } = {}
	for _, child in surface:GetChildren() do
		if child:IsA("BasePart") then
			local row = child:GetAttribute("WaterRow")
			local column = child:GetAttribute("WaterColumn")
			local baseCFrame = child:GetAttribute("BaseCFrame")
			if type(row) == "number" and type(column) == "number" and typeof(baseCFrame) == "CFrame" then
				table.insert(newCells, {
					Part = child,
					BaseCFrame = baseCFrame,
					Height = 0,
					Velocity = 0,
					Row = row,
					Column = column,
				})
			end
		end
	end
	table.sort(newCells, function(left, right)
		return left.Part.Name < right.Part.Name
	end)

	cells = newCells
	for _, state in cells do
		cellByGrid[gridKey(state.Row, state.Column)] = state
	end
	activeLab = lab
	waterSensor = sensor
	washApple = findJourneyApple(lab)
	lastPointer = viewportPointer()
	lastApplePosition = washApple and washApple.Position or nil
end

local function nearestCell(worldPosition: Vector3): CellState?
	local best: CellState? = nil
	local bestDistance = math.huge
	for _, state in cells do
		local flatOffset = Vector2.new(state.Part.Position.X - worldPosition.X, state.Part.Position.Z - worldPosition.Z)
		local distance = flatOffset.Magnitude
		if distance < bestDistance then
			bestDistance = distance
			best = state
		end
	end
	return best
end

local function disturb(worldPosition: Vector3, strength: number)
	local state = nearestCell(worldPosition)
	if state then
		state.Velocity += math.clamp(strength, -5, 5)
	end
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.IgnoreWater = true

local function cursorWaterPoint(): Vector3?
	local sensor = waterSensor
	local camera = Workspace.CurrentCamera
	if not sensor or not camera then
		return nil
	end
	raycastParams.FilterDescendantsInstances = { sensor }
	local pointer = viewportPointer()
	local ray = camera:ViewportPointToRay(pointer.X, pointer.Y)
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 256, raycastParams)
	return hit and hit.Position or nil
end

local function updateBindings()
	local current = Workspace:FindFirstChild(LAB_NAME)
	if current ~= activeLab then
		if current then
			bindLab(current)
		else
			clearBinding()
		end
	end
end

RunService.RenderStepped:Connect(function(deltaTime)
	updateBindings()
	local sensor = waterSensor
	if not sensor or #cells == 0 then
		return
	end

	local pointer = viewportPointer()
	local pointerSpeed = (pointer - lastPointer).Magnitude / math.max(deltaTime, 1 / 240)
	lastPointer = pointer
	local cursorPoint = cursorWaterPoint()
	if cursorPoint and pointerSpeed > 18 then
		disturb(cursorPoint, -math.clamp(pointerSpeed / 700, 0.2, 1.8))
	end

	local apple = washApple
	if apple and apple.Parent then
		local previous = lastApplePosition or apple.Position
		local motion = (apple.Position - previous).Magnitude / math.max(deltaTime, 1 / 240)
		lastApplePosition = apple.Position
		local localApple = sensor.CFrame:PointToObjectSpace(apple.Position)
		local half = sensor.Size * 0.5
		if math.abs(localApple.X) <= half.X and math.abs(localApple.Z) <= half.Z and math.abs(localApple.Y) <= 1.25 and motion > 0.4 then
			disturb(apple.Position, -math.clamp(motion / 12, 0.25, 2.4))
		end
	end

	if sensor:GetAttribute("SoapPouring") == true and os.clock() - lastSoapPulseAt > 0.08 then
		lastSoapPulseAt = os.clock()
		local soap = activeLab and activeLab:FindFirstChild("SoapNozzle")
		if soap and soap:IsA("BasePart") then
			disturb(soap.Position, -0.55)
		end
	end

	local nextHeights: { [CellState]: number } = {}
	for _, state in cells do
		local neighborTotal = 0
		local neighborCount = 0
		for _, offset in {
			{ 0, -1 },
			{ 0, 1 },
			{ -1, 0 },
			{ 1, 0 },
		} do
			local neighbor = cellByGrid[gridKey(state.Row + offset[1], state.Column + offset[2])]
			if neighbor then
				neighborTotal += neighbor.Height
				neighborCount += 1
			end
		end
		local neighborAverage = if neighborCount > 0 then neighborTotal / neighborCount else 0
		local acceleration = -state.Height * 52 - state.Velocity * 8 + (neighborAverage - state.Height) * 28
		state.Velocity += acceleration * deltaTime
		nextHeights[state] = math.clamp(state.Height + state.Velocity * deltaTime, -0.24, 0.24)
	end

	for _, state in cells do
		state.Height = nextHeights[state]
		local left = cellByGrid[gridKey(state.Row, state.Column - 1)]
		local right = cellByGrid[gridKey(state.Row, state.Column + 1)]
		local back = cellByGrid[gridKey(state.Row - 1, state.Column)]
		local front = cellByGrid[gridKey(state.Row + 1, state.Column)]
		local slopeX = ((right and right.Height or state.Height) - (left and left.Height or state.Height)) * 0.7
		local slopeZ = ((front and front.Height or state.Height) - (back and back.Height or state.Height)) * 0.7
		state.Part.CFrame = state.BaseCFrame
			* CFrame.new(0, state.Height, 0)
			* CFrame.Angles(-slopeZ, 0, slopeX)
	end
end)
