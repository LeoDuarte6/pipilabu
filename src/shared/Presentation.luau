--!strict

-- Shared authored tokens for the prototype's world fixtures and optional HUD.
-- The local village builder consumes this module through ReplicatedStorage so
-- the command-bar prototype and runtime feedback keep the same visual language.
local Presentation = {
	Palette = table.freeze({
		Ground = Color3.fromRGB(111, 145, 86),
		Path = Color3.fromRGB(163, 148, 126),
		Stone = Color3.fromRGB(188, 174, 151),
		Cream = Color3.fromRGB(240, 226, 200),
		Paper = Color3.fromRGB(248, 240, 222),
		Ink = Color3.fromRGB(52, 39, 31),
		Wood = Color3.fromRGB(126, 83, 56),
		WoodDark = Color3.fromRGB(73, 50, 38),
		AppleRed = Color3.fromRGB(194, 58, 48),
		Vermilion = Color3.fromRGB(211, 79, 61),
		Indigo = Color3.fromRGB(64, 76, 112),
		Persimmon = Color3.fromRGB(222, 130, 54),
		FlowerPink = Color3.fromRGB(222, 137, 157),
		Leaf = Color3.fromRGB(62, 112, 62),
		DogeCoat = Color3.fromRGB(222, 177, 112),
		Muzzle = Color3.fromRGB(244, 221, 182),
		CareGreen = Color3.fromRGB(92, 198, 102),
		CareSoft = Color3.fromRGB(184, 225, 168),
		Lantern = Color3.fromRGB(247, 187, 78),
	}),
	Ui = table.freeze({
		CardCornerRadius = UDim.new(0, 12),
		CardStrokeThickness = 1.5,
		HudLeft = 22,
		HudTop = 126,
	}),
}

return table.freeze(Presentation)
