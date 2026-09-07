local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
Color3 = roblox.Color3

local Config = require("../src/shared/Config")
local Copy = require("../src/shared/Copy")
local gameService = fs.readFile("src/server/GameService.luau")
local bootstrap = fs.readFile("src/client/Bootstrap.client.luau")
local hud = fs.readFile("src/client/HudView.luau")

-- GOLDEN-CHANGE: Leo and Jon asked for a shift-level stake whose reward is a
-- physically collectable cash object. Service count earns the variable pay;
-- completing all eight adds a clear bonus. Loss keeps humane partial pay.
assert(Config.Shift.PayoutBase == 2, "every completed shift needs a small guaranteed physical payout")
assert(Config.Shop.ServeReward == 1, "each served neighbor must contribute predictably to shift pay")
assert(Config.Shift.PayoutClearBonus == 4, "clearing the full shift must materially beat partial completion")
assert(Copy.Hud.CollectPayButton == "COLLECT PAY", "terminal action must direct the physical payout ritual")
assert(Copy.Hud.ShiftWonPaid == "SHIFT CLEAR\n$%d IN HAND", "collected pay must remain visible in the shift result")
assert(string.find(gameService, 'payout.Name = "PipilabuShiftPayout"', 1, true), "physical shift payout model is missing")
assert(string.find(gameService, 'prompt.Name = "TakeShiftPayoutPrompt"', 1, true), "physical payout needs a world prompt")
assert(string.find(gameService, 'note.CanCollide = canCollide', 1, true), "world cash must use honest physical collision")
assert(string.find(gameService, 'bundle.Name = "HeldShiftCash"', 1, true), "collected cash must become a held object")
assert(string.find(gameService, 'coins.Value += shiftPayoutAmount', 1, true), "cash balance must advance only when physical pay is collected")
assert(not string.find(gameService, 'coins.Value += shopConfig.ServeReward', 1, true), "invisible per-serve currency must not bypass payday")
assert(not string.find(gameService, 'coins.Value = 0', 1, true), "starting another shift must not erase earned cash")
assert(string.find(gameService, 'if shiftPayoutReady then', 1, true), "next shift must wait for physical pay collection")
assert(string.find(hud, 'dialogue.Name = "BottomDialogueSubtitle"', 1, true), "shopkeeper dialogue must have a bottom subtitle presentation")
assert(string.find(bootstrap, 'GetAttributeChangedSignal("OwnerDialogueSerial")', 1, true), "bottom subtitle must react to actual owner dialogue")
assert(string.find(Copy.Owner.PayoutTask, "better apples and recipes", 1, true), "payout must point toward the agreed progression desire")

local bannedFalseStakes = { "family death", "doom scroll", "bomb defusal" }
for _, phrase in bannedFalseStakes do
	assert(not string.find(string.lower(gameService .. bootstrap .. hud), phrase, 1, true), "ambient co-op chatter leaked into Pipi Labu")
end

print("Pipi Labu shift-stakes contract passed physical payday, retained balance, and bottom-subtitle gates")
