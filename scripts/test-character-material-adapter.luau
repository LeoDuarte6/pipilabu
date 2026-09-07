local fs = require("@lune/fs")

local adapter = fs.readFile("src/server/CharacterMaterialAdapter.luau")
local owner = fs.readFile("src/server/OwnerPresentationService.luau")
local customer = fs.readFile("src/server/CustomerPresentationService.luau")

assert(
	string.find(adapter, 'model:FindFirstChild("MainFusedBody", true)', 1, true)
		and string.find(adapter, 'body:FindFirstChild("PipiLabuBodyPBR")', 1, true)
		and string.find(adapter, "readProtectedContentId", 1, true)
		and string.find(adapter, "local ok, value = pcall(reader)", 1, true)
		and string.find(adapter, "bodySurface.ColorMap", 1, true)
		and string.find(adapter, "bodySurface.NormalMap", 1, true)
		and string.find(adapter, "bodySurface.RoughnessMap", 1, true)
		and string.find(adapter, "bodySurface.MetalnessMap", 1, true)
		and string.find(adapter, '"IncompleteBodyPBRSurface"', 1, true)
		and string.find(adapter, 'source:GetAttribute("FallbackBodyColor")', 1, true)
		and string.find(adapter, "body.Material = Enum.Material.SmoothPlastic", 1, true),
	"the runtime must capability-guard all four Studio-authored body map reads"
)
assert(
	not string.find(adapter, "surface.ColorMap =", 1, true)
		and not string.find(adapter, "surface.NormalMap =", 1, true)
		and not string.find(adapter, "surface.Parent = descendant", 1, true),
	"runtime code must not cross Roblox plugin-security or spray the body atlas across face parts"
)
for _, name in { "Eye_L", "EyeWarmth_L", "EyeGlint", "Nose", "Smile", "PawLine", "Paw_L" } do
	assert(string.find(adapter, name, 1, true), "face palette is missing " .. name)
end
assert(
	string.find(owner, "CharacterMaterialAdapter.Apply(pendingClone, candidate)", 1, true),
	"owner runtime must use the material adapter"
)
assert(
	string.find(customer, "CharacterMaterialAdapter.Apply(visual, current.Candidate)", 1, true),
	"customer runtime must use the face palette even while its separate PBR atlas remains unavailable"
)

print("Pipi Labu character material adapter passed body-only PBR and authored face-palette gates")
