--!strict

local Config = {
	ProjectName = "Jon and Leo Development",
	DevelopmentVersion = "0.7.0",
	Camera = table.freeze({
		MinimumZoom = 0.5,
		MaximumZoom = 20,
		FieldOfView = 70,
	}),
	Audio = table.freeze({
		PickupSoundId = "rbxassetid://7381723941",
		PickupVolume = 0.1,
		ServeSoundId = "rbxassetid://99980076888596",
		ServeVolume = 0.55,
	}),
	Shift = table.freeze({
		DurationSeconds = 90,
		TargetServed = 10,
		MaximumMissed = 3,
		CustomerPatienceSeconds = 12,
		TickRateSeconds = 0.1,
	}),
	Shop = table.freeze({
		StartingQueueSize = 3,
		MaximumQueueSize = 4,
		ServeReward = 1,
		CustomerRespawnDelay = 1.25,
		CustomerMoveTime = 0.7,
		ServeCelebrationTime = 0.9,
		PickupPromptDistance = 6,
		ServePromptDistance = 6,
	}),
}

return table.freeze(Config)
