local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local HapticService = game:GetService("HapticService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local AppleCatalog = require(projectRoot:WaitForChild("AppleCatalog"))
local Config = require(projectRoot:WaitForChild("Config"))
local Copy = require(projectRoot:WaitForChild("Copy"))
local HudView = require(script.Parent:WaitForChild("HudView"))

print(string.format("[JonAndLeo] client online - %s v%s", Config.ProjectName, Config.DevelopmentVersion))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
player.CameraMode = Enum.CameraMode.Classic
player.CameraMinZoomDistance = Config.Camera.MinimumZoom
player.CameraMaxZoomDistance = Config.Camera.MaximumZoom

local function applyCameraDefaults()
	local camera = Workspace.CurrentCamera
	if camera then
		camera.FieldOfView = Config.Camera.FieldOfView
	end
end

applyCameraDefaults()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(applyCameraDefaults)

local feedbackEvent = projectRoot:WaitForChild("ShopFeedback") :: RemoteEvent
local controlEvent = projectRoot:WaitForChild("ShopControl") :: RemoteEvent

local hud = HudView.new(playerGui, {
	Time = Copy.Hud.TimeLabel,
	Served = Copy.Hud.ServedLabel,
	Missed = Copy.Hud.MissedLabel,
	Celebration = Copy.Hud.Celebration,
})

local pickupSound = Instance.new("Sound")
pickupSound.Name = "PickupFeedback"
pickupSound.SoundId = Config.Audio.PickupSoundId
pickupSound.Volume = Config.Audio.PickupVolume
pickupSound.PlaybackSpeed = 1.08

local serveSound = Instance.new("Sound")
serveSound.Name = "ServeFeedback"
serveSound.SoundId = Config.Audio.ServeSoundId
serveSound.Volume = Config.Audio.ServeVolume
serveSound.PlaybackSpeed = 1.04

local wrongAppleSound = Instance.new("Sound")
wrongAppleSound.Name = "WrongAppleFeedback"
wrongAppleSound.SoundId = Config.Audio.PickupSoundId
wrongAppleSound.Volume = 0.16
wrongAppleSound.PlaybackSpeed = 0.72

local cashSound = Instance.new("Sound")
cashSound.Name = "CashFeedback"
cashSound.SoundId = Config.Audio.ServeSoundId
cashSound.Volume = 0.48
cashSound.PlaybackSpeed = 1.22

local function formatTime(seconds: number): string
	local safeSeconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", math.floor(safeSeconds / 60), safeSeconds % 60)
end

local function render()
	local hasApple = player:GetAttribute("HasApple") == true
	local heldAppleType = player:GetAttribute("HeldAppleType") :: string?
	local shiftState = tostring(player:GetAttribute("ShiftState") or "Waiting")
	local timeRemaining = player:GetAttribute("ShiftTimeRemaining") or 0
	local shiftServed = player:GetAttribute("ShiftServed") or 0
	local shiftTarget = player:GetAttribute("ShiftTarget") or Config.Shift.TargetServed
	local shiftMissed = player:GetAttribute("ShiftMissed") or 0
	local maximumMissed = player:GetAttribute("ShiftMaximumMissed") or Config.Shift.MaximumMissed
	local payoutReady = player:GetAttribute("ShiftPayoutReady") == true
	local payoutCollected = player:GetAttribute("ShiftPayoutCollected") == true
	local payoutAmount = tonumber(player:GetAttribute("ShiftPayoutAmount")) or 0
	local wonText = if payoutReady
		then string.format(Copy.Hud.ShiftWonPayout, payoutAmount)
		elseif payoutCollected
		then string.format(Copy.Hud.ShiftWonPaid, payoutAmount)
		else Copy.Hud.ShiftWon
	local lostText = if payoutReady
		then string.format(Copy.Hud.ShiftLostPayout, payoutAmount)
		elseif payoutCollected
		then string.format(Copy.Hud.ShiftLostPaid, payoutAmount)
		else Copy.Hud.ShiftLost

	hud:Render({
		HasApple = hasApple,
		HeldAppleColor = AppleCatalog.get(heldAppleType).Color,
		ShiftState = shiftState,
		TimeText = if shiftState == "Waiting" then "--:--" else formatTime(timeRemaining),
		ServedText = string.format("%d / %d", shiftServed, shiftTarget),
		MissedText = string.format("%d / %d", shiftMissed, maximumMissed),
		Instruction = tostring(player:GetAttribute("ShopMessage") or Copy.Messages.TakeApple),
		StartText = Copy.Hud.StartButton,
		NextShiftText = if payoutReady then Copy.Hud.CollectPayButton else Copy.Hud.NextShiftButton,
		RetryText = if payoutReady then Copy.Hud.CollectPayButton else Copy.Hud.RetryButton,
		ShiftWonText = wonText,
		ShiftLostText = lostText,
	})
end

local function confirmWithController()
	local gamepad = Enum.UserInputType.Gamepad1
	local motor = Enum.VibrationMotor.Small
	if HapticService:IsVibrationSupported(gamepad) and HapticService:IsMotorSupported(gamepad, motor) then
		HapticService:SetMotor(gamepad, motor, 0.55)
		task.delay(0.09, function()
			HapticService:SetMotor(gamepad, motor, 0)
		end)
	end
end

local function playOneShot(template: Sound)
	local sound = template:Clone()
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 4)
end

local function requestShift()
	if player:GetAttribute("ShiftState") ~= "Active" then
		if player:GetAttribute("ShiftPayoutReady") == true then
			local payoutCopy = if player:GetAttribute("ShiftState") == "Won" then Copy.Owner.PayoutWon else Copy.Owner.PayoutLost
			hud:ShowBanner(Copy.Hud.CollectPayButton)
			hud:ShowDialogue(
				Copy.Hud.OwnerSpeaker,
				string.format(payoutCopy, tonumber(player:GetAttribute("ShiftPayoutAmount")) or 0),
				Copy.Owner.PayoutTask,
				Config.OwnerInteraction.BubbleSeconds
			)
			return
		end
		controlEvent:FireServer("StartShift")
	end
end

hud:ConnectAction(requestShift)
ContextActionService:BindAction("PipilabuStartShift", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		requestShift()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.R, Enum.KeyCode.ButtonY)

feedbackEvent.OnClientEvent:Connect(function(action: string, value: unknown, detail: unknown)
	if action == "Pickup" then
		playOneShot(pickupSound)
		hud:Bump(1.012)
	elseif action == "Serve" then
		playOneShot(serveSound)
		hud:Bump(1.025)
		hud:PulseServe()
		confirmWithController()
		hud:ShowBanner(Copy.Hud.Celebration)
	elseif action == "Wrong" then
		playOneShot(wrongAppleSound)
		hud:Bump(0.988)
		hud:ShowBanner(Copy.Messages.WrongAppleReaction)
	elseif action == "Won" then
		hud:ShowBanner(Copy.Hud.ShiftWon)
	elseif action == "Lost" then
		hud:ShowBanner(Copy.Hud.ShiftLost)
	elseif action == "PayoutReady" then
		local amount = if type(value) == "number" then value else 0
		local dialogue = if detail == "Won" then Copy.Owner.PayoutWon else Copy.Owner.PayoutLost
		hud:ShowDialogue(Copy.Hud.OwnerSpeaker, string.format(dialogue, amount), Copy.Owner.PayoutTask, Config.OwnerInteraction.BubbleSeconds)
	elseif action == "PayoutRequired" then
		hud:ShowBanner(Copy.Hud.CollectPayButton)
	elseif action == "PayoutCollected" then
		local amount = if type(value) == "number" then value else 0
		playOneShot(cashSound)
		hud:Bump(1.035)
		hud:ShowBanner(string.format("$%d CASH", amount))
		hud:ShowDialogue(Copy.Hud.OwnerSpeaker, Copy.Owner.PayoutCollected, tostring(player:GetAttribute("ShopMessage") or ""), Config.OwnerInteraction.BubbleSeconds)
	end
end)

player:GetAttributeChangedSignal("OwnerDialogueSerial"):Connect(function()
	local dialogueText = tostring(player:GetAttribute("OwnerDialogueText") or "")
	if dialogueText == "" then
		return
	end
	hud:ShowDialogue(
		Copy.Hud.OwnerSpeaker,
		dialogueText,
		tostring(player:GetAttribute("OwnerTaskText") or ""),
		Config.OwnerInteraction.BubbleSeconds
	)
end)

for _, attribute in {
	"HasApple",
	"HeldAppleType",
	"ShopMessage",
	"ShiftState",
	"ShiftTimeRemaining",
	"ShiftTarget",
	"ShiftServed",
	"ShiftMissed",
	"ShiftMaximumMissed",
	"ShiftPayoutAmount",
	"ShiftPayoutReady",
	"ShiftPayoutCollected",
	"ShiftCashBalance",
} do
	player:GetAttributeChangedSignal(attribute):Connect(render)
end

render()
