--!strict

-- Gate P1 is intentionally inert in the default v0.9.x playable. Flip this
-- flag only in a private Studio session after the named integration gate in
-- docs/codex/HANDOFF.md is explicitly opened.
local P1SpringyBranchConfig = {
	Enabled = false,
	StudioOnly = true,
	WorldName = "P1SpringyBranchPrototype",
	OriginX = 10,
	OriginY = 0.5,
	OriginZ = 3,
	InteractionHoldDuration = 0.12,
	TensionUpdateHz = 24,
	MaxBranchBendDegrees = 18,
	RecoverySettleSeconds = 0.45,
	Tuning = table.freeze({
		BranchReachStuds = 6,
		PullDistanceForMaxTension = 2.5,
		TwistDegreesForMaxTension = 70,
		PullContribution = 0.86,
		TwistContribution = 0.64,
		DetachThreshold = 0.82,
		SpringStrength = 34,
		Damping = 3.5,
		MaxReleaseVelocity = 18,
		CatchForgivenessStuds = 2.25,
		RecoveryDistanceStuds = 60,
	}),
}

return table.freeze(P1SpringyBranchConfig)
