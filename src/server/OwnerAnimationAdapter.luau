--!strict

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Contract = require(projectRoot:WaitForChild("OwnerCharacterContract"))

type ActionName = Contract.ActionName

export type Options = {
	AllowStudioKeyframeSequences: boolean?,
}

export type PlayOptions = {
	FadeTime: number?,
	Weight: number?,
	Speed: number?,
	Looped: boolean?,
	Priority: Enum.AnimationPriority?,
}

export type ContentInspection = {
	Action: ActionName,
	Code: string,
	PublishedAnimationId: string?,
	KeyframeSequence: KeyframeSequence?,
	Source: string?,
}

export type PlaybackResult = {
	Played: boolean,
	Code: string,
	Action: ActionName,
	Source: string?,
	Track: AnimationTrack?,
}

export type Runtime = {
	Model: Model,
	Animator: Animator,
	AnimationRoot: Instance?,
	AllowStudioKeyframeSequences: boolean,
	Tracks: { [ActionName]: AnimationTrack },
	Animations: { [ActionName]: Animation },
	TemporaryContentIds: { [ActionName]: string },
}

local OwnerAnimationAdapter = {}

local DEFAULT_PRIORITIES: { [ActionName]: Enum.AnimationPriority } = {
	Idle = Enum.AnimationPriority.Idle,
	Talk = Enum.AnimationPriority.Action,
	Serve = Enum.AnimationPriority.Action2,
	Happy = Enum.AnimationPriority.Action,
	Stressed = Enum.AnimationPriority.Action,
}

local DEFAULT_LOOPED: { [ActionName]: boolean } = {
	Idle = true,
	Talk = true,
	Serve = false,
	Happy = false,
	Stressed = true,
}

local function sortedDescendants(root: Instance): { Instance }
	local descendants = root:GetDescendants()
	table.sort(descendants, function(left, right)
		return left:GetFullName() < right:GetFullName()
	end)
	return descendants
end

local function animationIdFromAttributes(instance: Instance, action: ActionName): (string?, string?)
	for _, attributeName in Contract.animationAttributeKeys(action) do
		local normalized = Contract.normalizeAnimationAssetId(instance:GetAttribute(attributeName))
		if normalized then
			return normalized, string.format("%s.%s", instance:GetFullName(), attributeName)
		end
	end

	local generic = Contract.normalizeAnimationAssetId(instance:GetAttribute("AnimationId"))
	if generic then
		return generic, string.format("%s.AnimationId", instance:GetFullName())
	end

	return nil, nil
end

local function findPublishedAnimation(model: Model, animationRoot: Instance?, action: ActionName): (string?, string?)
	local modelId, modelSource = animationIdFromAttributes(model, action)
	if modelId then
		return modelId, modelSource
	end

	local roots: { Instance } = { model }
	if animationRoot then
		table.insert(roots, animationRoot)
	end

	for _, root in roots do
		for _, descendant in sortedDescendants(root) do
			if descendant:IsA("Animation")
				and (descendant.Name == action or Contract.matchesSequenceName(descendant.Name, action))
			then
				local normalized = Contract.normalizeAnimationAssetId(descendant.AnimationId)
				if normalized then
					return normalized, descendant:GetFullName()
				end
			end
		end
	end

	return nil, nil
end

local function findKeyframeSequence(animationRoot: Instance?, action: ActionName): KeyframeSequence?
	if not animationRoot then
		return nil
	end

	for _, descendant in sortedDescendants(animationRoot) do
		if descendant:IsA("KeyframeSequence") and Contract.matchesSequenceName(descendant.Name, action) then
			return descendant
		end
	end
	return nil
end

local function findAnimator(model: Model): Animator?
	local existing = model:FindFirstChildWhichIsA("Animator", true)
	if existing then
		return existing
	end

	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	local host = controller or humanoid
	if not host then
		return nil
	end

	local animator = Instance.new("Animator")
	animator.Name = "OwnerRuntimeAnimator"
	animator.Parent = host
	return animator
end

function OwnerAnimationAdapter.inspect(model: Model, animationRoot: Instance?, action: ActionName): ContentInspection
	local publishedId, publishedSource = findPublishedAnimation(model, animationRoot, action)
	if publishedId then
		return table.freeze({
			Action = action,
			Code = "PublishedAnimationReady",
			PublishedAnimationId = publishedId,
			KeyframeSequence = nil,
			Source = publishedSource,
		})
	end

	local sequence = findKeyframeSequence(animationRoot, action)
	if sequence then
		local sequenceId, sequenceSource = animationIdFromAttributes(sequence, action)
		if sequenceId then
			return table.freeze({
				Action = action,
				Code = "PublishedAnimationReady",
				PublishedAnimationId = sequenceId,
				KeyframeSequence = sequence,
				Source = sequenceSource,
			})
		end

		return table.freeze({
			Action = action,
			Code = "StudioKeyframeSequenceOnly",
			PublishedAnimationId = nil,
			KeyframeSequence = sequence,
			Source = sequence:GetFullName(),
		})
	end

	return table.freeze({
		Action = action,
		Code = "MissingAnimationContent",
		PublishedAnimationId = nil,
		KeyframeSequence = nil,
		Source = nil,
	})
end

function OwnerAnimationAdapter.create(model: Model, animationRoot: Instance?, options: Options?): (Runtime?, string?)
	if not model:IsDescendantOf(workspace) then
		return nil, "ModelMustBeInWorkspace"
	end

	local animator = findAnimator(model)
	if not animator then
		return nil, "MissingAnimationController"
	end

	return {
		Model = model,
		Animator = animator,
		AnimationRoot = animationRoot,
		AllowStudioKeyframeSequences = options ~= nil and options.AllowStudioKeyframeSequences == true,
		Tracks = {},
		Animations = {},
		TemporaryContentIds = {},
	}, nil
end

local function resolveContentId(runtime: Runtime, action: ActionName): (string?, string?, string?)
	local inspection = OwnerAnimationAdapter.inspect(runtime.Model, runtime.AnimationRoot, action)
	if inspection.PublishedAnimationId then
		return inspection.PublishedAnimationId, inspection.Source, nil
	end

	if inspection.KeyframeSequence then
		if not runtime.AllowStudioKeyframeSequences then
			return nil, inspection.Source, "UnpublishedAnimation"
		end
		if not RunService:IsStudio() then
			return nil, inspection.Source, "StudioKeyframesForbiddenOutsideStudio"
		end

		local cached = runtime.TemporaryContentIds[action]
		if cached then
			return cached, inspection.Source, nil
		end

		local ok, temporaryId = pcall(function()
			return KeyframeSequenceProvider:RegisterKeyframeSequence(inspection.KeyframeSequence :: KeyframeSequence)
		end)
		if not ok or type(temporaryId) ~= "string" or temporaryId == "" then
			return nil, inspection.Source, "StudioKeyframeRegistrationFailed"
		end

		runtime.TemporaryContentIds[action] = temporaryId
		return temporaryId, inspection.Source, nil
	end

	return nil, nil, inspection.Code
end

function OwnerAnimationAdapter.play(runtime: Runtime, action: ActionName, options: PlayOptions?): PlaybackResult
	local contentId, source, resolutionError = resolveContentId(runtime, action)
	if not contentId then
		return table.freeze({
			Played = false,
			Code = resolutionError or "MissingAnimationContent",
			Action = action,
			Source = source,
			Track = nil,
		})
	end

	-- Idle is the base layer. Named reactions replace one another so repeated
	-- service events cannot accumulate competing action tracks over time.
	local actionsToStop: { ActionName } = {}
	for _, playingAction in Contract.Actions do
		if runtime.Tracks[playingAction] and (action == "Idle" or playingAction ~= "Idle") then
			table.insert(actionsToStop, playingAction)
		end
	end
	for _, playingAction in actionsToStop do
		local playingTrack = runtime.Tracks[playingAction]
		if playingTrack then
			playingTrack:Stop(0.08)
			playingTrack:Destroy()
			runtime.Tracks[playingAction] = nil
		end
		local playingAnimation = runtime.Animations[playingAction]
		if playingAnimation then
			playingAnimation:Destroy()
			runtime.Animations[playingAction] = nil
		end
	end

	local previous = runtime.Tracks[action]
	if previous then
		previous:Stop(0)
		previous:Destroy()
		runtime.Tracks[action] = nil
	end
	local previousAnimation = runtime.Animations[action]
	if previousAnimation then
		previousAnimation:Destroy()
		runtime.Animations[action] = nil
	end

	local animation = Instance.new("Animation")
	animation.Name = "OwnerRuntime_" .. action
	animation.AnimationId = contentId
	animation.Parent = runtime.Model

	local loadedTrack: AnimationTrack? = nil
	local ok, loadError = pcall(function()
		loadedTrack = runtime.Animator:LoadAnimation(animation)
	end)
	if not ok or not loadedTrack then
		animation:Destroy()
		return table.freeze({
			Played = false,
			Code = "AnimationLoadFailed:" .. tostring(loadError),
			Action = action,
			Source = source,
			Track = nil,
		})
	end

	local track = loadedTrack :: AnimationTrack
	track.Priority = if options and options.Priority then options.Priority else DEFAULT_PRIORITIES[action]
	track.Looped = if options and options.Looped ~= nil then options.Looped else DEFAULT_LOOPED[action]
	runtime.Tracks[action] = track
	runtime.Animations[action] = animation
	track:Play(
		if options and options.FadeTime then options.FadeTime else 0.12,
		if options and options.Weight then options.Weight else 1,
		if options and options.Speed then options.Speed else 1
	)

	return table.freeze({
		Played = true,
		Code = "Playing",
		Action = action,
		Source = source,
		Track = track,
	})
end

function OwnerAnimationAdapter.stopAll(runtime: Runtime, fadeTime: number?)
	for _, action in Contract.Actions do
		local track = runtime.Tracks[action]
		if track then
			track:Stop(fadeTime or 0.1)
			track:Destroy()
			runtime.Tracks[action] = nil
		end
	end
	for _, action in Contract.Actions do
		local animation = runtime.Animations[action]
		if animation then
			animation:Destroy()
			runtime.Animations[action] = nil
		end
	end
end

function OwnerAnimationAdapter.destroy(runtime: Runtime)
	OwnerAnimationAdapter.stopAll(runtime, 0)
	table.clear(runtime.TemporaryContentIds)
end

return OwnerAnimationAdapter
