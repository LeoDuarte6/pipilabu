--!strict

export type Assignment = {
	PlayerId: number,
	BayId: string,
}

export type Result = {
	Accepted: boolean,
	Reason: string?,
	Assignment: Assignment?,
}

export type Registry = {
	assign: (playerId: number) -> Result,
	release: (playerId: number) -> Result,
	get: (playerId: number) -> Assignment?,
	count: () -> number,
	snapshot: () -> { Assignment },
}

local ShopAssignment = {}

local function validPlayerId(playerId: number): boolean
	return playerId == playerId and playerId > 0 and playerId < math.huge and playerId % 1 == 0
end

local function copyAssignment(assignment: Assignment): Assignment
	return {
		PlayerId = assignment.PlayerId,
		BayId = assignment.BayId,
	}
end

function ShopAssignment.newRegistry(bayIds: { string }): Registry
	assert(type(bayIds) == "table" and #bayIds > 0, "at least one shop bay is required")

	local orderedBays = table.clone(bayIds)
	local seenBays: { [string]: boolean } = {}
	for index, bayId in orderedBays do
		assert(type(bayId) == "string" and bayId ~= "", string.format("invalid shop bay at index %d", index))
		assert(not seenBays[bayId], string.format("duplicate shop bay %s", bayId))
		seenBays[bayId] = true
	end

	local byPlayer: { [number]: Assignment } = {}
	local playerByBay: { [string]: number } = {}

	local registry = {} :: any

	function registry.assign(playerId: number): Result
		if not validPlayerId(playerId) then
			return { Accepted = false, Reason = "InvalidPlayerId" }
		end

		local existing = byPlayer[playerId]
		if existing then
			return {
				Accepted = true,
				Reason = "AlreadyAssigned",
				Assignment = copyAssignment(existing),
			}
		end

		for _, bayId in orderedBays do
			if playerByBay[bayId] == nil then
				local assignment = {
					PlayerId = playerId,
					BayId = bayId,
				}
				byPlayer[playerId] = assignment
				playerByBay[bayId] = playerId
				return {
					Accepted = true,
					Assignment = copyAssignment(assignment),
				}
			end
		end

		return { Accepted = false, Reason = "NoShopAvailable" }
	end

	function registry.release(playerId: number): Result
		if not validPlayerId(playerId) then
			return { Accepted = false, Reason = "InvalidPlayerId" }
		end

		local existing = byPlayer[playerId]
		if not existing then
			return { Accepted = false, Reason = "NotAssigned" }
		end

		byPlayer[playerId] = nil
		playerByBay[existing.BayId] = nil
		return {
			Accepted = true,
			Assignment = copyAssignment(existing),
		}
	end

	function registry.get(playerId: number): Assignment?
		local existing = byPlayer[playerId]
		return if existing then copyAssignment(existing) else nil
	end

	function registry.count(): number
		local total = 0
		for _ in byPlayer do
			total += 1
		end
		return total
	end

	function registry.snapshot(): { Assignment }
		local result = {}
		for _, bayId in orderedBays do
			local playerId = playerByBay[bayId]
			if playerId then
				table.insert(result, copyAssignment(byPlayer[playerId]))
			end
		end
		return result
	end

	return registry :: Registry
end

return table.freeze(ShopAssignment)
