--!strict

-- Native Roblox realization of Leo and Jon's approved Pipi Labu HUD board.
-- The board is direction, not a texture atlas: this view rebuilds its warm
-- medallion language with accessible Roblox UI primitives at any resolution.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

export type RenderState = {
	HasApple: boolean,
	HeldAppleColor: Color3,
	ShiftState: string,
	TimeText: string,
	ServedText: string,
	MissedText: string,
	Instruction: string,
	StartText: string,
	NextShiftText: string,
	RetryText: string,
	ShiftWonText: string,
	ShiftLostText: string,
}

local HudView = {}
HudView.__index = HudView

local WARM_GOLD = Color3.fromRGB(226, 177, 94)
local LIGHT_GOLD = Color3.fromRGB(250, 220, 151)
local CREAM = Color3.fromRGB(255, 241, 213)
local MUTED_CREAM = Color3.fromRGB(215, 199, 171)
local DARK_INK = Color3.fromRGB(39, 32, 27)
local DARK_WOOD = Color3.fromRGB(77, 52, 36)
local RUBY = Color3.fromRGB(190, 58, 48)
local SUCCESS = Color3.fromRGB(111, 158, 95)

local function addCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addStroke(parent: Instance, color: Color3, thickness: number, transparency: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	stroke.Parent = parent
	return stroke
end

local function addGradient(parent: Instance, top: Color3, bottom: Color3, rotation: number?)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(top, bottom)
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
end

local function makeLine(parent: Instance, size: UDim2, position: UDim2, rotation: number, color: Color3): Frame
	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = position
	line.Size = size
	line.Rotation = rotation
	line.BackgroundColor3 = color
	line.BorderSizePixel = 0
	line.Parent = parent
	addCorner(line, 3)
	return line
end

local function drawClock(parent: Instance)
	local center = Instance.new("Frame")
	center.AnchorPoint = Vector2.new(0.5, 0.5)
	center.Position = UDim2.fromScale(0.5, 0.5)
	center.Size = UDim2.fromOffset(5, 5)
	center.BackgroundColor3 = LIGHT_GOLD
	center.BorderSizePixel = 0
	center.Parent = parent
	addCorner(center, 3)
	makeLine(parent, UDim2.fromOffset(3, 13), UDim2.fromScale(0.5, 0.39), 0, LIGHT_GOLD)
	makeLine(parent, UDim2.fromOffset(3, 11), UDim2.fromScale(0.58, 0.54), 53, LIGHT_GOLD)
end

local function drawPaw(parent: Instance)
	local pad = Instance.new("Frame")
	pad.AnchorPoint = Vector2.new(0.5, 0.5)
	pad.Position = UDim2.fromScale(0.5, 0.62)
	pad.Size = UDim2.fromOffset(19, 14)
	pad.BackgroundColor3 = LIGHT_GOLD
	pad.BorderSizePixel = 0
	pad.Parent = parent
	addCorner(pad, 8)
	for _, point in {
		Vector2.new(0.32, 0.34),
		Vector2.new(0.45, 0.25),
		Vector2.new(0.59, 0.25),
		Vector2.new(0.70, 0.36),
	} do
		local toe = Instance.new("Frame")
		toe.AnchorPoint = Vector2.new(0.5, 0.5)
		toe.Position = UDim2.fromScale(point.X, point.Y)
		toe.Size = UDim2.fromOffset(7, 9)
		toe.BackgroundColor3 = LIGHT_GOLD
		toe.BorderSizePixel = 0
		toe.Parent = parent
		addCorner(toe, 5)
	end
end

local function drawCross(parent: Instance)
	makeLine(parent, UDim2.fromOffset(4, 25), UDim2.fromScale(0.5, 0.5), 45, LIGHT_GOLD)
	makeLine(parent, UDim2.fromOffset(4, 25), UDim2.fromScale(0.5, 0.5), -45, LIGHT_GOLD)
end

local function makeIconDisc(parent: Instance, name: string, position: UDim2): (Frame, UIStroke)
	local disc = Instance.new("Frame")
	disc.Name = name
	disc.Position = position
	disc.Size = UDim2.fromOffset(48, 48)
	disc.BackgroundColor3 = DARK_INK
	disc.BackgroundTransparency = 0.08
	disc.BorderSizePixel = 0
	disc.Parent = parent
	addCorner(disc, 24)
	local stroke = addStroke(disc, WARM_GOLD, 2, 0.05)

	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.new(1, -9, 1, -9)
	inner.BackgroundTransparency = 1
	inner.Parent = disc
	addCorner(inner, 20)
	addStroke(inner, Color3.fromRGB(130, 94, 55), 1, 0.25)
	return inner, stroke
end

local function makeStat(parent: Instance, name: string, x: number, labelText: string, icon: string): (TextLabel, UIStroke)
	local group = Instance.new("Frame")
	group.Name = name
	group.Position = UDim2.fromOffset(x, 0)
	group.Size = UDim2.fromOffset(76, 94)
	group.BackgroundTransparency = 1
	group.Parent = parent

	local iconFace, stroke = makeIconDisc(group, "Medallion", UDim2.fromOffset(14, 0))
	if icon == "Clock" then
		drawClock(iconFace)
	elseif icon == "Paw" then
		drawPaw(iconFace)
	else
		drawCross(iconFace)
	end

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Position = UDim2.fromOffset(0, 52)
	label.Size = UDim2.fromOffset(76, 15)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.BuilderSansBold
	label.Text = labelText
	label.TextColor3 = MUTED_CREAM
	label.TextSize = 10
	label.TextStrokeColor3 = Color3.fromRGB(35, 27, 22)
	label.TextStrokeTransparency = 0.22
	label.Parent = group

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Position = UDim2.fromOffset(-4, 67)
	value.Size = UDim2.fromOffset(84, 25)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.BuilderSansExtraBold
	value.Text = "0"
	value.TextColor3 = CREAM
	value.TextSize = 20
	value.TextStrokeColor3 = Color3.fromRGB(35, 27, 22)
	value.TextStrokeTransparency = 0.18
	value.Parent = group
	return value, stroke
end

local function makeButton(parent: Instance, name: string, position: UDim2, size: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.AutoButtonColor = false
	button.BackgroundColor3 = DARK_WOOD
	button.BorderSizePixel = 0
	button.Font = Enum.Font.BuilderSansBold
	button.TextColor3 = CREAM
	button.TextSize = 13
	button.TextStrokeColor3 = Color3.fromRGB(35, 27, 22)
	button.TextStrokeTransparency = 0.32
	button.Parent = parent
	addCorner(button, 8)
	addStroke(button, WARM_GOLD, 1.5, 0.18)
	local depth = Instance.new("UIGradient")
	depth.Name = "ButtonDepth"
	depth.Rotation = 90
	depth.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.02),
		NumberSequenceKeypoint.new(1, 0.18),
	})
	depth.Parent = button
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), { BackgroundTransparency = 0.06 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.14), { BackgroundTransparency = 0 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.06), { BackgroundTransparency = 0.14 }):Play()
	end)
	return button
end

function HudView.new(playerGui: PlayerGui, labels: { Time: string, Served: string, Missed: string, Celebration: string })
	local existing = playerGui:FindFirstChild("DogeAppleHUD")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DogeAppleHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui

	local status = Instance.new("Frame")
	status.Name = "StatusMedallions"
	status.Position = UDim2.fromOffset(20, 14)
	status.Size = UDim2.fromOffset(244, 136)
	status.BackgroundTransparency = 1
	status.Parent = screenGui

	local statusScale = Instance.new("UIScale")
	statusScale.Name = "FeedbackScale"
	statusScale.Parent = status

	local timeValue = makeStat(status, "Time", 0, labels.Time, "Clock")
	local servedValue, servedStroke = makeStat(status, "Served", 84, labels.Served, "Paw")
	local missedValue = makeStat(status, "Missed", 168, labels.Missed, "Cross")

	local notice = Instance.new("Frame")
	notice.Name = "ContextNotice"
	notice.Position = UDim2.fromOffset(0, 98)
	notice.Size = UDim2.fromOffset(244, 32)
	notice.BackgroundColor3 = DARK_INK
	notice.BackgroundTransparency = 0.13
	notice.BorderSizePixel = 0
	notice.Parent = status
	addCorner(notice, 9)
	addStroke(notice, Color3.fromRGB(137, 102, 66), 1, 0.35)

	local appleDot = Instance.new("Frame")
	appleDot.Name = "AppleState"
	appleDot.Position = UDim2.fromOffset(10, 9)
	appleDot.Size = UDim2.fromOffset(14, 14)
	appleDot.BackgroundColor3 = Color3.fromRGB(116, 105, 92)
	appleDot.BorderSizePixel = 0
	appleDot.Parent = notice
	addCorner(appleDot, 7)
	addStroke(appleDot, CREAM, 1, 0.38)

	local instruction = Instance.new("TextLabel")
	instruction.Name = "Instruction"
	instruction.Position = UDim2.fromOffset(32, 0)
	instruction.Size = UDim2.new(1, -40, 1, 0)
	instruction.BackgroundTransparency = 1
	instruction.Font = Enum.Font.BuilderSansMedium
	instruction.TextColor3 = CREAM
	instruction.TextSize = 12
	instruction.TextStrokeColor3 = Color3.fromRGB(35, 27, 22)
	instruction.TextStrokeTransparency = 0.38
	instruction.TextTruncate = Enum.TextTruncate.AtEnd
	instruction.TextXAlignment = Enum.TextXAlignment.Left
	instruction.Parent = notice

	local startButton = makeButton(status, "StartShift", UDim2.fromOffset(0, 98), UDim2.fromOffset(244, 34))

	local result = Instance.new("Frame")
	result.Name = "ShiftResult"
	result.AnchorPoint = Vector2.new(0.5, 0.5)
	result.Position = UDim2.fromScale(0.80, 0.61)
	result.Size = UDim2.fromOffset(226, 252)
	result.BackgroundTransparency = 1
	result.Visible = false
	result.Parent = screenGui

	local resultScale = Instance.new("UIScale")
	resultScale.Name = "RevealScale"
	resultScale.Parent = result

	local resultShadow = Instance.new("Frame")
	resultShadow.Name = "Shadow"
	resultShadow.Position = UDim2.fromOffset(37, 7)
	resultShadow.Size = UDim2.fromOffset(164, 164)
	resultShadow.BackgroundColor3 = Color3.fromRGB(27, 20, 16)
	resultShadow.BackgroundTransparency = 0.48
	resultShadow.BorderSizePixel = 0
	resultShadow.Parent = result
	addCorner(resultShadow, 82)

	local resultDisc = Instance.new("Frame")
	resultDisc.Name = "Medallion"
	resultDisc.Position = UDim2.fromOffset(31, 0)
	resultDisc.Size = UDim2.fromOffset(164, 164)
	resultDisc.BackgroundColor3 = Color3.fromRGB(153, 102, 55)
	resultDisc.BorderSizePixel = 0
	resultDisc.Parent = result
	addCorner(resultDisc, 82)
	local resultStroke = addStroke(resultDisc, WARM_GOLD, 4, 0)
	addGradient(resultDisc, Color3.fromRGB(194, 137, 70), Color3.fromRGB(112, 72, 44))

	local resultInner = Instance.new("Frame")
	resultInner.Name = "Inner"
	resultInner.AnchorPoint = Vector2.new(0.5, 0.5)
	resultInner.Position = UDim2.fromScale(0.5, 0.5)
	resultInner.Size = UDim2.new(1, -25, 1, -25)
	resultInner.BackgroundColor3 = Color3.fromRGB(134, 90, 50)
	resultInner.BackgroundTransparency = 0.08
	resultInner.BorderSizePixel = 0
	resultInner.Parent = resultDisc
	addCorner(resultInner, 70)
	addStroke(resultInner, LIGHT_GOLD, 2, 0.2)

	local resultSymbol = Instance.new("Frame")
	resultSymbol.Name = "WinSymbol"
	resultSymbol.AnchorPoint = Vector2.new(0.5, 0.5)
	resultSymbol.Position = UDim2.fromScale(0.5, 0.30)
	resultSymbol.Size = UDim2.fromOffset(56, 56)
	resultSymbol.BackgroundTransparency = 1
	resultSymbol.Parent = resultInner
	drawPaw(resultSymbol)

	local resultCross = Instance.new("Frame")
	resultCross.Name = "LossSymbol"
	resultCross.AnchorPoint = Vector2.new(0.5, 0.5)
	resultCross.Position = resultSymbol.Position
	resultCross.Size = resultSymbol.Size
	resultCross.BackgroundTransparency = 1
	resultCross.Visible = false
	resultCross.Parent = resultInner
	drawCross(resultCross)

	local resultTitle = Instance.new("TextLabel")
	resultTitle.Name = "Title"
	resultTitle.Position = UDim2.fromScale(0.08, 0.47)
	resultTitle.Size = UDim2.fromScale(0.84, 0.43)
	resultTitle.BackgroundTransparency = 1
	resultTitle.Font = Enum.Font.BuilderSansExtraBold
	resultTitle.Text = "SHIFT CLEAR"
	resultTitle.TextColor3 = CREAM
	resultTitle.TextSize = 21
	resultTitle.TextStrokeColor3 = Color3.fromRGB(61, 39, 25)
	resultTitle.TextStrokeTransparency = 0.32
	resultTitle.TextWrapped = true
	resultTitle.Parent = resultInner

	local resultButton = makeButton(result, "ResultAction", UDim2.fromOffset(18, 182), UDim2.fromOffset(190, 43))
	resultButton.TextSize = 15

	local celebration = Instance.new("TextLabel")
	celebration.Name = "Celebration"
	celebration.AnchorPoint = Vector2.new(0.5, 0.5)
	celebration.BackgroundTransparency = 1
	celebration.Font = Enum.Font.BuilderSansExtraBold
	celebration.Position = UDim2.fromScale(0.5, 0.61)
	celebration.Size = UDim2.fromOffset(300, 58)
	celebration.Text = labels.Celebration
	celebration.TextColor3 = CREAM
	celebration.TextSize = 28
	celebration.TextTransparency = 1
	celebration.Parent = screenGui

	local dialogue = Instance.new("Frame")
	dialogue.Name = "BottomDialogueSubtitle"
	dialogue.AnchorPoint = Vector2.new(0.5, 1)
	dialogue.Position = UDim2.new(0.5, 0, 1, -34)
	dialogue.Size = UDim2.new(1, -40, 0, 112)
	dialogue.BackgroundColor3 = Color3.fromRGB(31, 25, 22)
	dialogue.BackgroundTransparency = 0.08
	dialogue.BorderSizePixel = 0
	dialogue.Visible = false
	dialogue.Parent = screenGui
	addCorner(dialogue, 12)
	addStroke(dialogue, WARM_GOLD, 2, 0.14)
	local dialogueSize = Instance.new("UISizeConstraint")
	dialogueSize.MaxSize = Vector2.new(720, 112)
	dialogueSize.MinSize = Vector2.new(280, 112)
	dialogueSize.Parent = dialogue

	local speaker = Instance.new("TextLabel")
	speaker.Name = "Speaker"
	speaker.Position = UDim2.fromOffset(18, 10)
	speaker.Size = UDim2.new(1, -36, 0, 20)
	speaker.BackgroundTransparency = 1
	speaker.Font = Enum.Font.BuilderSansExtraBold
	speaker.TextColor3 = LIGHT_GOLD
	speaker.TextSize = 13
	speaker.TextXAlignment = Enum.TextXAlignment.Left
	speaker.Parent = dialogue

	local dialogueText = Instance.new("TextLabel")
	dialogueText.Name = "Dialogue"
	dialogueText.Position = UDim2.fromOffset(18, 31)
	dialogueText.Size = UDim2.new(1, -36, 0, 48)
	dialogueText.BackgroundTransparency = 1
	dialogueText.Font = Enum.Font.BuilderSansMedium
	dialogueText.TextColor3 = CREAM
	dialogueText.TextSize = 18
	dialogueText.TextWrapped = true
	dialogueText.TextXAlignment = Enum.TextXAlignment.Left
	dialogueText.TextYAlignment = Enum.TextYAlignment.Center
	dialogueText.Parent = dialogue

	local dialogueTask = Instance.new("TextLabel")
	dialogueTask.Name = "Task"
	dialogueTask.Position = UDim2.fromOffset(18, 81)
	dialogueTask.Size = UDim2.new(1, -36, 0, 20)
	dialogueTask.BackgroundTransparency = 1
	dialogueTask.Font = Enum.Font.BuilderSansBold
	dialogueTask.TextColor3 = Color3.fromRGB(230, 151, 98)
	dialogueTask.TextSize = 13
	dialogueTask.TextTruncate = Enum.TextTruncate.AtEnd
	dialogueTask.TextXAlignment = Enum.TextXAlignment.Left
	dialogueTask.Parent = dialogue

	local self = setmetatable({
		ScreenGui = screenGui,
		Status = status,
		StatusScale = statusScale,
		TimeValue = timeValue,
		ServedValue = servedValue,
		ServedStroke = servedStroke,
		MissedValue = missedValue,
		Notice = notice,
		AppleDot = appleDot,
		Instruction = instruction,
		StartButton = startButton,
		Result = result,
		ResultScale = resultScale,
		ResultStroke = resultStroke,
		ResultWinSymbol = resultSymbol,
		ResultLossSymbol = resultCross,
		ResultTitle = resultTitle,
		ResultButton = resultButton,
		Celebration = celebration,
		Dialogue = dialogue,
		DialogueSpeaker = speaker,
		DialogueText = dialogueText,
		DialogueTask = dialogueTask,
		DialogueSerial = 0,
		LastShiftState = "",
		Connections = {},
	}, HudView)

	local function positionForViewport()
		local camera = Workspace.CurrentCamera
		local narrow = camera and camera.ViewportSize.X < 760
		result.Position = if narrow then UDim2.fromScale(0.5, 0.64) else UDim2.fromScale(0.80, 0.61)
	end
	positionForViewport()
	table.insert(self.Connections, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(positionForViewport))
	if Workspace.CurrentCamera then
		table.insert(self.Connections, Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(positionForViewport))
	end

	return self
end

function HudView:ConnectAction(callback: () -> ())
	table.insert(self.Connections, self.StartButton.Activated:Connect(callback))
	table.insert(self.Connections, self.ResultButton.Activated:Connect(callback))
end

function HudView:Render(state: RenderState)
	self.TimeValue.Text = state.TimeText
	self.ServedValue.Text = state.ServedText
	self.MissedValue.Text = state.MissedText
	self.Notice.Visible = state.ShiftState == "Active"
	self.StartButton.Visible = state.ShiftState == "Waiting"
	self.Instruction.Text = state.Instruction
	self.AppleDot.BackgroundColor3 = if state.HasApple then state.HeldAppleColor else Color3.fromRGB(116, 105, 92)

	local terminal = state.ShiftState == "Won" or state.ShiftState == "Lost"
	self.Result.Visible = terminal
	if state.ShiftState == "Won" then
		self.ResultTitle.Text = state.ShiftWonText
		self.ResultButton.Text = state.NextShiftText
		self.ResultStroke.Color = LIGHT_GOLD
		self.ResultButton.BackgroundColor3 = SUCCESS
		self.ResultWinSymbol.Visible = true
		self.ResultLossSymbol.Visible = false
	elseif state.ShiftState == "Lost" then
		self.ResultTitle.Text = state.ShiftLostText
		self.ResultButton.Text = state.RetryText
		self.ResultStroke.Color = RUBY
		self.ResultButton.BackgroundColor3 = RUBY
		self.ResultWinSymbol.Visible = false
		self.ResultLossSymbol.Visible = true
	else
		self.StartButton.Text = state.StartText
	end

	if terminal and self.LastShiftState ~= state.ShiftState then
		self.ResultScale.Scale = 0.84
		TweenService:Create(
			self.ResultScale,
			TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
	end
	self.LastShiftState = state.ShiftState
end

function HudView:PulseServe()
	local brighten = TweenService:Create(self.ServedStroke, TweenInfo.new(0.1), {
		Color = Color3.fromRGB(132, 231, 145),
		Thickness = 4,
		Transparency = 0,
	})
	local settle = TweenService:Create(self.ServedStroke, TweenInfo.new(0.38), {
		Color = WARM_GOLD,
		Thickness = 2,
		Transparency = 0.05,
	})
	brighten.Completed:Once(function()
		settle:Play()
	end)
	brighten:Play()
end

function HudView:Bump(amount: number)
	self.StatusScale.Scale = 1
	local expand = TweenService:Create(
		self.StatusScale,
		TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = amount }
	)
	local settle = TweenService:Create(
		self.StatusScale,
		TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	expand.Completed:Once(function()
		settle:Play()
	end)
	expand:Play()
end

function HudView:ShowBanner(text: string)
	self.Celebration.Text = text
	self.Celebration.Position = UDim2.fromScale(0.5, 0.61)
	self.Celebration.TextTransparency = 0
	TweenService:Create(
		self.Celebration,
		TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 0.56), TextTransparency = 1 }
	):Play()
end

function HudView:ShowDialogue(speaker: string, text: string, taskText: string, duration: number)
	self.DialogueSerial += 1
	local serial = self.DialogueSerial
	self.DialogueSpeaker.Text = speaker
	self.DialogueText.Text = text
	self.DialogueTask.Text = taskText
	self.Dialogue.Visible = true
	self.Dialogue.Position = UDim2.new(0.5, 0, 1, 12)
	self.Dialogue.BackgroundTransparency = 0.3
	TweenService:Create(
		self.Dialogue,
		TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 1, -34), BackgroundTransparency = 0.08 }
	):Play()
	task.delay(duration, function()
		if serial ~= self.DialogueSerial or not self.Dialogue.Parent then
			return
		end
		local hide = TweenService:Create(
			self.Dialogue,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 1, 8), BackgroundTransparency = 0.35 }
		)
		hide.Completed:Once(function()
			if serial == self.DialogueSerial then
				self.Dialogue.Visible = false
			end
		end)
		hide:Play()
	end)
end

function HudView:Destroy()
	for _, connection in self.Connections do
		connection:Disconnect()
	end
	self.ScreenGui:Destroy()
end

return HudView
