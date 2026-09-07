local fs = require("@lune/fs")

local service = fs.readFile("src/server/PhysicsLabService.luau")
local waterClient = fs.readFile("src/client/PhysicsLabWater.client.luau")
local dragClient = fs.readFile("src/client/PhysicsLabDrag.client.luau")

assert(
	string.find(service, "Enum.DragDetectorResponseStyle.Geometric", 1, true)
		and string.find(service, "detector.RunLocally = true", 1, true)
		and string.find(dragClient, "ray.Origin + ray.Direction * dragDepth", 1, true)
		and not string.find(dragClient, "dragPlaneY", 1, true)
		and string.find(dragClient, "target:PivotTo", 1, true)
		and string.find(dragClient, "camera:ViewportPointToRay(pointer.X, pointer.Y)", 1, true)
		and not string.find(dragClient, "GuiService:GetGuiInset()", 1, true)
		and string.find(waterClient, "camera:ViewportPointToRay(pointer.X, pointer.Y)", 1, true)
		and string.find(dragClient, "gameProcessed and select(1, targetFromPointer()) == nil", 1, true),
	"held objects must follow local pointer intent instead of lagging through server physical response"
)
assert(
	string.find(dragClient, 'target:GetAttribute("LabRole") == "JourneyApple"', 1, true)
		and string.find(dragClient, 'target:GetAttribute("JourneyState") == "PluckedDirty"', 1, true)
		and string.find(dragClient, "insideSensor(sensor, position, 1.35)", 1, true)
		and string.find(dragClient, 'sensor:GetAttribute("Soapy") ~= true', 1, true),
	"wash progress must require the same plucked apple, physical water entry, and poured soap"
)
assert(
	string.find(service, 'makePart(lab, "SoapBottle"', 1, true)
		and string.find(service, 'soap:GetAttribute("DragActive") == true and overWater', 1, true)
		and string.find(service, "soapDrag.Enabled = false", 1, true)
		and string.find(dragClient, 'target.Name == "SoapBottle"', 1, true)
		and string.find(dragClient, 'target:SetAttribute("Pouring", false)', 1, true)
		and string.find(dragClient, "pointerHitsSensor(sensor)", 1, true),
	"soap must be a held bottle poured over the basin"
)
assert(
	not string.find(service, 'ClickDetector")\n\tsoapClick', 1, true)
		and not string.find(service, 'soapClick.MouseClick', 1, true),
	"soap may not regress to a click-to-toggle state"
)
assert(
	string.find(service, 'waterCells.Name = "WashWaterSurface"', 1, true)
		and string.find(waterClient, "cursorWaterPoint", 1, true)
		and string.find(waterClient, "neighborAverage", 1, true),
	"the basin must expose a cursor/object-driven spring surface"
)
assert(
	string.find(service, 'lidAssembly.Name = "PhysicsCrateLidAssembly"', 1, true)
		and string.find(service, "lidDrag.ResponseStyle = Enum.DragDetectorResponseStyle.Geometric", 1, true)
		and string.find(service, "lidDrag.RunLocally = true", 1, true)
		and string.find(service, "lidDrag.Enabled = false", 1, true)
		and string.find(dragClient, 'dragMode == "RotateHingeX"', 1, true),
	"crate lid must rotate around an explicit responsive pivot"
)
assert(
	string.find(service, "soapDrag.Enabled = false", 1, true)
		and string.find(service, "lidDrag.Enabled = false", 1, true)
		and string.find(service, "branchDrag.Enabled = false", 1, true),
	"client-controlled targets must not have a second native controller fighting the pointer owner"
)
assert(
	string.find(service, 'branchApple:SetAttribute("ClientDragMode", "PluckSpring")', 1, true)
		and string.find(service, 'interactionEvent.Name = "PhysicsLabEvent"', 1, true)
		and string.find(service, 'action ~= "Pluck" or target ~= branchApple', 1, true)
		and string.find(service, 'reportedTension < 1 or reportedTension > 1.25', 1, true)
		and string.find(service, '(root.Position - branchApple.Position).Magnitude > 18', 1, true)
		and string.find(dragClient, 'dragMode == "PluckSpring"', 1, true)
		and string.find(dragClient, 'event:FireServer("Pluck", target, tension)', 1, true)
		and string.find(dragClient, 'target:SetAttribute("StemTension", tension)', 1, true)
		and string.find(dragClient, "Enum.EasingStyle.Back", 1, true),
	"pluck must use direct pointer tension, bounded server validation, a readable pop, and early-release recovery"
)
assert(
	string.find(service, 'makeApple(lab, "JourneyApple"', 1, true)
		and not string.find(service, 'makeApple(lab, "BranchRuby"', 1, true)
		and not string.find(service, 'makeApple(lab, "DirtyRuby"', 1, true)
		and string.find(service, 'branchApple:SetAttribute("JourneyState", "PluckedDirty")', 1, true)
		and string.find(service, '"WashingDirty"', 1, true)
		and string.find(service, '"Clean"', 1, true)
		and string.find(service, '"CratedLocked"', 1, true),
	"the lab must expose one continuous dirty-to-clean-to-crated apple journey"
)
assert(
	string.find(service, 'basin.Name = "WashBasin"', 1, true)
		and string.find(service, 'basin:SetAttribute("Hollow", true)', 1, true)
		and string.find(service, 'makePart(basin, "BasinFloor"', 1, true)
		and string.find(service, 'makePart(basin, "BasinWallLeft"', 1, true)
		and string.find(service, 'makePart(lab, "WashWaterVolume"', 1, true),
	"the wash basin must be a hollow raised shell around visible deep water"
)
assert(
	string.find(service, 'crate.Name = "PhysicsCrate"', 1, true)
		and string.find(service, 'crate:SetAttribute("Hollow", true)', 1, true)
		and string.find(service, '"CrateInteriorSensor"', 1, true)
		and string.find(service, 'crateSlots.Name = "CrateGridSlots"', 1, true)
		and string.find(service, 'task.delay(0.38', 1, true)
		and string.find(service, 'branchApple:SetAttribute("JourneyState", "CratedLocked")', 1, true),
	"the crate must be hollow and lock a clean dropped apple after a brief physical fall"
)
assert(
	string.find(dragClient, "local followRatio = 0.2 + 0.4 * (tension ^ 1.5)", 1, true)
		and string.find(dragClient, "local appleTravel = math.min(pointerTravel * followRatio, maxTravel)", 1, true),
	"the attached apple must visibly lag behind the pointer under stem tension"
)
assert(
	not string.find(service, 'makePart(lab, "LabSign"', 1, true)
		and string.find(service, '"A  |  GRAB APPLE • PULL"', 1, true)
		and string.find(service, '"B  |  POUR SOAP + SCRUB"', 1, true)
		and string.find(service, '"C  |  LIFT LID"', 1, true),
	"the lab must communicate each verb without a redundant title slab occluding the stations"
)

print("Pipi Labu Physics Lab interaction contract passed pointer, soap-pour, water-response, and crate-pivot gates")
