--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Config = require(projectRoot:WaitForChild("Config"))

type EventRecord = {
	at: number,
	kind: string,
	value: any?,
}

type RunRecord = {
	run: number,
	player: string,
	startedAt: number,
	endedAt: number?,
	result: string?,
	served: number,
	missed: number,
	wrongAttempts: number,
	customerReadyCount: number,
	handoffsStarted: number,
	handoffsCompleted: number,
	immediateNextPickups: number,
	replayStarted: boolean,
	appleHeldSeconds: { number },
	approachSeconds: { number },
	selections: { string },
	events: { EventRecord },
}

local PlaytestRecorderService = {}

local started = false
local evidence: Folder
local runCount = 0
local activeByPlayer: { [Player]: RunRecord } = {}
local finishedRuns: { RunRecord } = {}
local MAX_EVENTS_PER_RUN = 128

local function roundedElapsed(run: RunRecord): number
	return math.round((os.clock() - run.startedAt) * 100) / 100
end

local function encode(value: any): string
	local ok, result = pcall(HttpService.JSONEncode, HttpService, value)
	return if ok then result else "{}"
end

local function publishActive(run: RunRecord?)
	evidence:SetAttribute("ActiveRunJson", if run then encode(run) else "")
end

local function refreshGateEvidence()
	local pairWrongAttempts = 0
	for _, run in finishedRuns do
		pairWrongAttempts += run.wrongAttempts
	end

	local objectiveEvidenceReady = #finishedRuns >= 2 and pairWrongAttempts >= 1
	local gateState = if #finishedRuns < 2
		then "AwaitingTwoCompletedRuns"
		elseif pairWrongAttempts < 1 then "NeedsWrongAppleAttempt"
		else "AwaitingQualitativeVerdict"

	evidence:SetAttribute("CompletedRunCount", #finishedRuns)
	evidence:SetAttribute("PairWrongAttempts", pairWrongAttempts)
	evidence:SetAttribute("ObjectiveEvidenceReady", objectiveEvidenceReady)
	evidence:SetAttribute("QualitativeVerdictRecorded", false)
	evidence:SetAttribute("GateState", gateState)
	evidence:SetAttribute("LatestPairJson", encode({
		build = Config.DevelopmentVersion,
		placeId = game.PlaceId,
		gameId = game.GameId,
		wrongAttempts = pairWrongAttempts,
		objectiveEvidenceReady = objectiveEvidenceReady,
		runs = finishedRuns,
	}))
end

local function record(run: RunRecord, kind: string, value: any?)
	if #run.events >= MAX_EVENTS_PER_RUN then
		table.remove(run.events, 1)
	end
	table.insert(run.events, {
		at = roundedElapsed(run),
		kind = kind,
		value = value,
	})
	evidence:SetAttribute("LastEvent", kind)
	publishActive(run)
end

local function beginRun(player: Player)
	if activeByPlayer[player] then
		return
	end

	runCount += 1
	local replayStarted = false
	for _, previousRun in finishedRuns do
		if previousRun.player == player.Name then
			replayStarted = true
			break
		end
	end
	local run: RunRecord = {
		run = runCount,
		player = player.Name,
		startedAt = os.clock(),
		served = 0,
		missed = 0,
		wrongAttempts = 0,
		customerReadyCount = 0,
		handoffsStarted = 0,
		handoffsCompleted = 0,
		immediateNextPickups = 0,
		replayStarted = replayStarted,
		appleHeldSeconds = {},
		approachSeconds = {},
		selections = {},
		events = {},
	}
	activeByPlayer[player] = run
	evidence:SetAttribute("RunCount", runCount)
	if replayStarted then
		record(run, "ReplayStarted", nil)
	end
	record(run, "ShiftStarted", nil)
end

local function finishRun(player: Player, result: string)
	local run = activeByPlayer[player]
	if not run then
		return
	end

	run.endedAt = os.clock()
	run.result = result
	run.served = tonumber(player:GetAttribute("ShiftServed")) or run.served
	run.missed = tonumber(player:GetAttribute("ShiftMissed")) or run.missed
	record(run, "ShiftEnded", result)

	local previous = evidence:GetAttribute("LastRunJson")
	if type(previous) == "string" and previous ~= "" then
		evidence:SetAttribute("PreviousRunJson", previous)
	end
	evidence:SetAttribute("LastRunJson", encode(run))
	table.insert(finishedRuns, run)
	if #finishedRuns > 2 then
		table.remove(finishedRuns, 1)
	end
	activeByPlayer[player] = nil
	publishActive(nil)
	refreshGateEvidence()
end

local function observePlayer(player: Player)
	local lastApple = tostring(player:GetAttribute("HeldAppleType") or "")
	local lastServed = tonumber(player:GetAttribute("ShiftServed")) or 0
	local lastMissed = tonumber(player:GetAttribute("ShiftMissed")) or 0
	local lastFrontReadySerial = tonumber(player:GetAttribute("FrontReadySerial")) or 0
	local lastHandoffSerial = tonumber(player:GetAttribute("HandoffSerial")) or 0
	local lastHandoffCompletedSerial = tonumber(player:GetAttribute("HandoffCompletedSerial")) or 0
	local lastImmediateNextPickupSerial = tonumber(player:GetAttribute("ImmediateNextPickupSerial")) or 0
	local lastWrongAppleSerial = tonumber(player:GetAttribute("WrongAppleSerial")) or 0
	local lastAppleTakenAt: number? = nil
	local lastFrontReadyAt: number? = nil

	player:GetAttributeChangedSignal("ShiftState"):Connect(function()
		local state = tostring(player:GetAttribute("ShiftState") or "Waiting")
		if state == "Active" then
			beginRun(player)
		elseif state == "Won" or state == "Lost" then
			finishRun(player, state)
		end
	end)

	player:GetAttributeChangedSignal("HeldAppleType"):Connect(function()
		local apple = tostring(player:GetAttribute("HeldAppleType") or "")
		local run = activeByPlayer[player]
		if run and apple ~= "" and apple ~= lastApple then
			table.insert(run.selections, apple)
			lastAppleTakenAt = os.clock()
			record(run, "AppleSelected", apple)
		end
		lastApple = apple
	end)

	player:GetAttributeChangedSignal("FrontReadySerial"):Connect(function()
		local serial = tonumber(player:GetAttribute("FrontReadySerial")) or 0
		local run = activeByPlayer[player]
		if run and serial > lastFrontReadySerial then
			lastFrontReadyAt = os.clock()
			run.customerReadyCount += serial - lastFrontReadySerial
			record(run, "CustomerReady", player:GetAttribute("FrontReadyOrderType"))
		end
		lastFrontReadySerial = serial
	end)

	player:GetAttributeChangedSignal("HandoffSerial"):Connect(function()
		local serial = tonumber(player:GetAttribute("HandoffSerial")) or 0
		local run = activeByPlayer[player]
		if run and serial > lastHandoffSerial then
			local now = os.clock()
			run.handoffsStarted += serial - lastHandoffSerial
			if lastAppleTakenAt then
				table.insert(run.appleHeldSeconds, math.round((now - lastAppleTakenAt) * 100) / 100)
			end
			if lastFrontReadyAt then
				table.insert(run.approachSeconds, math.round((now - lastFrontReadyAt) * 100) / 100)
			end
			record(run, "HandoffStarted", player:GetAttribute("LastHandoffAppleType"))
		end
		lastHandoffSerial = serial
	end)

	player:GetAttributeChangedSignal("HandoffCompletedSerial"):Connect(function()
		local serial = tonumber(player:GetAttribute("HandoffCompletedSerial")) or 0
		local run = activeByPlayer[player]
		if run and serial > lastHandoffCompletedSerial then
			run.handoffsCompleted += serial - lastHandoffCompletedSerial
			record(run, "HandoffCompleted", player:GetAttribute("LastHandoffAppleType"))
		end
		lastHandoffCompletedSerial = serial
	end)

	player:GetAttributeChangedSignal("ImmediateNextPickupSerial"):Connect(function()
		local serial = tonumber(player:GetAttribute("ImmediateNextPickupSerial")) or 0
		local run = activeByPlayer[player]
		if run and serial > lastImmediateNextPickupSerial then
			run.immediateNextPickups += serial - lastImmediateNextPickupSerial
			record(run, "ImmediateNextPickup", player:GetAttribute("ImmediateNextPickupAppleType"))
		end
		lastImmediateNextPickupSerial = serial
	end)

	player:GetAttributeChangedSignal("WrongAppleSerial"):Connect(function()
		local serial = tonumber(player:GetAttribute("WrongAppleSerial")) or 0
		local run = activeByPlayer[player]
		if run and serial > lastWrongAppleSerial then
			run.wrongAttempts += serial - lastWrongAppleSerial
			record(run, "WrongApple", player:GetAttribute("LastWrongAppleType"))
		end
		lastWrongAppleSerial = serial
	end)

	player:GetAttributeChangedSignal("ShiftServed"):Connect(function()
		local served = tonumber(player:GetAttribute("ShiftServed")) or 0
		local run = activeByPlayer[player]
		if run and served > lastServed then
			run.served = served
			record(run, "CustomerServed", served)
		end
		lastServed = served
	end)

	player:GetAttributeChangedSignal("ShiftMissed"):Connect(function()
		local missed = tonumber(player:GetAttribute("ShiftMissed")) or 0
		local run = activeByPlayer[player]
		if run and missed > lastMissed then
			run.missed = missed
			record(run, "CustomerMissed", missed)
		end
		lastMissed = missed
	end)
end

function PlaytestRecorderService.Start()
	if started or not RunService:IsStudio() then
		return
	end
	started = true

	evidence = ReplicatedStorage:FindFirstChild("PipiLabuPlaytestEvidence") :: Folder
	if not evidence then
		evidence = Instance.new("Folder")
		evidence.Name = "PipiLabuPlaytestEvidence"
		evidence.Parent = ReplicatedStorage
	end
	evidence:SetAttribute("SchemaVersion", 4)
	evidence:SetAttribute("MaximumEventsPerRun", MAX_EVENTS_PER_RUN)
	evidence:SetAttribute("BuildVersion", Config.DevelopmentVersion)
	evidence:SetAttribute("PlaceId", game.PlaceId)
	evidence:SetAttribute("GameId", game.GameId)
	evidence:SetAttribute("RunCount", 0)
	evidence:SetAttribute("ActiveRunJson", "")
	evidence:SetAttribute("LastRunJson", "")
	evidence:SetAttribute("PreviousRunJson", "")
	evidence:SetAttribute("LastEvent", "Ready")
	refreshGateEvidence()

	Players.PlayerAdded:Connect(observePlayer)
	Players.PlayerRemoving:Connect(function(player)
		activeByPlayer[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		observePlayer(player)
	end

	print("[PipiLabuPlaytest] recorder ready (Studio only)")
end

return PlaytestRecorderService
