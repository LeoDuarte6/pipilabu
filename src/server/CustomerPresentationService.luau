--!strict

-- Studio-only customer visual integration. This service owns no gameplay state:
-- GameService remains authoritative for prompts, queue membership, handoff,
-- rewards, timers, and customer movement.

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Contract = require(projectRoot:WaitForChild("CustomerPresentationContract"))
local CharacterMaterialAdapter = require(script.Parent:WaitForChild("CharacterMaterialAdapter"))

type ActionName = Contract.ActionName
type ExitAction = Contract.ExitAction

export type Options = {
	Enabled: boolean?,
	AllowUnapprovedCandidateInStudio: boolean?,
	AllowStudioKeyframeSequences: boolean?,
	RequireInitialAnimation: boolean?,
	InitialAnimation: ActionName?,
	ExitAnimation: ExitAction?,
}

export type PlayOptions = {
	FadeTime: number?,
	Weight: number?,
	Speed: number?,
	Looped: boolean?,
	Priority: Enum.AnimationPriority?,
	PhaseOffsetNormalized: number?,
}

export type CandidateAudit = {
	Found: boolean,
	ApprovedForPresentation: boolean,
	TechnicalValidated: boolean,
	MeshPartCount: number,
	BoneCount: number,
	HasAnimationHost: boolean,
	HasPrimaryPart: boolean,
	MissingMeshIds: { string },
	MissingAnimations: { string },
	AnimationStates: { [ActionName]: string },
}

export type ActivationResult = {
	Activated: boolean,
	Code: string,
	Audit: CandidateAudit,
}

export type AttachResult = {
	Attached: boolean,
	Code: string,
	Model: Model?,
}

export type PlaybackResult = {
	Played: boolean,
	Code: string,
	Action: ActionName,
	Track: AnimationTrack?,
}

type AnimationRuntime = {
	Model: Model,
	Animator: Animator,
	Tracks: { [ActionName]: AnimationTrack },
	Animations: { [ActionName]: Animation },
}

type ActivationState = {
	Candidate: Model,
	AnimationRoot: Instance,
	Sequences: { [ActionName]: KeyframeSequence },
	ContentIds: { [ActionName]: string },
	AvailableActions: { [string]: boolean },
	Options: Options,
}

type CustomerState = {
	Customer: Model,
	Visual: Model,
	Runtime: AnimationRuntime,
	GameplayRoot: BasePart,
	HiddenPrimitiveParts: { [BasePart]: number },
	Serial: number,
}

local CustomerPresentationService = {}
local activationState: ActivationState? = nil
local activeCustomers: { [Model]: CustomerState } = {}

local DEFAULT_PRIORITIES: { [ActionName]: Enum.AnimationPriority } = {
	Idle = Enum.AnimationPriority.Idle,
	Receive = Enum.AnimationPriority.Action,
	Hold = Enum.AnimationPriority.Action,
	Happy = Enum.AnimationPriority.Action,
	Run = Enum.AnimationPriority.Movement,
	TurnLeave = Enum.AnimationPriority.Action,
}

local DEFAULT_LOOPED: { [ActionName]: boolean } = {
	Idle = true,
	Receive = false,
	Hold = true,
	Happy = false,
	Run = true,
	TurnLeave = false,
}

local function emptyAudit(): CandidateAudit
	local animationStates: { [ActionName]: string } = {}
	local missingAnimations: { string } = {}
	for _, action in Contract.Actions do
		animationStates[action] = "MissingAnimationContent"
		table.insert(missingAnimations, Contract.sequenceName(action))
	end

	return table.freeze({
		Found = false,
		ApprovedForPresentation = false,
		TechnicalValidated = false,
		MeshPartCount = 0,
		BoneCount = 0,
		HasAnimationHost = false,
		HasPrimaryPart = false,
		MissingMeshIds = table.freeze({}),
		MissingAnimations = table.freeze(missingAnimations),
		AnimationStates = table.freeze(animationStates),
	})
end

local function sortedDescendants(root: Instance): { Instance }
	local descendants = root:GetDescendants()
	table.sort(descendants, function(left, right)
		return left:GetFullName() < right:GetFullName()
	end)
	return descendants
end

local function locateCandidate(): Model?
	local folder = ServerStorage:FindFirstChild(Contract.CandidateFolderName)
	local candidate = folder and folder:FindFirstChild(Contract.CandidateModelName)
	if candidate and candidate:IsA("Model") then
		return candidate
	end
	return nil
end

local function locateAnimationRoot(): Instance?
	local saves = ServerStorage:FindFirstChild(Contract.AnimationSavesFolderName)
	local root = saves and saves:FindFirstChild(Contract.AnimationSetName)
	return root
end

local function findSequence(animationRoot: Instance?, action: ActionName): KeyframeSequence?
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

local function countCandidateGeometry(candidate: Model): (number, number, { string })
	local meshPartCount = 0
	local boneCount = 0
	local missingMeshIds: { string } = {}
	for _, descendant in candidate:GetDescendants() do
		if descendant:IsA("MeshPart") then
			meshPartCount += 1
			if descendant.MeshId == "" then
				table.insert(missingMeshIds, descendant:GetFullName())
			end
		elseif descendant:IsA("Bone") then
			boneCount += 1
		end
	end
	table.sort(missingMeshIds)
	return meshPartCount, boneCount, missingMeshIds
end

function CustomerPresentationService.AuditCandidate(candidateOverride: Model?, animationRootOverride: Instance?): CandidateAudit
	local candidate = candidateOverride or locateCandidate()
	if not candidate then
		return emptyAudit()
	end

	local meshPartCount, boneCount, missingMeshIds = countCandidateGeometry(candidate)
	local animationRoot = animationRootOverride
	if animationRoot == nil then
		animationRoot = locateAnimationRoot()
	end

	local animationStates: { [ActionName]: string } = {}
	local missingAnimations: { string } = {}
	for _, action in Contract.Actions do
		local sequence = findSequence(animationRoot, action)
		if sequence then
			animationStates[action] = "KeyframeSequenceReady"
		else
			animationStates[action] = "MissingAnimationContent"
			table.insert(missingAnimations, Contract.sequenceName(action))
		end
	end

	return table.freeze({
		Found = true,
		ApprovedForPresentation = candidate:GetAttribute("ApprovedForPresentation") == true,
		TechnicalValidated = candidate:GetAttribute("TechnicalValidated") == true,
		MeshPartCount = meshPartCount,
		BoneCount = boneCount,
		HasAnimationHost = candidate:FindFirstChildWhichIsA("AnimationController", true) ~= nil
			or candidate:FindFirstChildWhichIsA("Humanoid", true) ~= nil,
		HasPrimaryPart = candidate.PrimaryPart ~= nil,
		MissingMeshIds = table.freeze(missingMeshIds),
		MissingAnimations = table.freeze(missingAnimations),
		AnimationStates = table.freeze(animationStates),
	})
end

local function activationResult(activated: boolean, code: string, audit: CandidateAudit): ActivationResult
	return table.freeze({
		Activated = activated,
		Code = code,
		Audit = audit,
	})
end

function CustomerPresentationService.Activate(options: Options?): ActivationResult
	local resolvedOptions: Options = options or {}
	local audit = emptyAudit()
	if resolvedOptions.Enabled ~= true then
		return activationResult(false, "DisabledByConfig", audit)
	end
	if not RunService:IsStudio() then
		return activationResult(false, "OutsideStudio", audit)
	end
	if resolvedOptions.AllowStudioKeyframeSequences ~= true then
		return activationResult(false, "StudioKeyframesDisabled", audit)
	end
	if resolvedOptions.InitialAnimation and not Contract.isActionName(resolvedOptions.InitialAnimation) then
		return activationResult(false, "InvalidInitialAnimation", audit)
	end
	if resolvedOptions.ExitAnimation and resolvedOptions.ExitAnimation ~= "Run" and resolvedOptions.ExitAnimation ~= "TurnLeave" then
		return activationResult(false, "InvalidExitAnimation", audit)
	end
	if activationState then
		return activationResult(true, "AlreadyActive", audit)
	end
	audit = CustomerPresentationService.AuditCandidate(nil, nil)

	local candidate = locateCandidate()
	if not candidate then
		return activationResult(false, "CandidateMissing", audit)
	end
	if audit.TechnicalValidated ~= true then
		return activationResult(false, "CandidateNotTechnicallyValidated", audit)
	end
	if audit.ApprovedForPresentation ~= true and resolvedOptions.AllowUnapprovedCandidateInStudio ~= true then
		return activationResult(false, "CandidateNotApprovedForPresentation", audit)
	end
	if audit.MeshPartCount == 0 or #audit.MissingMeshIds > 0 then
		return activationResult(false, "CandidateMeshInvalid", audit)
	end
	if not audit.HasPrimaryPart then
		return activationResult(false, "CandidatePrimaryPartMissing", audit)
	end
	if not audit.HasAnimationHost then
		return activationResult(false, "CandidateAnimationHostMissing", audit)
	end
	if #audit.MissingAnimations > 0 then
		return activationResult(false, "CustomerAnimationsMissing", audit)
	end

	local animationRoot = locateAnimationRoot()
	if not animationRoot then
		return activationResult(false, "AnimationRootMissing", audit)
	end

	local sequences: { [ActionName]: KeyframeSequence } = {}
	local availableActions: { [string]: boolean } = {}
	for _, action in Contract.Actions do
		local sequence = findSequence(animationRoot, action)
		if not sequence then
			return activationResult(false, "CustomerAnimationsMissing", audit)
		end
		sequences[action] = sequence
		availableActions[action] = true
	end

	activationState = {
		Candidate = candidate,
		AnimationRoot = animationRoot,
		Sequences = sequences,
		ContentIds = {},
		AvailableActions = availableActions,
		Options = resolvedOptions,
	}
	return activationResult(true, "StudioCustomerCandidateReady", audit)
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
	animator.Name = "CustomerRuntimeAnimator"
	animator.Parent = host
	return animator
end

local function createRuntime(model: Model): (AnimationRuntime?, string?)
	local animator = findAnimator(model)
	if not animator then
		return nil, "MissingAnimationController"
	end

	return {
		Model = model,
		Animator = animator,
		Tracks = {},
		Animations = {},
	}, nil
end

local function stopTracks(runtime: AnimationRuntime)
	for _, action in Contract.Actions do
		local track = runtime.Tracks[action]
		if track then
			track:Stop(0.08)
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

local function restorePrimitiveGeometry(state: CustomerState)
	for part, transparency in state.HiddenPrimitiveParts do
		if part.Parent then
			part.Transparency = transparency
		end
	end
	state.HiddenPrimitiveParts = {}
end

local function cleanupCustomerState(customer: Model, state: CustomerState)
	if activeCustomers[customer] == state then
		activeCustomers[customer] = nil
	end
	state.Serial += 1
	stopTracks(state.Runtime)
	restorePrimitiveGeometry(state)
	if state.Visual.Parent then
		state.Visual:Destroy()
	end
	if customer.Parent then
		customer:SetAttribute("CustomerPresentationV4", nil)
	end
end

local function playbackFailure(customer: Model, state: CustomerState, action: ActionName, code: string): PlaybackResult
	cleanupCustomerState(customer, state)
	return table.freeze({
		Played = false,
		Code = code,
		Action = action,
		Track = nil,
	})
end

local function resolveContentId(action: ActionName): (string?, string?)
	local current = activationState
	if not current then
		return nil, "CustomerPresentationInactive"
	end

	local cached = current.ContentIds[action]
	if cached then
		return cached, nil
	end

	local sequence = current.Sequences[action]
	if not sequence then
		return nil, "MissingAnimationContent"
	end
	if current.Options.AllowStudioKeyframeSequences ~= true or not RunService:IsStudio() then
		return nil, "StudioKeyframesForbidden"
	end

	local ok, temporaryId = pcall(function()
		return KeyframeSequenceProvider:RegisterKeyframeSequence(sequence)
	end)
	if not ok or type(temporaryId) ~= "string" or temporaryId == "" then
		return nil, "StudioKeyframeRegistrationFailed"
	end

	current.ContentIds[action] = temporaryId
	return temporaryId, nil
end

local function playAction(customer: Model, action: ActionName, options: PlayOptions?): PlaybackResult
	local state = activeCustomers[customer]
	if not state then
		return table.freeze({
			Played = false,
			Code = "CustomerPresentationInactive",
			Action = action,
			Track = nil,
		})
	end

	local contentId, contentError = resolveContentId(action)
	if not contentId then
		return playbackFailure(customer, state, action, contentError or "MissingAnimationContent")
	end

	state.Serial += 1
	stopTracks(state.Runtime)

	local animation = Instance.new("Animation")
	animation.Name = "CustomerRuntime_" .. action
	animation.AnimationId = contentId
	animation.Parent = state.Visual

	local loadedTrack: AnimationTrack? = nil
	local ok, loadError = pcall(function()
		loadedTrack = state.Runtime.Animator:LoadAnimation(animation)
	end)
	if not ok or not loadedTrack then
		animation:Destroy()
		return playbackFailure(customer, state, action, "AnimationLoadFailed:" .. tostring(loadError))
	end

	local track = loadedTrack :: AnimationTrack
	track.Priority = if options and options.Priority then options.Priority else DEFAULT_PRIORITIES[action]
	track.Looped = if options and options.Looped ~= nil then options.Looped else DEFAULT_LOOPED[action]
	state.Runtime.Tracks[action] = track
	state.Runtime.Animations[action] = animation
	track:Play(
		if options and options.FadeTime then options.FadeTime else 0.12,
		if options and options.Weight then options.Weight else 1,
		if options and options.Speed then options.Speed else 1
	)

	local phaseOffset = if options then options.PhaseOffsetNormalized else nil
	if phaseOffset and track.Looped then
		local normalizedPhase = math.clamp(phaseOffset, 0, 0.999)
		local expectedState = state
		local expectedSerial = state.Serial
		task.spawn(function()
			for _ = 1, 12 do
				if activeCustomers[customer] ~= expectedState or expectedState.Serial ~= expectedSerial then
					return
				end
				if track.Length > 0 then
					track.TimePosition = track.Length * normalizedPhase
					return
				end
				RunService.Heartbeat:Wait()
			end
		end)
	end

	return table.freeze({
		Played = true,
		Code = "Playing",
		Action = action,
		Track = track,
	})
end

local function continueAfterTrack(
	customer: Model,
	state: CustomerState,
	serial: number,
	track: AnimationTrack?,
	callback: () -> ()
)
	if not track then
		callback()
		return
	end

	local continued = false
	local function continue()
		if continued then
			return
		end
		continued = true
		if activeCustomers[customer] ~= state or state.Serial ~= serial then
			return
		end
		callback()
	end

	track.Stopped:Once(continue)
	local fallbackDelay = math.max(0.18, track.Length)
	task.delay(fallbackDelay, continue)
end

function CustomerPresentationService.Attach(customer: Model): AttachResult
	if activeCustomers[customer] then
		return table.freeze({ Attached = true, Code = "AlreadyAttached", Model = activeCustomers[customer].Visual })
	end

	local current = activationState
	if not current then
		return table.freeze({ Attached = false, Code = "PresentationInactive", Model = nil })
	end

	local gameplayRoot = customer.PrimaryPart
	if not gameplayRoot then
		return table.freeze({ Attached = false, Code = "CustomerPrimaryPartMissing", Model = nil })
	end

	local cloned: Model? = nil
	local ok, cloneError = pcall(function()
		cloned = current.Candidate:Clone()
	end)
	if not ok or not cloned then
		return table.freeze({
			Attached = false,
			Code = "CustomerCandidateCloneFailed:" .. tostring(cloneError),
			Model = nil,
		})
	end

	local visual = cloned :: Model
	visual.Name = Contract.VisualName
	visual:SetAttribute("PresentationRole", "Peepilabu customer")
	visual:SetAttribute("RuntimeSource", current.Candidate:GetFullName())
	visual:SetAttribute("RuntimeValidationMode", true)
	visual:SetAttribute("RuntimeBodyPBRApplied", CharacterMaterialAdapter.Apply(visual, current.Candidate))
	local visualRoot = visual.PrimaryPart
	if not visualRoot then
		visual:Destroy()
		return table.freeze({ Attached = false, Code = "CustomerVisualPrimaryPartMissing", Model = nil })
	end

	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end

	visual.Parent = customer
	local positioned, positionError = pcall(function()
		visual:PivotTo(gameplayRoot.CFrame)
		local weld = Instance.new("WeldConstraint")
		weld.Name = Contract.RuntimeWeldName
		weld.Part0 = gameplayRoot
		weld.Part1 = visualRoot
		weld.Parent = visualRoot
	end)
	if not positioned then
		visual:Destroy()
		return table.freeze({
			Attached = false,
			Code = "CustomerVisualPositionFailed:" .. tostring(positionError),
			Model = nil,
		})
	end

	local runtime, runtimeError = createRuntime(visual)
	if not runtime then
		visual:Destroy()
		return table.freeze({ Attached = false, Code = runtimeError or "AnimationRuntimeCreationFailed", Model = nil })
	end

	local state: CustomerState = {
		Customer = customer,
		Visual = visual,
		Runtime = runtime,
		GameplayRoot = gameplayRoot,
		HiddenPrimitiveParts = {},
		Serial = 0,
	}
	activeCustomers[customer] = state

	local initialAction = current.Options.InitialAnimation or "Idle"
	local queueNumber = customer:GetAttribute("QueueNumber")
	local initialPlayback = playAction(customer, initialAction, {
		Looped = true,
		PhaseOffsetNormalized = Contract.idlePhaseForQueueNumber(if type(queueNumber) == "number" then queueNumber else 1),
	})
	if current.Options.RequireInitialAnimation ~= false and not initialPlayback.Played then
		-- playAction already restored the primitive fallback when it failed.
		return table.freeze({ Attached = false, Code = "InitialAnimationFailed:" .. initialPlayback.Code, Model = nil })
	end

	for _, descendant in customer:GetDescendants() do
		if descendant:IsA("BasePart")
			and descendant ~= gameplayRoot
			and not descendant:IsDescendantOf(visual)
		then
			state.HiddenPrimitiveParts[descendant] = descendant.Transparency
			descendant.Transparency = 1
		end
	end
	customer:SetAttribute("CustomerPresentationV4", true)

	return table.freeze({ Attached = true, Code = "Attached", Model = visual })
end

function CustomerPresentationService.Play(customer: Model, action: ActionName, options: PlayOptions?): PlaybackResult
	return playAction(customer, action, options)
end

function CustomerPresentationService.PlayHandoff(customer: Model): boolean
	local state = activeCustomers[customer]
	if not state then
		return false
	end

	local receive = playAction(customer, "Receive", { Looped = false })
	if not receive.Played then
		return false
	end
	local receiveSerial = state.Serial
	continueAfterTrack(customer, state, receiveSerial, receive.Track, function()
		local happy = playAction(customer, "Happy", { Looped = false })
		if not happy.Played then
			return
		end
		local happySerial = state.Serial
		continueAfterTrack(customer, state, happySerial, happy.Track, function()
			playAction(customer, "Hold", { Looped = true })
		end)
	end)
	return true
end

function CustomerPresentationService.PlayExit(customer: Model, requestedAction: ExitAction?): PlaybackResult
	local state = activeCustomers[customer]
	if not state then
		return table.freeze({
			Played = false,
			Code = "CustomerPresentationInactive",
			Action = "Run",
			Track = nil,
		})
	end

	local current = activationState
	if not current then
		return table.freeze({
			Played = false,
			Code = "CustomerPresentationInactive",
			Action = "Run",
			Track = nil,
		})
	end

	local requested = requestedAction or current.Options.ExitAnimation
	local selected: ExitAction? = if requested and current.AvailableActions[requested] == true
		then requested
		else Contract.chooseExitAction(current.AvailableActions)
	if not selected then
		return playbackFailure(customer, state, "Run", "ExitAnimationMissing")
	end

	return playAction(customer, selected, { Looped = selected == "Run" })
end

function CustomerPresentationService.Detach(customer: Model)
	local state = activeCustomers[customer]
	if state then
		cleanupCustomerState(customer, state)
	end
end

function CustomerPresentationService.Deactivate()
	local customers: { Model } = {}
	for customer in activeCustomers do
		table.insert(customers, customer)
	end
	for _, customer in customers do
		CustomerPresentationService.Detach(customer)
	end
	activationState = nil
end

return CustomerPresentationService
