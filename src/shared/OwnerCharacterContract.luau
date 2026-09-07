--!strict

-- Pure names and validation helpers for the Peepilabu owner presentation lane.
-- This module deliberately contains no Instance access so its policy can be
-- tested outside Studio and shared by server-side adapters.

export type ActionName = "Idle" | "Talk" | "Serve" | "Happy" | "Stressed"
export type AttachmentKey = "Back" | "FruitL" | "FruitR" | "Mouth" | "OrderBillboard" | "ShopkeeperProp"

local ACTIONS: { ActionName } = {
	"Idle",
	"Talk",
	"Serve",
	"Happy",
	"Stressed",
}

local ATTACHMENT_KEYS: { AttachmentKey } = {
	"Back",
	"FruitL",
	"FruitR",
	"Mouth",
	"OrderBillboard",
	"ShopkeeperProp",
}

local SEQUENCE_NAMES: { [ActionName]: string } = {
	Idle = "Pipilabu_Idle",
	Talk = "Pipilabu_Talk",
	Serve = "Pipilabu_Serve",
	Happy = "Pipilabu_Happy",
	Stressed = "Pipilabu_Stressed",
}

local ATTACHMENT_NAMES: { [AttachmentKey]: string } = {
	Back = "ATTACH_Back",
	FruitL = "ATTACH_Fruit_L",
	FruitR = "ATTACH_Fruit_R",
	Mouth = "ATTACH_Mouth",
	OrderBillboard = "ATTACH_OrderBillboard",
	ShopkeeperProp = "ATTACH_ShopkeeperProp",
}

local OwnerCharacterContract = {
	CandidateFolderName = "PipilabuCandidateAssets",
	CandidateModelName = "OwnerShibaV4Candidate",
	VillageRootName = "PipilabuMarketVillagePrototype",
	AnchorName = "PeepilabuQuestAnchor",
	PresentationSlotName = "OwnerShibaVisual",
	AnimationSavesFolderName = "RBX_ANIMSAVES",
	AnimationSetName = "pipilabu_shiba_owner_v4",
	RuntimeFallbackFolderName = "PipilabuRuntimeFallbacks",
	RuntimeFallbackName = "OwnerShibaVisual__RuntimeFallback",
	Actions = table.freeze(ACTIONS),
	AttachmentKeys = table.freeze(ATTACHMENT_KEYS),
	SequenceNames = table.freeze(SEQUENCE_NAMES),
	AttachmentNames = table.freeze(ATTACHMENT_NAMES),
}

function OwnerCharacterContract.isActionName(value: string): boolean
	for _, action in ACTIONS do
		if value == action then
			return true
		end
	end
	return false
end

function OwnerCharacterContract.sequenceName(action: ActionName): string
	return SEQUENCE_NAMES[action]
end

function OwnerCharacterContract.attachmentName(key: AttachmentKey): string
	return ATTACHMENT_NAMES[key]
end

function OwnerCharacterContract.animationAttributeKeys(action: ActionName): { string }
	local sequenceName = SEQUENCE_NAMES[action]
	return {
		string.format("%sAnimationId", action),
		string.format("AnimationId_%s", sequenceName),
		string.format("%sAnimationId", sequenceName),
	}
end

function OwnerCharacterContract.matchesSequenceName(instanceName: string, action: ActionName): boolean
	local expected = SEQUENCE_NAMES[action]
	if instanceName == expected then
		return true
	end

	local suffix = "|" .. expected
	return #instanceName > #suffix and string.sub(instanceName, -#suffix) == suffix
end

function OwnerCharacterContract.normalizeAnimationAssetId(value: unknown): string?
	if type(value) == "number" then
		if value <= 0 or value ~= math.floor(value) or value > 9_007_199_254_740_991 then
			return nil
		end
		return "rbxassetid://" .. string.format("%.0f", value)
	end

	if type(value) ~= "string" then
		return nil
	end

	local trimmed = string.match(value, "^%s*(.-)%s*$") :: string
	local digits = string.match(trimmed, "^(%d+)$")
		or string.match(trimmed, "^rbxassetid://(%d+)$")
		or string.match(trimmed, "^https?://www%.roblox%.com/asset/%?id=(%d+)$")
		or string.match(trimmed, "^https?://www%.roblox%.com/asset%?id=(%d+)$")

	if not digits then
		return nil
	end

	local numeric = tonumber(digits)
	if not numeric or numeric <= 0 or numeric > 9_007_199_254_740_991 then
		return nil
	end

	return "rbxassetid://" .. digits
end

return table.freeze(OwnerCharacterContract)
