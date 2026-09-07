local Contract = require("../src/shared/CustomerPresentationContract")

local expectedSequences = {
	Idle = "Pipilabu_Idle",
	Receive = "Pipilabu_Receive",
	Hold = "Pipilabu_Hold",
	Happy = "Pipilabu_Happy",
	Run = "Pipilabu_Run",
	TurnLeave = "Pipilabu_TurnLeave",
}

for action, sequenceName in expectedSequences do
	assert(Contract.isActionName(action), action .. " should be a known customer action")
	assert(Contract.sequenceName(action) == sequenceName, action .. " should resolve its sequence")
	assert(Contract.matchesSequenceName(action, action), action .. " should match its short imported name")
	assert(Contract.matchesSequenceName(sequenceName, action), action .. " should match its canonical sequence name")
	assert(
		Contract.matchesSequenceName("CustomerShibaV4_Rig|" .. sequenceName, action),
		action .. " should match a Studio-prefixed sequence name"
	)
	assert(not Contract.matchesSequenceName("Wrong_" .. sequenceName, action), action .. " should reject unrelated names")
end

assert(#Contract.HandoffActions == 3, "handoff should have three deterministic presentation stages")
assert(Contract.HandoffActions[1] == "Receive", "handoff should start with Receive")
assert(Contract.HandoffActions[2] == "Happy", "handoff should continue with Happy")
assert(Contract.HandoffActions[3] == "Hold", "handoff should settle on Hold")

assert(Contract.chooseExitAction({ Run = true, TurnLeave = true }) == "Run", "Run should be the preferred exit action")
assert(Contract.chooseExitAction({ Run = false, TurnLeave = true }) == "TurnLeave", "TurnLeave should be the safe fallback")
assert(Contract.chooseExitAction({ Run = false, TurnLeave = false }) == nil, "missing exit actions must fail closed")

local seenPhases = {}
for queueNumber = 1, 8 do
	local phase = Contract.idlePhaseForQueueNumber(queueNumber)
	assert(phase >= 0 and phase < 1, "idle phase must be normalized")
	local bucket = math.floor(phase * 10000)
	assert(not seenPhases[bucket], "neighboring customers must not share an idle phase")
	seenPhases[bucket] = true
end

print("Customer presentation contract passed action, sequence, handoff, exit, and idle-phase policy checks")
