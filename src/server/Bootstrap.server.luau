local ReplicatedStorage = game:GetService("ReplicatedStorage")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Config = require(projectRoot:WaitForChild("Config"))
local GameService = require(script.Parent:WaitForChild("GameService"))
local OwnerPresentationService = require(script.Parent:WaitForChild("OwnerPresentationService"))
local OwnerInteractionService = require(script.Parent:WaitForChild("OwnerInteractionService"))
local PlaytestRecorderService = require(script.Parent:WaitForChild("PlaytestRecorderService"))
local PhysicsLabService = require(script.Parent:WaitForChild("PhysicsLabService"))
local ShopAssignmentService = require(script.Parent:WaitForChild("ShopAssignmentService"))
local ProfilePersistenceService = require(script.Parent:WaitForChild("ProfilePersistenceService"))

print(string.format("[JonAndLeo] server online - %s v%s", Config.ProjectName, Config.DevelopmentVersion))

GameService.Start(Config)
PlaytestRecorderService.Start()
print(string.format("[PipiLabuPhysicsLab] %s", PhysicsLabService.Start(Config.PhysicsLab)))
local shopAssignmentActivation = ShopAssignmentService.Start(Config.MultiplayerShopAssignment)
print(string.format("[PipiLabuShops] %s", shopAssignmentActivation.Code))
local profilePersistenceActivation = ProfilePersistenceService.Start(Config.ProfilePersistence)
print(string.format("[PipiLabuProfiles] %s", profilePersistenceActivation.Code))

local ownerActivation = OwnerPresentationService.Activate(Config.OwnerPresentation)
print(string.format("[PeepilabuOwner] %s", ownerActivation.Code))

if ownerActivation.Activated then
	print(string.format("[PeepilabuOwnerTalk] %s", OwnerInteractionService.Start(Config.OwnerInteraction)))
end

if ownerActivation.Activated then
	local reactionSerial = 0

	local function playReaction(action, returnDelay)
		reactionSerial += 1
		local serial = reactionSerial
		OwnerPresentationService.Play(action, { Looped = false })
		if returnDelay then
			task.delay(returnDelay, function()
				if reactionSerial == serial then
					OwnerPresentationService.Play("Idle")
				end
			end)
		end
	end

	GameService.Lifecycle:Connect(function(eventName, snapshot)
		if eventName == GameService.LifecycleNames.ShiftStarted then
			reactionSerial += 1
			OwnerPresentationService.Play("Idle")
		elseif eventName == GameService.LifecycleNames.CustomerServed then
			reactionSerial += 1
			local serial = reactionSerial
			OwnerPresentationService.Play("Serve", { Looped = false })
			task.delay(0.78, function()
				if reactionSerial ~= serial then
					return
				end
				OwnerPresentationService.Play("Happy", { Looped = false })
				task.delay(0.72, function()
					if reactionSerial == serial then
						OwnerPresentationService.Play("Idle")
					end
				end)
			end)
		elseif eventName == GameService.LifecycleNames.CustomerMissed then
			playReaction("Stressed", 1.35)
		elseif eventName == GameService.LifecycleNames.ShiftEnded then
			local state = if type(snapshot) == "table" then snapshot.state else nil
			playReaction(if state == "Won" then "Happy" else "Stressed", 1.45)
		end
	end)
end
