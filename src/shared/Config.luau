--!strict

local Config = {
	ProjectName = "Jon and Leo Development",
	DevelopmentVersion = "0.4.0",
	Camera = table.freeze({
		MinimumZoom = 6,
		MaximumZoom = 14,
	}),
	Audio = table.freeze({
		PickupSoundId = "rbxassetid://7381723941",
		ServeSoundId = "rbxassetid://99980076888596",
	}),
	Shop = table.freeze({
		StartingQueueSize = 3,
		MaximumQueueSize = 4,
		ServeReward = 1,
		CustomerRespawnDelay = 1.25,
		CustomerMoveTime = 0.7,
		ServeCelebrationTime = 0.48,
		PickupPromptDistance = 6,
		ServePromptDistance = 6,
	}),
}

return table.freeze(Config)
