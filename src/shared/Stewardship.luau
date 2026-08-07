--!strict

-- Pure, positive-only service consequence contract. It deliberately has no
-- timer, loss branch, persistence, ownership, or random event dependency.
export type Evaluation = {
	Served: number,
	Goodwill: number,
	CareMarks: number,
	StageId: string,
	StageName: string,
}

local stages = table.freeze({
	{
		Threshold = 0,
		CareMarks = 0,
		Id = "OpenHands",
		Name = "OPEN HANDS",
	},
	{
		Threshold = 3,
		CareMarks = 1,
		Id = "WarmWelcome",
		Name = "WARM WELCOME",
	},
	{
		Threshold = 6,
		CareMarks = 2,
		Id = "GrowingLane",
		Name = "GROWING LANE",
	},
	{
		Threshold = 10,
		CareMarks = 3,
		Id = "GoodCareTravels",
		Name = "GOOD CARE TRAVELS",
	},
})

local function evaluate(served: number): Evaluation
	local normalizedServed = math.max(0, math.floor(served))
	local selected = stages[1]

	for _, stage in ipairs(stages) do
		if normalizedServed >= stage.Threshold then
			selected = stage
		end
	end

	return table.freeze({
		Served = normalizedServed,
		Goodwill = normalizedServed,
		CareMarks = selected.CareMarks,
		StageId = selected.Id,
		StageName = selected.Name,
	})
end

return table.freeze({
	MaxCareMarks = stages[#stages].CareMarks,
	Thresholds = table.freeze({ 0, 3, 6, 10 }),
	evaluate = evaluate,
})
