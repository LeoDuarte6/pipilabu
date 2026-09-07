--!strict

local Config = {
	ProjectName = "Jon and Leo Development",
	DisplayName = "Pipi Labu",
	DevelopmentVersion = "0.9.9-dev",
	PhysicsLab = table.freeze({
		Enabled = true,
		StudioOnly = true,
		OriginX = 32,
		OriginY = 0,
		OriginZ = 12,
	}),
	MarketPresentation = table.freeze({
		ShowCareHud = false,
	}),
	MultiplayerShopAssignment = table.freeze({
		-- The server-session adapter exists but is disabled. No live shop spawning,
		-- DataStore, teleport, or multiplayer behavior is enabled at this gate.
		Enabled = false,
		BayIds = table.freeze({ "Shop_01", "Shop_02", "Shop_03", "Shop_04" }),
	}),
	ProfilePersistence = table.freeze({
		-- DataStore integration exists only as a fail-closed candidate seam.
		-- Default gameplay never reads or writes persistent player data.
		Enabled = false,
		StoreName = "PipiLabuProfiles_v1",
		KeyPrefix = "player:",
	}),
	PhysicalInteractionKernel = table.freeze({
		-- Shared authority contract for future pluck, wash, crate, and drag
		-- interactions. No production verb is routed through it yet.
		Enabled = false,
		MaximumReachStuds = 7,
		LeaseSeconds = 1.5,
	}),
	OwnerPresentation = table.freeze({
		Enabled = true,
		ScaleMultiplier = 1.15,
		-- The owner is an interior shop NPC facing the service lane. This explicit
		-- target supersedes the old market-prototype anchor outside the shop.
		-- Keep the owner inside the shop but outside the service customer's sightline.
		-- The previous X=0 target covered the first customer in the populated line.
		TargetPosition = table.freeze({ X = -9, Y = 0.5, Z = -20 }),
		-- The Blender candidate's authored front points toward the service lane at
		-- zero yaw; the superseded primitive/recovery model used 180 degrees.
		TargetYawDegrees = 0,
		-- The imported v4 rig and KeyframeSequences are intentionally testable only
		-- inside Studio until their private Roblox assets finish validation.
		AllowUnvalidatedCandidateInStudio = true,
		AllowStudioKeyframeSequences = true,
		RequireInitialAnimation = true,
		InitialAnimation = "Idle",
	}),
	OwnerInteraction = table.freeze({
		Enabled = true,
		MaximumDistance = 16,
		BubbleMaxDistance = 90,
		BubbleSeconds = 7.5,
	}),
	CustomerPresentation = table.freeze({
		Enabled = true,
		-- The customer candidate is intentionally unapproved for presentation;
		-- this explicit exception is valid only inside Studio at this gate.
		AllowUnapprovedCandidateInStudio = true,
		AllowStudioKeyframeSequences = true,
		RequireInitialAnimation = true,
		InitialAnimation = "Idle",
		ExitAnimation = "Run",
	}),
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
		TargetServed = 8,
		MaximumMissed = 3,
		CustomerPatienceSeconds = 18,
		TickRateSeconds = 0.1,
		-- Every terminal shift produces a physical payday. Service determines the
		-- variable portion while the clear bonus makes the full line matter.
		PayoutBase = 2,
		PayoutClearBonus = 4,
		PayoutPosition = table.freeze({ X = -9, Y = 1.35, Z = -16.5 }),
	}),
	Shop = table.freeze({
		StartingQueueSize = 8,
		MaximumQueueSize = 10,
		-- Level one is a fixed eight-customer shift. Replacements and later
		-- population ramps stay closed until progression has its own design gate.
		FirstShiftPopulationCap = 8,
		-- V4's measured 2.10-stud visual width leaves a warm 0.15-stud gap here.
		-- Eight customers now fit in the actual service view instead of spilling
		-- behind the shop wall and owner.
		QueueSpacingStuds = 2.25,
		ServeReward = 1,
		CustomerRespawnDelay = 1.25,
		CustomerMoveTime = 0.7,
		-- Comfort-first pacing: the handoff must be readable, the catch must land,
		-- and the customer must get time to enjoy the apple before leaving.
		ServeCelebrationTime = 1.65,
		PromptHoldDuration = 0,
		HandoffDuration = 0.34,
		HandoffArcHeight = 0.62,
		HandoffSpinDegrees = 42,
		HandoffSettleTime = 0.16,
		WrongAppleOutDuration = 0.18,
		WrongAppleReturnDuration = 0.28,
		WrongAppleArcHeight = 0.48,
		EnjoymentApproachDuration = 0.28,
		EnjoymentBiteDuration = 0.14,
		PickupPromptDistance = 9,
		ServePromptDistance = 6,
	}),
}

return table.freeze(Config)
