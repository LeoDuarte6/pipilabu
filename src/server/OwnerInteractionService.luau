--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local AppleCatalog = require(projectRoot:WaitForChild("AppleCatalog"))
local Copy = require(projectRoot:WaitForChild("Copy"))
local OwnerDialogue = require(projectRoot:WaitForChild("OwnerDialogue"))
local OwnerPresentationService = require(script.Parent:WaitForChild("OwnerPresentationService"))

type Options = {
	Enabled: boolean,
	MaximumDistance: number,
	BubbleMaxDistance: number,
	BubbleSeconds: number,
}

local OwnerInteractionService = {}
local started = false
local lastMissedByUserId: { [number]: number } = {}
local talkSerial = 0

local function appleName(value: unknown): string
	if type(value) ~= "string" or value == "" then
		return ""
	end
	local definition = AppleCatalog.get(value)
	return if definition then definition.DisplayName else value
end

local function makeBubble(root: BasePart, maximumDistance: number): (BillboardGui, TextLabel, TextLabel)
	local gui = Instance.new("BillboardGui")
	gui.Name = "OwnerDialogueBubble"
	gui.AlwaysOnTop = true
	gui.MaxDistance = maximumDistance
	gui.Size = UDim2.fromOffset(330, 108)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	gui.Enabled = false
	gui.Parent = root

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(255, 244, 219)
	frame.BackgroundTransparency = 0.04
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(117, 76, 48)
	stroke.Thickness = 2
	stroke.Transparency = 0.15
	stroke.Parent = frame

	local dialogue = Instance.new("TextLabel")
	dialogue.Name = "Dialogue"
	dialogue.Position = UDim2.fromOffset(14, 9)
	dialogue.Size = UDim2.new(1, -28, 0, 62)
	dialogue.BackgroundTransparency = 1
	dialogue.Font = Enum.Font.BuilderSansMedium
	dialogue.TextColor3 = Color3.fromRGB(61, 45, 36)
	dialogue.TextSize = 17
	dialogue.TextWrapped = true
	dialogue.TextXAlignment = Enum.TextXAlignment.Left
	dialogue.TextYAlignment = Enum.TextYAlignment.Center
	dialogue.Parent = frame

	local taskLabel = Instance.new("TextLabel")
	taskLabel.Name = "Task"
	taskLabel.Position = UDim2.fromOffset(14, 72)
	taskLabel.Size = UDim2.new(1, -28, 0, 25)
	taskLabel.BackgroundTransparency = 1
	taskLabel.Font = Enum.Font.BuilderSansBold
	taskLabel.TextColor3 = Color3.fromRGB(156, 82, 50)
	taskLabel.TextSize = 14
	taskLabel.TextXAlignment = Enum.TextXAlignment.Left
	taskLabel.Parent = frame
	return gui, dialogue, taskLabel
end

function OwnerInteractionService.Start(options: Options): string
	if started then
		return "AlreadyStarted"
	end
	started = true
	if not options.Enabled then
		return "Disabled"
	end
	local model = OwnerPresentationService.GetActiveModel()
	if not model then
		return "OwnerUnavailable"
	end
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not root or not root:IsA("BasePart") then
		return "OwnerRootMissing"
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OwnerTalkPrompt"
	prompt.ActionText = Copy.Prompts.OwnerTalkAction
	prompt.ObjectText = Copy.Prompts.OwnerTalkObject
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = options.MaximumDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	local bubble, dialogueLabel, taskLabel = makeBubble(root, options.BubbleMaxDistance)
	model:SetAttribute("InteractionReady", true)

	prompt.Triggered:Connect(function(player)
		local missed = tonumber(player:GetAttribute("ShiftMissed")) or 0
		local previousMissed = lastMissedByUserId[player.UserId] or 0
		lastMissedByUserId[player.UserId] = missed
		local result = OwnerDialogue.resolve({
			ShiftState = tostring(player:GetAttribute("ShiftState") or "Waiting"),
			Served = tonumber(player:GetAttribute("ShiftServed")) or 0,
			Target = tonumber(player:GetAttribute("ShiftTarget")) or 10,
			HasApple = player:GetAttribute("HasApple") == true,
			HeldAppleName = appleName(player:GetAttribute("HeldAppleType")),
			OrderedAppleName = appleName(player:GetAttribute("FrontReadyOrderType")),
			NewMissedCustomer = missed > previousMissed,
		})

		talkSerial += 1
		local serial = talkSerial
		player:SetAttribute("OwnerDialogueSerial", serial)
		player:SetAttribute("OwnerDialogueText", result.Dialogue)
		player:SetAttribute("OwnerTaskText", result.Task)
		model:SetAttribute("LastDialogueKey", result.Key)
		model:SetAttribute("TalkSerial", serial)
		dialogueLabel.Text = result.Dialogue
		taskLabel.Text = result.Task
		bubble.Enabled = true
		OwnerPresentationService.Play("Talk", { Looped = false })

		task.delay(options.BubbleSeconds, function()
			if talkSerial == serial and bubble.Parent then
				bubble.Enabled = false
				OwnerPresentationService.Play("Idle")
			end
		end)
	end)

	return "Ready"
end

return OwnerInteractionService
