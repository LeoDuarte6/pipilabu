local fs = require("@lune/fs")

local hud = fs.readFile("src/client/HudView.luau")
local bootstrap = fs.readFile("src/client/Bootstrap.client.luau")
local copy = fs.readFile("src/shared/Copy.luau")

assert(string.find(hud, 'screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets', 1, true), "HUD must respect Core UI safe insets")
assert(string.find(hud, 'status.Name = "StatusMedallions"', 1, true), "approved top-left medallions are missing")
assert(string.find(hud, 'result.Name = "ShiftResult"', 1, true), "terminal result medallion is missing")
assert(string.find(hud, 'resultSymbol.Name = "WinSymbol"', 1, true), "win symbol is missing")
assert(string.find(hud, 'resultCross.Name = "LossSymbol"', 1, true), "loss symbol is missing")
assert(string.find(hud, 'camera.ViewportSize.X < 760', 1, true), "narrow-screen result repositioning is missing")
assert(not string.find(bootstrap, 'makeStatChip', 1, true), "rejected rectangular stat-chip implementation returned")
assert(not string.find(bootstrap, 'UDim2.fromOffset(404, 100)', 1, true), "rejected 404px HUD slab returned")
assert(string.find(copy, 'NextShiftButton = "NEXT SHIFT"', 1, true), "approved next-shift copy changed")
assert(string.find(copy, 'RetryButton = "TRY AGAIN"', 1, true), "loss action must stay distinct")

print("Pipi Labu HUD direction contract passed medallion, copy, safe-inset, and responsive-layout checks")
