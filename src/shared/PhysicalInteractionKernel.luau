--!strict

export type Config = {
	MaximumReachStuds: number,
	LeaseSeconds: number,
}

export type Result = {
	Accepted: boolean,
	Reason: string?,
	ObjectId: string?,
	OwnerPlayerId: number?,
	State: string?,
}

export type Registry = {
	beginGrab: (playerId: number, objectId: string, distanceStuds: number, now: number) -> Result,
	heartbeat: (playerId: number, objectId: string, distanceStuds: number, now: number) -> Result,
	release: (playerId: number, objectId: string, reason: string?) -> Result,
	consume: (playerId: number, objectId: string) -> Result,
	disconnect: (playerId: number) -> number,
	expire: (now: number) -> number,
	snapshot: () -> { [string]: { State: string, OwnerPlayerId: number?, LastSeenAt: number? } },
}

type ObjectState = {
	State: "Available" | "Held" | "Consumed",
	OwnerPlayerId: number?,
	LastSeenAt: number?,
}

local Kernel = {}

local function finite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

local function validPlayerId(playerId: number): boolean
	return finite(playerId) and playerId > 0 and playerId % 1 == 0
end

local function validObjectId(objectId: string): boolean
	return type(objectId) == "string" and objectId ~= ""
end

function Kernel.newRegistry(config: Config): Registry
	assert(finite(config.MaximumReachStuds) and config.MaximumReachStuds > 0, "MaximumReachStuds must be positive")
	assert(finite(config.LeaseSeconds) and config.LeaseSeconds > 0, "LeaseSeconds must be positive")

	local objects: { [string]: ObjectState } = {}
	local heldByPlayer: { [number]: string } = {}
	local registry = {} :: any

	local function available(objectId: string): ObjectState
		local state = objects[objectId]
		if not state then
			state = { State = "Available" }
			objects[objectId] = state
		end
		return state
	end

	local function releaseState(objectId: string, state: ObjectState)
		if state.OwnerPlayerId then
			heldByPlayer[state.OwnerPlayerId] = nil
		end
		state.State = "Available"
		state.OwnerPlayerId = nil
		state.LastSeenAt = nil
	end

	function registry.expire(now: number): number
		assert(finite(now), "expire time must be finite")
		local count = 0
		for objectId, state in objects do
			if state.State == "Held" and state.LastSeenAt and now - state.LastSeenAt > config.LeaseSeconds then
				releaseState(objectId, state)
				count += 1
			end
		end
		return count
	end

	function registry.beginGrab(playerId: number, objectId: string, distanceStuds: number, now: number): Result
		if not validPlayerId(playerId) then
			return { Accepted = false, Reason = "InvalidPlayerId" }
		end
		if not validObjectId(objectId) then
			return { Accepted = false, Reason = "InvalidObjectId" }
		end
		if not finite(distanceStuds) or distanceStuds < 0 or distanceStuds > config.MaximumReachStuds then
			return { Accepted = false, Reason = "OutOfReach" }
		end
		if not finite(now) then
			return { Accepted = false, Reason = "InvalidTime" }
		end

		registry.expire(now)
		local playerObject = heldByPlayer[playerId]
		if playerObject and playerObject ~= objectId then
			return { Accepted = false, Reason = "PlayerAlreadyHolding", ObjectId = playerObject }
		end

		local state = available(objectId)
		if state.State == "Consumed" then
			return { Accepted = false, Reason = "ObjectConsumed", ObjectId = objectId }
		end
		if state.State == "Held" then
			if state.OwnerPlayerId == playerId then
				state.LastSeenAt = now
				return { Accepted = true, Reason = "AlreadyHeld", ObjectId = objectId, OwnerPlayerId = playerId, State = "Held" }
			end
			return { Accepted = false, Reason = "OwnedByAnotherPlayer", ObjectId = objectId, OwnerPlayerId = state.OwnerPlayerId }
		end

		state.State = "Held"
		state.OwnerPlayerId = playerId
		state.LastSeenAt = now
		heldByPlayer[playerId] = objectId
		return { Accepted = true, ObjectId = objectId, OwnerPlayerId = playerId, State = "Held" }
	end

	function registry.heartbeat(playerId: number, objectId: string, distanceStuds: number, now: number): Result
		if not validPlayerId(playerId) or not validObjectId(objectId) or not finite(now) then
			return { Accepted = false, Reason = "InvalidHeartbeat" }
		end
		local state = objects[objectId]
		if not state or state.State ~= "Held" or state.OwnerPlayerId ~= playerId then
			return { Accepted = false, Reason = "NotOwner" }
		end
		if state.LastSeenAt and now - state.LastSeenAt > config.LeaseSeconds then
			releaseState(objectId, state)
			return { Accepted = false, Reason = "LeaseExpired", ObjectId = objectId, State = "Available" }
		end
		if not finite(distanceStuds) or distanceStuds < 0 or distanceStuds > config.MaximumReachStuds then
			releaseState(objectId, state)
			return { Accepted = false, Reason = "OutOfReachReleased", ObjectId = objectId, State = "Available" }
		end
		state.LastSeenAt = now
		return { Accepted = true, ObjectId = objectId, OwnerPlayerId = playerId, State = "Held" }
	end

	function registry.release(playerId: number, objectId: string, reason: string?): Result
		local state = objects[objectId]
		if not state or state.State ~= "Held" or state.OwnerPlayerId ~= playerId then
			return { Accepted = false, Reason = "NotOwner", ObjectId = objectId }
		end
		releaseState(objectId, state)
		return { Accepted = true, Reason = reason or "Released", ObjectId = objectId, State = "Available" }
	end

	function registry.consume(playerId: number, objectId: string): Result
		local state = objects[objectId]
		if not state or state.State ~= "Held" or state.OwnerPlayerId ~= playerId then
			return { Accepted = false, Reason = "NotOwner", ObjectId = objectId }
		end
		heldByPlayer[playerId] = nil
		state.State = "Consumed"
		state.OwnerPlayerId = nil
		state.LastSeenAt = nil
		return { Accepted = true, ObjectId = objectId, State = "Consumed" }
	end

	function registry.disconnect(playerId: number): number
		local objectId = heldByPlayer[playerId]
		if not objectId then
			return 0
		end
		local state = objects[objectId]
		if state and state.State == "Held" and state.OwnerPlayerId == playerId then
			releaseState(objectId, state)
			return 1
		end
		heldByPlayer[playerId] = nil
		return 0
	end

	function registry.snapshot()
		local result = {}
		for objectId, state in objects do
			result[objectId] = {
				State = state.State,
				OwnerPlayerId = state.OwnerPlayerId,
				LastSeenAt = state.LastSeenAt,
			}
		end
		return result
	end

	return registry :: Registry
end

return table.freeze(Kernel)
