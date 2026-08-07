--!strict

local Config = {
	ProjectName = "Jon and Leo Development",
	DevelopmentVersion = "0.3.0",
	Shop = table.freeze({
		StartingQueueSize = 3,
		MaximumQueueSize = 4,
		ServeReward = 1,
		CustomerRespawnDelay = 1.25,
		CustomerMoveTime = 0.7,
		PickupPromptDistance = 6,
		ServePromptDistance = 6,
	}),
}

return table.freeze(Config)
