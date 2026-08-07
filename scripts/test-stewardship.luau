local Stewardship = require("../src/shared/Stewardship")

local cases = {
	{ served = -2, marks = 0, stage = "OpenHands" },
	{ served = 0, marks = 0, stage = "OpenHands" },
	{ served = 2, marks = 0, stage = "OpenHands" },
	{ served = 3, marks = 1, stage = "WarmWelcome" },
	{ served = 6, marks = 2, stage = "GrowingLane" },
	{ served = 9, marks = 2, stage = "GrowingLane" },
	{ served = 10, marks = 3, stage = "GoodCareTravels" },
	{ served = 18, marks = 3, stage = "GoodCareTravels" },
}

for _, case in cases do
	local evaluation = Stewardship.evaluate(case.served)
	assert(evaluation.CareMarks == case.marks, string.format("served %d: wrong care marks", case.served))
	assert(evaluation.StageId == case.stage, string.format("served %d: wrong stage", case.served))
	assert(evaluation.Goodwill == math.max(0, math.floor(case.served)), string.format("served %d: wrong goodwill", case.served))
end

print(string.format("Stewardship contract passed %d boundary cases", #cases))
