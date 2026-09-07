--!strict

local Copy = require(script.Parent:WaitForChild("Copy"))

export type Context = {
	ShiftState: string,
	Served: number,
	Target: number,
	HasApple: boolean,
	HeldAppleName: string,
	OrderedAppleName: string,
	NewMissedCustomer: boolean,
}

export type Result = {
	Key: string,
	Dialogue: string,
	Task: string,
}

local OwnerDialogue = {}

function OwnerDialogue.resolve(context: Context): Result
	local remaining = math.max(0, context.Target - context.Served)
	if context.ShiftState == "Won" then
		return { Key = "Won", Dialogue = Copy.Owner.Won, Task = Copy.Owner.TaskComplete }
	end
	if context.ShiftState == "Lost" then
		return { Key = "Lost", Dialogue = Copy.Owner.Lost, Task = Copy.Owner.TaskWaiting }
	end
	if context.ShiftState ~= "Active" then
		return { Key = "Waiting", Dialogue = Copy.Owner.Waiting, Task = Copy.Owner.TaskWaiting }
	end
	if context.NewMissedCustomer then
		return {
			Key = "Missed",
			Dialogue = Copy.Owner.Missed,
			Task = string.format(Copy.Owner.TaskActive, remaining),
		}
	end
	if context.HasApple then
		if context.HeldAppleName ~= "" and context.HeldAppleName == context.OrderedAppleName then
			return {
				Key = "Matching",
				Dialogue = string.format(Copy.Owner.ActiveMatching, context.HeldAppleName),
				Task = string.format(Copy.Owner.TaskActive, remaining),
			}
		end
		return {
			Key = "WrongApple",
			Dialogue = string.format(Copy.Owner.ActiveWrong, context.HeldAppleName, context.OrderedAppleName),
			Task = string.format(Copy.Owner.TaskActive, remaining),
		}
	end
	return {
		Key = "NextCustomer",
		Dialogue = string.format(Copy.Owner.ActiveNoApple, context.Served + 1),
		Task = string.format(Copy.Owner.TaskActive, remaining),
	}
end

return table.freeze(OwnerDialogue)
