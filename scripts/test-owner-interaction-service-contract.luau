local fs = require("@lune/fs")

local copySource = fs.readFile("src/shared/Copy.luau")
local dialogueSource = fs.readFile("src/shared/OwnerDialogue.luau")
local serviceSource = fs.readFile("src/server/OwnerInteractionService.luau")
local bootstrapSource = fs.readFile("src/server/Bootstrap.server.luau")
local configSource = fs.readFile("src/shared/Config.luau")

assert(
	string.find(copySource, 'OwnerTalkAction = "Talk"', 1, true)
		and string.find(copySource, 'OwnerTalkObject = "Shopkeeper"', 1, true),
	"the owner must expose a plain in-world talk action"
)
assert(
	string.find(dialogueSource, 'context.ShiftState == "Won"', 1, true)
		and string.find(dialogueSource, 'context.ShiftState == "Lost"', 1, true)
		and string.find(dialogueSource, "context.NewMissedCustomer", 1, true)
		and string.find(dialogueSource, 'context.HeldAppleName == context.OrderedAppleName', 1, true)
		and string.find(dialogueSource, 'Key = "WrongApple"', 1, true)
		and string.find(dialogueSource, "math.max(0, context.Target - context.Served)", 1, true),
	"dialogue must respond to waiting, progress, correct/wrong apples, misses, wins, and losses"
)
assert(
	string.find(serviceSource, 'prompt.Name = "OwnerTalkPrompt"', 1, true)
		and string.find(serviceSource, "prompt.RequiresLineOfSight = false", 1, true)
		and string.find(serviceSource, "OwnerDialogue.resolve", 1, true)
		and string.find(serviceSource, 'OwnerPresentationService.Play("Talk"', 1, true)
		and string.find(serviceSource, 'OwnerPresentationService.Play("Idle")', 1, true)
		and string.find(serviceSource, 'player:SetAttribute("OwnerDialogueText", result.Dialogue)', 1, true)
		and string.find(serviceSource, 'player:SetAttribute("OwnerTaskText", result.Task)', 1, true),
	"the active owner must visibly speak, expose the current task, and return to idle"
)
assert(
	string.find(bootstrapSource, "OwnerInteractionService.Start(Config.OwnerInteraction)", 1, true),
	"the owner interaction must start only after owner presentation activates"
)
assert(
	string.find(configSource, "BubbleMaxDistance = 90", 1, true)
		and string.find(serviceSource, "gui.MaxDistance = maximumDistance", 1, true)
		and string.find(configSource, "MaximumDistance = 16", 1, true),
	"owner talk must remain readable across the market while keeping a bounded interaction range"
)

print("Pipi Labu owner interaction contract passed contextual talk/task and animation gates")
