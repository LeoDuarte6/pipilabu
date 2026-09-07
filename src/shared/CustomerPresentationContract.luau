--!strict

-- Pure contract and deterministic policy for the guarded customer presentation
-- lane. Roblox instance access stays in CustomerPresentationService so these
-- names and action choices can be tested without Studio.

export type ActionName = "Idle" | "Receive" | "Hold" | "Happy" | "Run" | "TurnLeave"
export type ExitAction = "Run" | "TurnLeave"

local ACTIONS: { ActionName } = {
	"Idle",
	"Receive",
	"Hold",
	"Happy",
	"Run",
	"TurnLeave",
}

local HANDOFF_ACTIONS: { ActionName } = {
	"Receive",
	"Happy",
	"Hold",
}

local SEQUENCE_NAMES: { [ActionName]: string } = {
	Idle = "Pipilabu_Idle",
	Receive = "Pipilabu_Receive",
	Hold = "Pipilabu_Hold",
	Happy = "Pipilabu_Happy",
	Run = "Pipilabu_Run",
	TurnLeave = "Pipilabu_TurnLeave",
}

local CustomerPresentationContract = {
	CandidateFolderName = "PipilabuCandidateAssets",
	CandidateModelName = "CustomerShibaV4Candidate",
	AnimationSavesFolderName = "RBX_ANIMSAVES",
	AnimationSetName = "pipilabu_shiba_customer_v4",
	VisualName = "CustomerShibaV4Visual",
	RuntimeWeldName = "CustomerPresentationWeld",
	Actions = table.freeze(ACTIONS),
	HandoffActions = table.freeze(HANDOFF_ACTIONS),
	SequenceNames = table.freeze(SEQUENCE_NAMES),
}

function CustomerPresentationContract.isActionName(value: string): boolean
	for _, action in ACTIONS do
		if value == action then
			return true
		end
	end
	return false
end

function CustomerPresentationContract.sequenceName(action: ActionName): string
	return SEQUENCE_NAMES[action]
end

function CustomerPresentationContract.matchesSequenceName(instanceName: string, action: ActionName): boolean
	local expected = SEQUENCE_NAMES[action]
	if instanceName == action or instanceName == expected then
		return true
	end

	local shortSuffix = "|" .. action
	local namedSuffix = "|" .. expected
	return (#instanceName > #shortSuffix and string.sub(instanceName, -#shortSuffix) == shortSuffix)
		or (#instanceName > #namedSuffix and string.sub(instanceName, -#namedSuffix) == namedSuffix)
end

function CustomerPresentationContract.chooseExitAction(available: { [string]: boolean }): ExitAction?
	if available.Run == true then
		return "Run"
	end
	if available.TurnLeave == true then
		return "TurnLeave"
	end
	return nil
end

-- Irrational spacing keeps neighboring queue customers from sharing the same
-- idle pose while remaining deterministic for repeatable playtests.
function CustomerPresentationContract.idlePhaseForQueueNumber(queueNumber: number): number
	local safeNumber = math.max(1, math.floor(queueNumber))
	return (safeNumber * 0.3819660112501051) % 1
end

return table.freeze(CustomerPresentationContract)
