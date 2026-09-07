--!strict

export type AppleKind = "Ruby" | "Honeygold"

export type AppleDefinition = {
	Id: AppleKind,
	DisplayName: string,
	ShortName: string,
	CrateName: string,
	Color: Color3,
	DarkColor: Color3,
}

local definitions: { [AppleKind]: AppleDefinition } = {
	Ruby = table.freeze({
		Id = "Ruby",
		DisplayName = "Ruby Apple",
		ShortName = "RUBY",
		CrateName = "Ruby Apples",
		Color = Color3.fromRGB(210, 49, 42),
		DarkColor = Color3.fromRGB(133, 35, 32),
	}),
	Honeygold = table.freeze({
		Id = "Honeygold",
		DisplayName = "Honeygold Apple",
		ShortName = "HONEYGOLD",
		CrateName = "Honeygold Apples",
		Color = Color3.fromRGB(239, 181, 54),
		DarkColor = Color3.fromRGB(145, 94, 24),
	}),
}

-- Deterministic on purpose: the first two orders teach the red crate, then the
-- gold request introduces exactly one new variable without random difficulty.
local orderSequence: { AppleKind } = {
	"Ruby",
	"Ruby",
	"Honeygold",
	"Ruby",
	"Honeygold",
	"Honeygold",
	"Ruby",
	"Honeygold",
	"Ruby",
	"Honeygold",
}

local AppleCatalog = {}

function AppleCatalog.get(kind: string?): AppleDefinition
	return definitions[kind :: AppleKind] or definitions.Ruby
end

function AppleCatalog.forCustomer(customerNumber: number): AppleDefinition
	local index = ((math.max(1, customerNumber) - 1) % #orderSequence) + 1
	return definitions[orderSequence[index]]
end

AppleCatalog.All = table.freeze({ definitions.Ruby, definitions.Honeygold })

return table.freeze(AppleCatalog)
