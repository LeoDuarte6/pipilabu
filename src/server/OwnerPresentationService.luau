--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local projectRoot = ReplicatedStorage:WaitForChild("JonAndLeoDevelopment")
local Contract = require(projectRoot:WaitForChild("OwnerCharacterContract"))
local AnimationAdapter = require(script.Parent:WaitForChild("OwnerAnimationAdapter"))
local CharacterMaterialAdapter = require(script.Parent:WaitForChild("CharacterMaterialAdapter"))

type ActionName = Contract.ActionName
type AttachmentKey = Contract.AttachmentKey

export type Options = {
	Enabled: boolean?,
	AllowUnvalidatedCandidateInStudio: boolean?,
	AllowStudioKeyframeSequences: boolean?,
	RequireInitialAnimation: boolean?,
	InitialAnimation: ActionName?,
	RequiredAttachments: { AttachmentKey }?,
	PivotOffset: CFrame?,
	TargetPosition: { X: number, Y: number, Z: number }?,
	TargetYawDegrees: number?,
	ScaleMultiplier: number?,
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
	MissingAttachments: { string },
	AnimationStates: { [ActionName]: string },
}

export type ActivationResult = {
	Activated: boolean,
	Code: string,
	Model: Model?,
	Audit: CandidateAudit,
}

type ActiveState = {
	Model: Model,
	Fallback: Model,
	FallbackParent: Instance,
	FallbackName: string,
	Runtime: AnimationAdapter.Runtime,
	FallbackFolder: Folder,
}

local OwnerPresentationService = {}
local activeState: ActiveState? = nil

local function emptyAudit(): CandidateAudit
	local animationStates: { [ActionName]: string } = {}
	for _, action in Contract.Actions do
		animationStates[action] = "MissingAnimationContent"
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
		MissingAttachments = table.freeze({}),
		AnimationStates = table.freeze(animationStates),
	})
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
	return saves and saves:FindFirstChild(Contract.AnimationSetName) or nil
end

local function locateAnchor(): Model?
	local village = Workspace:FindFirstChild(Contract.VillageRootName)
	local anchor = village and village:FindFirstChild(Contract.AnchorName)
	if anchor and anchor:IsA("Model") then
		return anchor
	end
	return nil
end

local function sortedBaseParts(model: Model): { BasePart }
	local parts: { BasePart } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	table.sort(parts, function(left, right)
		return left:GetFullName() < right:GetFullName()
	end)
	return parts
end

local function findAttachment(model: Model, key: AttachmentKey): Instance?
	local exactName = Contract.attachmentName(key)
	local matches: { Instance } = {}
	for _, descendant in model:GetDescendants() do
		if descendant.Name == exactName
			and (descendant:IsA("Attachment") or descendant:IsA("Bone") or descendant:IsA("BasePart"))
		then
			table.insert(matches, descendant)
		end
	end
	table.sort(matches, function(left, right)
		return left:GetFullName() < right:GetFullName()
	end)
	return matches[1]
end

function OwnerPresentationService.AuditCandidate(candidateOverride: Model?): CandidateAudit
	local candidate = candidateOverride or locateCandidate()
	if not candidate then
		return emptyAudit()
	end

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

	local missingAttachments: { string } = {}
	for _, key in Contract.AttachmentKeys do
		if not findAttachment(candidate, key) then
			table.insert(missingAttachments, Contract.attachmentName(key))
		end
	end

	local animationRoot = locateAnimationRoot()
	local animationStates: { [ActionName]: string } = {}
	for _, action in Contract.Actions do
		animationStates[action] = AnimationAdapter.inspect(candidate, animationRoot, action).Code
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
		MissingAttachments = table.freeze(missingAttachments),
		AnimationStates = table.freeze(animationStates),
	})
end

local function activationResult(activated: boolean, code: string, model: Model?, audit: CandidateAudit): ActivationResult
	return table.freeze({
		Activated = activated,
		Code = code,
		Model = model,
		Audit = audit,
	})
end

local function candidateAllowed(candidate: Model, options: Options): (boolean, string)
	if candidate:GetAttribute("ApprovedForPresentation") == true and candidate:GetAttribute("TechnicalValidated") == true then
		return true, "ApprovedCandidate"
	end

	if options.AllowUnvalidatedCandidateInStudio == true and RunService:IsStudio() then
		return true, "StudioValidationCandidate"
	end

	if candidate:GetAttribute("TechnicalValidated") ~= true then
		return false, "CandidateNotTechnicallyValidated"
	end
	return false, "CandidateNotApprovedForPresentation"
end

local function validateRequiredAttachments(model: Model, keys: { AttachmentKey }?): (boolean, string?)
	if not keys then
		return true, nil
	end
	for _, key in keys do
		if not findAttachment(model, key) then
			return false, "MissingRequiredAttachment:" .. Contract.attachmentName(key)
		end
	end
	return true, nil
end

local function ensureRuntimeFallbackFolder(): (Folder?, string?)
	local existing = ServerStorage:FindFirstChild(Contract.RuntimeFallbackFolderName)
	if existing then
		if not existing:IsA("Folder") then
			return nil, "RuntimeFallbackPathOccupied"
		end
		return existing, nil
	end

	local folder = Instance.new("Folder")
	folder.Name = Contract.RuntimeFallbackFolderName
	folder.Parent = ServerStorage
	return folder, nil
end

function OwnerPresentationService.Activate(options: Options?): ActivationResult
	local resolvedOptions: Options = options or {}
	local audit = OwnerPresentationService.AuditCandidate(nil)
	if resolvedOptions.Enabled ~= true then
		return activationResult(false, "DisabledByDefault", nil, audit)
	end
	if activeState then
		return activationResult(true, "AlreadyActive", activeState.Model, audit)
	end

	local candidate = locateCandidate()
	if not candidate then
		return activationResult(false, "CandidateMissing", nil, audit)
	end
	local allowed, allowCode = candidateAllowed(candidate, resolvedOptions)
	if not allowed then
		return activationResult(false, allowCode, nil, audit)
	end
	if audit.MeshPartCount == 0 or #audit.MissingMeshIds > 0 then
		return activationResult(false, "CandidateMeshInvalid", nil, audit)
	end
	if not audit.HasPrimaryPart then
		return activationResult(false, "CandidatePrimaryPartMissing", nil, audit)
	end
	if not audit.HasAnimationHost then
		return activationResult(false, "CandidateAnimationHostMissing", nil, audit)
	end

	local anchor = locateAnchor()
	if not anchor then
		return activationResult(false, "PresentationAnchorMissing", nil, audit)
	end
	local fallback = anchor:FindFirstChild(Contract.PresentationSlotName)
	if not fallback or not fallback:IsA("Model") then
		return activationResult(false, "FallbackPresentationMissing", nil, audit)
	end

	local attachmentsValid, attachmentError = validateRequiredAttachments(candidate, resolvedOptions.RequiredAttachments)
	if not attachmentsValid then
		return activationResult(false, attachmentError :: string, nil, audit)
	end

	local fallbackFolder, folderError = ensureRuntimeFallbackFolder()
	if not fallbackFolder then
		return activationResult(false, folderError :: string, nil, audit)
	end
	if fallbackFolder:FindFirstChild(Contract.RuntimeFallbackName) then
		return activationResult(false, "StaleRuntimeFallbackPresent", nil, audit)
	end

	local clone: Model? = nil
	local cloned, cloneError = pcall(function()
		clone = candidate:Clone()
	end)
	if not cloned or not clone then
		if #fallbackFolder:GetChildren() == 0 then
			fallbackFolder:Destroy()
		end
		return activationResult(false, "CandidateCloneFailed:" .. tostring(cloneError), nil, audit)
	end

	local pendingClone = clone :: Model
	pendingClone.Name = "__OwnerShibaV4Pending"
	pendingClone:SetAttribute("PresentationRole", "Peepilabu owner")
	pendingClone:SetAttribute("RuntimeSource", candidate:GetFullName())
	pendingClone:SetAttribute("RuntimeValidationMode", allowCode == "StudioValidationCandidate")
	pendingClone:SetAttribute("RuntimeBodyPBRApplied", CharacterMaterialAdapter.Apply(pendingClone, candidate))
	local scaleMultiplier = resolvedOptions.ScaleMultiplier or 1
	if scaleMultiplier <= 0 or scaleMultiplier > 2 then
		pendingClone:Destroy()
		if #fallbackFolder:GetChildren() == 0 then
			fallbackFolder:Destroy()
		end
		return activationResult(false, "InvalidScaleMultiplier", nil, audit)
	end
	pendingClone:ScaleTo(pendingClone:GetScale() * scaleMultiplier)
	pendingClone:SetAttribute("RuntimeScaleMultiplier", scaleMultiplier)
	for _, part in sortedBaseParts(pendingClone) do
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
	end
	local positioned, positionError = pcall(function()
		local targetPosition = resolvedOptions.TargetPosition
		local target = if targetPosition
			then CFrame.new(targetPosition.X, targetPosition.Y, targetPosition.Z)
				* CFrame.Angles(0, math.rad(resolvedOptions.TargetYawDegrees or 0), 0)
			else fallback:GetPivot()
		pendingClone:PivotTo(target * (resolvedOptions.PivotOffset or CFrame.identity))
		pendingClone.Parent = anchor
	end)
	if not positioned then
		pendingClone:Destroy()
		if #fallbackFolder:GetChildren() == 0 then
			fallbackFolder:Destroy()
		end
		return activationResult(false, "CandidatePositionFailed:" .. tostring(positionError), nil, audit)
	end

	local runtime, runtimeError = AnimationAdapter.create(pendingClone, locateAnimationRoot(), {
		AllowStudioKeyframeSequences = resolvedOptions.AllowStudioKeyframeSequences == true,
	})
	if not runtime then
		pendingClone:Destroy()
		if #fallbackFolder:GetChildren() == 0 then
			fallbackFolder:Destroy()
		end
		return activationResult(false, runtimeError or "AnimationRuntimeCreationFailed", nil, audit)
	end

	local initialAction = resolvedOptions.InitialAnimation or "Idle"
	local initialPlayback = AnimationAdapter.play(runtime, initialAction, nil)
	local requireInitialAnimation = resolvedOptions.RequireInitialAnimation ~= false
	if requireInitialAnimation and not initialPlayback.Played then
		AnimationAdapter.destroy(runtime)
		pendingClone:Destroy()
		if #fallbackFolder:GetChildren() == 0 then
			fallbackFolder:Destroy()
		end
		return activationResult(false, "InitialAnimationFailed:" .. initialPlayback.Code, nil, audit)
	end

	local fallbackParent = fallback.Parent :: Instance
	local fallbackName = fallback.Name
	fallback.Name = Contract.RuntimeFallbackName
	fallback.Parent = fallbackFolder
	pendingClone.Name = Contract.PresentationSlotName
	anchor.PrimaryPart = pendingClone.PrimaryPart
	activeState = {
		Model = pendingClone,
		Fallback = fallback,
		FallbackParent = fallbackParent,
		FallbackName = fallbackName,
		Runtime = runtime,
		FallbackFolder = fallbackFolder,
	}

	return activationResult(true, allowCode, pendingClone, audit)
end

function OwnerPresentationService.Play(action: ActionName, options: AnimationAdapter.PlayOptions?): AnimationAdapter.PlaybackResult
	if not activeState then
		return table.freeze({
			Played = false,
			Code = "OwnerPresentationInactive",
			Action = action,
			Source = nil,
			Track = nil,
		})
	end
	return AnimationAdapter.play(activeState.Runtime, action, options)
end

function OwnerPresentationService.GetAttachment(key: AttachmentKey): Instance?
	if not activeState then
		return nil
	end
	return findAttachment(activeState.Model, key)
end

function OwnerPresentationService.GetAttachmentWorldCFrame(key: AttachmentKey): CFrame?
	local attachment = OwnerPresentationService.GetAttachment(key)
	if not attachment then
		return nil
	end
	if attachment:IsA("Attachment") or attachment:IsA("Bone") then
		return attachment.WorldCFrame
	end
	if attachment:IsA("BasePart") then
		return attachment.CFrame
	end
	return nil
end

function OwnerPresentationService.GetActiveModel(): Model?
	return if activeState then activeState.Model else nil
end

function OwnerPresentationService.Deactivate(): boolean
	local state = activeState
	if not state then
		return false
	end
	activeState = nil

	AnimationAdapter.destroy(state.Runtime)
	if state.Model.Parent then
		state.Model:Destroy()
	end
	if state.Fallback.Parent then
		state.Fallback.Name = state.FallbackName
		state.Fallback.Parent = state.FallbackParent
		if state.FallbackParent:IsA("Model") then
			state.FallbackParent.PrimaryPart = state.Fallback.PrimaryPart
		end
	end
	if #state.FallbackFolder:GetChildren() == 0 then
		state.FallbackFolder:Destroy()
	end
	return true
end

return OwnerPresentationService
