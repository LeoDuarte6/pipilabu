--!strict

-- A small deterministic shuffle bag for finite, unique value sets.
-- Every value is emitted exactly once per cycle, and cycle boundaries are
-- repaired so the immediately previous value can never repeat.

export type Bag<T> = {
	next: () -> T,
	cycle: () -> number,
	size: () -> number,
}

local MODULUS = 2147483647
local MULTIPLIER = 48271

local function normalizeSeed(seed: number?): number
	if seed == nil then
		return 1
	end

	assert(seed == seed and seed ~= math.huge and seed ~= -math.huge, "shuffle-bag seed must be finite")
	local normalized = math.floor(math.abs(seed)) % (MODULUS - 1)
	return if normalized == 0 then 1 else normalized
end

local function new<T>(items: { T }, seed: number?): Bag<T>
	assert(#items >= 2, "shuffle bag requires at least two values to prevent immediate repeats")

	local source = table.clone(items)
	for left = 1, #source do
		for right = left + 1, #source do
			assert(source[left] ~= source[right], "shuffle bag values must be unique")
		end
	end

	local randomState = normalizeSeed(seed)
	local working: { T } = {}
	local cursor = 1
	local completedRefills = 0
	local hasPrevious = false
	local previous: T? = nil

	local function nextIndex(upperBound: number): number
		randomState = (randomState * MULTIPLIER) % MODULUS
		return math.floor((randomState / MODULUS) * upperBound) + 1
	end

	local function refill()
		working = table.clone(source)
		for index = #working, 2, -1 do
			local swapIndex = nextIndex(index)
			working[index], working[swapIndex] = working[swapIndex], working[index]
		end

		if hasPrevious and working[1] == previous then
			working[1], working[2] = working[2], working[1]
		end

		cursor = 1
		completedRefills += 1
	end

	local function nextValue(): T
		if cursor > #working then
			refill()
		end

		local value = working[cursor]
		cursor += 1
		previous = value
		hasPrevious = true
		return value
	end

	return table.freeze({
		next = nextValue,
		cycle = function(): number
			return completedRefills
		end,
		size = function(): number
			return #source
		end,
	})
end

return table.freeze({
	new = new,
})
