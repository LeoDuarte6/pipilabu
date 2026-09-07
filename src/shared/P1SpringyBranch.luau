--!strict

-- Pure server-owned contract for Gate P1. Roblox instances, prompts, and
-- presentation are deliberately outside this module so the transition rules
-- can be tested deterministically without Studio.

export type State =
	"Attached"
	| "Gripped"
	| "DetachedAirborne"
	| "Held"
	| "RecoverableGround"
	| "Served"
	| "Abandoned"

export type DominantInput = "None" | "Pull" | "Twist" | "Combined"

export type Tuning = {
	BranchReachStuds: number,
	PullDistanceForMaxTension: number,
	TwistDegreesForMaxTension: number,
	PullContribution: number,
	TwistContribution: number,
	DetachThreshold: number,
	SpringStrength: number,
	Damping: number,
	MaxReleaseVelocity: number,
	CatchForgivenessStuds: number,
	RecoveryDistanceStuds: number,
}

export type TensionInput = {
	PullDistanceStuds: number,
	TwistDegrees: number,
}

export type TensionSample = {
	Pull: number,
	Twist: number,
	Value: number,
	Dominant: DominantInput,
}

export type Event = {
	Name: string,
	Serial: number,
	State: State,
	PreviousState: State,
	Tension: number,
	PeakTension: number,
	DominantInput: DominantInput,
	ReleaseSpeed: number?,
	Reason: string?,
}

export type Result = {
	Accepted: boolean,
	State: State,
	Reason: string?,
	Events: { Event },
	Sample: TensionSample?,
	PeakTension: number,
	ReleaseSpeed: number?,
}

export type Session = {
	beginGrip: (distanceStuds: number, branchAttached: boolean) -> Result,
	updateGrip: (input: TensionInput) -> Result,
	releaseGrip: () -> Result,
	catchRuby: () -> Result,
	dropRuby: () -> Result,
	recoverRuby: (distanceStuds: number, grounded: boolean) -> Result,
	recoverOutOfBounds: (settled: boolean, genuinelyUnreachable: boolean) -> Result,
	serveRuby: () -> Result,
	abandon: (reason: string?) -> Result,
	getSnapshot: () -> {
		State: State,
		PeakTension: number,
		LastTension: number,
		DominantInput: DominantInput,
		ReleaseSpeed: number?,
	},
	getTuning: () -> Tuning,
}

local DEFAULT_TUNING: Tuning = table.freeze({
	BranchReachStuds = 6,
	PullDistanceForMaxTension = 2.5,
	TwistDegreesForMaxTension = 70,
	PullContribution = 0.86,
	TwistContribution = 0.64,
	DetachThreshold = 0.82,
	SpringStrength = 34,
	Damping = 3.5,
	MaxReleaseVelocity = 18,
	CatchForgivenessStuds = 2.25,
	RecoveryDistanceStuds = 60,
})

local TUNING_KEYS = table.freeze({
	"BranchReachStuds",
	"PullDistanceForMaxTension",
	"TwistDegreesForMaxTension",
	"PullContribution",
	"TwistContribution",
	"DetachThreshold",
	"SpringStrength",
	"Damping",
	"MaxReleaseVelocity",
	"CatchForgivenessStuds",
	"RecoveryDistanceStuds",
})

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function validateTuning(tuning: Tuning)
	for _, key in TUNING_KEYS do
		local value = tuning[key]
		assert(type(value) == "number" and isFinite(value), string.format("P1 tuning %s must be finite", key))
		assert(value > 0, string.format("P1 tuning %s must be positive", key))
	end
	assert(tuning.DetachThreshold <= 1, "P1 DetachThreshold cannot exceed 1")
	assert(tuning.PullContribution <= 1, "P1 PullContribution cannot exceed 1")
	assert(tuning.TwistContribution <= 1, "P1 TwistContribution cannot exceed 1")
end

local function resolveTuning(overrides: Tuning?): Tuning
	local resolved = table.clone(DEFAULT_TUNING)
	if overrides then
		for _, key in TUNING_KEYS do
			local value = overrides[key]
			if value ~= nil then
				resolved[key] = value
			end
		end
	end
	validateTuning(resolved)
	return table.freeze(resolved)
end

local function reject(state: State, peakTension: number, reason: string): Result
	return table.freeze({
		Accepted = false,
		State = state,
		Reason = reason,
		Events = table.freeze({}),
		Sample = nil,
		PeakTension = peakTension,
		ReleaseSpeed = nil,
	})
end

local function makeEvent(
	name: string,
	serial: number,
	state: State,
	previousState: State,
	lastSample: TensionSample,
	peakTension: number,
	releaseSpeed: number?,
	reason: string?
): Event
	return table.freeze({
		Name = name,
		Serial = serial,
		State = state,
		PreviousState = previousState,
		Tension = lastSample.Value,
		PeakTension = peakTension,
		DominantInput = lastSample.Dominant,
		ReleaseSpeed = releaseSpeed,
		Reason = reason,
	})
end

local function makeResult(
	state: State,
	peakTension: number,
	events: { Event },
	sample: TensionSample?,
	releaseSpeed: number?
): Result
	return table.freeze({
		Accepted = true,
		State = state,
		Reason = nil,
		Events = table.freeze(events),
		Sample = sample,
		PeakTension = peakTension,
		ReleaseSpeed = releaseSpeed,
	})
end

local function validateTensionInput(value: any): (boolean, string?)
	if type(value) ~= "table" then
		return false, "InvalidTensionInput"
	end

	for _, key in { "PullDistanceStuds", "TwistDegrees" } do
		local field = value[key]
		if type(field) ~= "number" or not isFinite(field) then
			return false, string.format("Invalid%s", key)
		end
	end

	return true, nil
end

local function computeTension(input: TensionInput, tuning: Tuning): TensionSample
	local valid, reason = validateTensionInput(input)
	assert(valid, reason or "InvalidTensionInput")

	local pullRatio = math.clamp(math.abs(input.PullDistanceStuds) / tuning.PullDistanceForMaxTension, 0, 1)
	local twistRatio = math.clamp(math.abs(input.TwistDegrees) / tuning.TwistDegreesForMaxTension, 0, 1)
	local pullLoad = pullRatio * tuning.PullContribution
	local twistLoad = twistRatio * tuning.TwistContribution
	local value = math.clamp(math.sqrt(pullLoad * pullLoad + twistLoad * twistLoad), 0, 1)

	local dominant: DominantInput
	if pullLoad <= 0 and twistLoad <= 0 then
		dominant = "None"
	elseif pullLoad > 0 and twistLoad > 0 and math.abs(pullLoad - twistLoad) <= 0.12 then
		dominant = "Combined"
	elseif pullLoad >= twistLoad then
		dominant = "Pull"
	else
		dominant = "Twist"
	end

	return table.freeze({
		Pull = pullLoad,
		Twist = twistLoad,
		Value = value,
		Dominant = dominant,
	})
end

local function createSession(overrides: Tuning?): Session
	local tuning = resolveTuning(overrides)
	local state: State = "Attached"
	local eventSerial = 0
	local peakTension = 0
	local lastSample: TensionSample = table.freeze({
		Pull = 0,
		Twist = 0,
		Value = 0,
		Dominant = "None",
	})
	local releaseSpeed: number? = nil

	local function emit(
		name: string,
		previousState: State,
		eventReleaseSpeed: number?,
		reason: string?
	): Event
		eventSerial += 1
		return makeEvent(name, eventSerial, state, previousState, lastSample, peakTension, eventReleaseSpeed, reason)
	end

	local function beginGrip(distanceStuds: number, branchAttached: boolean): Result
		if state ~= "Attached" then
			return reject(state, peakTension, "RubyNotAttached")
		end
		if not isFinite(distanceStuds) or distanceStuds < 0 then
			return reject(state, peakTension, "InvalidReach")
		end
		if not branchAttached then
			return reject(state, peakTension, "BranchNotAttached")
		end
		if distanceStuds > tuning.BranchReachStuds then
			return reject(state, peakTension, "OutOfReach")
		end

		state = "Gripped"
		peakTension = 0
		lastSample = table.freeze({
			Pull = 0,
			Twist = 0,
			Value = 0,
			Dominant = "None",
		})
		releaseSpeed = nil
		return makeResult(state, peakTension, { emit("P1GrabStarted", "Attached", nil, nil) }, lastSample, nil)
	end

	local function updateGrip(input: TensionInput): Result
		if state ~= "Gripped" then
			return reject(state, peakTension, "GripNotActive")
		end

		local valid, reason = validateTensionInput(input)
		if not valid then
			return reject(state, peakTension, reason or "InvalidTensionInput")
		end

		local sample = computeTension(input, tuning)
		lastSample = sample
		local events: { Event } = {}
		if sample.Value > peakTension then
			peakTension = sample.Value
			table.insert(events, emit("P1PeakTension", state, nil, nil))
		end

		if sample.Value >= tuning.DetachThreshold then
			local previousState = state
			state = "DetachedAirborne"
			releaseSpeed = math.clamp(sample.Value * tuning.MaxReleaseVelocity, 0, tuning.MaxReleaseVelocity)
			table.insert(events, emit("P1Detached", previousState, releaseSpeed, nil))
		end

		return makeResult(state, peakTension, events, sample, releaseSpeed)
	end

	local function releaseGrip(): Result
		if state ~= "Gripped" then
			return reject(state, peakTension, "GripNotActive")
		end

		local previousState = state
		state = "Attached"
		return makeResult(state, peakTension, { emit("P1GripReleasedAttached", previousState, nil, nil) }, lastSample, nil)
	end

	local function catchRuby(): Result
		if state ~= "DetachedAirborne" then
			return reject(state, peakTension, "RubyNotAirborne")
		end

		local previousState = state
		state = "Held"
		return makeResult(state, peakTension, { emit("P1CaughtBeforeGround", previousState, releaseSpeed, nil) }, lastSample, releaseSpeed)
	end

	local function dropRuby(): Result
		if state ~= "DetachedAirborne" and state ~= "Held" then
			return reject(state, peakTension, "RubyNotDroppable")
		end

		local previousState = state
		state = "RecoverableGround"
		return makeResult(state, peakTension, { emit("P1Dropped", previousState, releaseSpeed, nil) }, lastSample, releaseSpeed)
	end

	local function recoverRuby(distanceStuds: number, grounded: boolean): Result
		if state ~= "RecoverableGround" then
			return reject(state, peakTension, "RubyNotRecoverable")
		end
		if not isFinite(distanceStuds) or distanceStuds < 0 then
			return reject(state, peakTension, "InvalidReach")
		end
		if distanceStuds > tuning.CatchForgivenessStuds then
			return reject(state, peakTension, "RecoveryOutOfReach")
		end
		if not grounded then
			return reject(state, peakTension, "RubyNotSettled")
		end

		local previousState = state
		state = "Held"
		return makeResult(state, peakTension, { emit("P1Recovered", previousState, releaseSpeed, nil) }, lastSample, releaseSpeed)
	end

	local function recoverOutOfBounds(settled: boolean, genuinelyUnreachable: boolean): Result
		if state ~= "RecoverableGround" then
			return reject(state, peakTension, "RubyNotRecoverable")
		end
		if not settled then
			return reject(state, peakTension, "RubyNotSettled")
		end
		if not genuinelyUnreachable then
			return reject(state, peakTension, "RubyStillRecoverable")
		end

		local previousState = state
		state = "Attached"
		peakTension = 0
		lastSample = table.freeze({
			Pull = 0,
			Twist = 0,
			Value = 0,
			Dominant = "None",
		})
		releaseSpeed = nil
		return makeResult(state, peakTension, { emit("P1OutOfBoundsRecovered", previousState, nil, "SettledAndUnreachable") }, lastSample, nil)
	end

	local function serveRuby(): Result
		if state ~= "Held" then
			return reject(state, peakTension, "RubyNotHeld")
		end

		local previousState = state
		state = "Served"
		return makeResult(state, peakTension, { emit("P1Served", previousState, releaseSpeed, nil) }, lastSample, releaseSpeed)
	end

	local function abandon(reason: string?): Result
		if state == "Served" or state == "Abandoned" then
			return reject(state, peakTension, "SessionClosed")
		end

		local previousState = state
		state = "Abandoned"
		return makeResult(state, peakTension, { emit("P1Abandoned", previousState, releaseSpeed, reason or "SessionClosed") }, lastSample, releaseSpeed)
	end

	local function getSnapshot()
		return table.freeze({
			State = state,
			PeakTension = peakTension,
			LastTension = lastSample.Value,
			DominantInput = lastSample.Dominant,
			ReleaseSpeed = releaseSpeed,
		})
	end

	return table.freeze({
		beginGrip = beginGrip,
		updateGrip = updateGrip,
		releaseGrip = releaseGrip,
		catchRuby = catchRuby,
		dropRuby = dropRuby,
		recoverRuby = recoverRuby,
		recoverOutOfBounds = recoverOutOfBounds,
		serveRuby = serveRuby,
		abandon = abandon,
		getSnapshot = getSnapshot,
		getTuning = function(): Tuning
			return tuning
		end,
	})
end

local P1SpringyBranch = {
	DefaultTuning = DEFAULT_TUNING,
	validateTensionInput = validateTensionInput,
	computeTension = function(input: TensionInput, tuning: Tuning?): TensionSample
		return computeTension(input, resolveTuning(tuning))
	end,
	newSession = createSession,
}

return table.freeze(P1SpringyBranch)
