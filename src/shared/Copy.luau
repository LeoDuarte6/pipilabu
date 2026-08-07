--!strict

-- Player-facing language lives here so the shared copy sheet can map one-to-one
-- to stable keys without making the running game depend on Google Docs.
local Copy = {
	Hud = table.freeze({
		Title = "PIPILABU",
		TitleAppleReady = "PIPILABU  •  APPLE READY",
		Celebration = "NICE SERVE!",
		Progress = "Coins  %d     Served  %d     Waiting  %d",
		ShiftActive = "TIME  %s     SERVED  %d/%d     MISSED  %d/%d",
		ShiftDetail = "Coins  %d     Waiting  %d     Patience  %ds",
		ShiftReady = "%d-SECOND SHIFT",
		ShiftWon = "SHIFT COMPLETE!",
		ShiftLost = "SHIFT OVER",
		StartButton = "START SHIFT  [R / Y]",
		RestartButton = "PLAY AGAIN  [R / Y]",
	}),
	Prompts = table.freeze({
		GiveAppleAction = "Give Apple",
		SmallDoge = "Small Doge",
		WaitingDoge = "Waiting Doge",
		WaitingDogeNumbered = "Waiting Doge #%d",
		OrderApple = "APPLE",
		Patience = "PATIENCE  %ds",
		Impatient = "TOO SLOW!",
		ThankYou = "THANK YOU!",
		TakeAppleAction = "Take One Apple",
		AppleCrate = "Apple Crate",
	}),
	Messages = table.freeze({
		Waiting = "Serve %d Doges before time runs out. You can miss %d.",
		ShiftStarted = "The shop is open - serve the first small Doge",
		ShiftWon = "Beautiful work - all 10 Doges served!",
		ShiftLostTime = "Time is up. Press R or Y to try again.",
		ShiftLostMisses = "Three Doges left impatient. Press R or Y to try again.",
		ShiftInProgress = "This shift is already in progress",
		MissedCustomer = "A Doge left impatient - keep moving!",
		TakeApple = "Take one apple from the crate",
		PawsFull = "Your paws are full - give it to the small Doge",
		AppleReady = "Apple ready - give it to the small Doge",
		ServeReadyDogeFirst = "Help the small Doge who's ready first",
		NeedsApple = "This small Doge ordered an apple - visit the crate",
		Sending = "Send it with care",
		Served = "Nice serve!",
	}),
}

return table.freeze(Copy)
