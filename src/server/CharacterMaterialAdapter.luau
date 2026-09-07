--!strict

-- Runtime material bridge for imported Pipi Labu candidates. The authored PBR
-- atlas belongs only on MainFusedBody; applying it indiscriminately to eyes,
-- paws, nose, and linework produces the visibly corrupted patterned result.

local CharacterMaterialAdapter = {}

local DARK = Color3.fromRGB(46, 31, 25)
local WARM_EYE = Color3.fromRGB(121, 74, 36)
local CREAM = Color3.fromRGB(244, 221, 182)
local GLINT = Color3.fromRGB(255, 248, 226)
local FALLBACK_COAT = Color3.fromRGB(201, 145, 78)

local function hasContentId(value: string): boolean
	return string.match(value, "^rbxassetid://%d+$") ~= nil
		or string.match(value, "^https?://") ~= nil
end

local function readProtectedContentId(reader: () -> string): string?
	local ok, value = pcall(reader)
	if not ok or type(value) ~= "string" or not hasContentId(value) then
		return nil
	end
	return value
end

local function applyFacePalette(part: BasePart)
	local name = part.Name
	if name == "Eye_L" or name == "Eye_R" then
		part.Color = DARK
		part.Material = Enum.Material.SmoothPlastic
	elseif name == "EyeWarmth_L" or name == "EyeWarmth_R" then
		part.Color = WARM_EYE
		part.Material = Enum.Material.Neon
		part.Transparency = 0.32
	elseif string.find(name, "EyeGlint", 1, true) then
		part.Color = GLINT
		part.Material = Enum.Material.Neon
		part.Transparency = 0
	elseif name == "Nose"
		or name == "MouthStem"
		or string.find(name, "Smile", 1, true)
		or string.find(name, "PawLine", 1, true)
	then
		part.Color = DARK
		part.Material = Enum.Material.SmoothPlastic
	elseif name == "Paw_L" or name == "Paw_R" then
		part.Color = CREAM
		part.Material = Enum.Material.SmoothPlastic
	end
end

function CharacterMaterialAdapter.Apply(model: Model, source: Model): boolean
	local _source = source
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			applyFacePalette(descendant)
		end
	end

	local body = model:FindFirstChild("MainFusedBody", true)
	if not body or not body:IsA("MeshPart") then
		return false
	end
	-- Content properties on SurfaceAppearance are plugin-security protected.
	-- Studio authors the body surface onto the candidate after moderation; the
	-- runtime clone inherits it and only applies safe color/material properties.
	local surface = body:FindFirstChild("PipiLabuBodyPBR")
	local hasBodySurface = surface ~= nil and surface:IsA("SurfaceAppearance")
	local hasBodyPBR = false
	if hasBodySurface then
		local bodySurface = surface :: SurfaceAppearance
		-- Current cloud Studio/server capability rules can reject reads of these
		-- plugin-authored content properties. Treat an unreadable map exactly like
		-- a missing map so presentation falls back without aborting gameplay boot.
		hasBodyPBR = readProtectedContentId(function()
			return bodySurface.ColorMap
		end) ~= nil
			and readProtectedContentId(function()
				return bodySurface.NormalMap
			end) ~= nil
			and readProtectedContentId(function()
				return bodySurface.RoughnessMap
			end) ~= nil
			and readProtectedContentId(function()
				return bodySurface.MetalnessMap
			end) ~= nil
	end
	if not hasBodyPBR then
		local authoredFallback = source:GetAttribute("FallbackBodyColor")
		body.Color = if typeof(authoredFallback) == "Color3" then authoredFallback else FALLBACK_COAT
		body.Material = Enum.Material.SmoothPlastic
	end
	model:SetAttribute(
		"RuntimeMaterialState",
		if hasBodyPBR
			then "BodyPBRAndAuthoredFacePalette"
			elseif hasBodySurface then "IncompleteBodyPBRSurface"
			else "AuthoredFacePaletteOnly"
	)
	return hasBodyPBR
end

return table.freeze(CharacterMaterialAdapter)
