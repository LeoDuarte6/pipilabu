local Contract = require("../src/shared/OwnerCharacterContract")

local expectedActions = {
	Idle = "Pipilabu_Idle",
	Talk = "Pipilabu_Talk",
	Serve = "Pipilabu_Serve",
	Happy = "Pipilabu_Happy",
	Stressed = "Pipilabu_Stressed",
}

for action, sequenceName in expectedActions do
	assert(Contract.isActionName(action), action .. " should be a known action")
	assert(Contract.sequenceName(action) == sequenceName, action .. " should resolve its sequence")
	assert(Contract.matchesSequenceName(sequenceName, action), action .. " should match an exact sequence name")
	assert(
		Contract.matchesSequenceName("PeepilabuOwner_Rig|" .. sequenceName, action),
		action .. " should match the Studio-imported sequence name"
	)
	assert(not Contract.matchesSequenceName("Wrong_" .. sequenceName, action), action .. " should reject unrelated prefixes")
end

local expectedAttachments = {
	Back = "ATTACH_Back",
	FruitL = "ATTACH_Fruit_L",
	FruitR = "ATTACH_Fruit_R",
	Mouth = "ATTACH_Mouth",
	OrderBillboard = "ATTACH_OrderBillboard",
	ShopkeeperProp = "ATTACH_ShopkeeperProp",
}

for key, instanceName in expectedAttachments do
	assert(Contract.attachmentName(key) == instanceName, key .. " should resolve its exact imported name")
end

local acceptedIds = {
	{ input = 123, expected = "rbxassetid://123" },
	{ input = "456", expected = "rbxassetid://456" },
	{ input = " rbxassetid://789 ", expected = "rbxassetid://789" },
	{ input = "https://www.roblox.com/asset/?id=101112", expected = "rbxassetid://101112" },
}

for _, case in acceptedIds do
	assert(Contract.normalizeAnimationAssetId(case.input) == case.expected, tostring(case.input) .. " should normalize")
end

assert(Contract.normalizeAnimationAssetId(nil) == nil, "nil should be rejected")
for _, rejected in { false, 0, -1, 1.5, "", "rbxassetid://0", "active://temporary", "not-an-id" } do
	assert(Contract.normalizeAnimationAssetId(rejected) == nil, tostring(rejected) .. " should be rejected")
end

print("Owner character contract passed action, attachment, sequence, and animation ID checks")
