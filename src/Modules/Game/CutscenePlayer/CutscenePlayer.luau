--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Packages.trove)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Types = require(script.Parent.Types)
local Animations = require(ReplicatedStorage.Shared.Modules.Assets.Animations)

type CharacterOptions = Types.CharacterOptions
type CharacterEntry = Types.CharacterEntry
type MarkerCallback = Types.MarkerCallback

local isServer = RunService:IsServer()

local cutsceneRemote: RemoteEvent? = nil

local function getRemote(): RemoteEvent?
	if cutsceneRemote then
		return cutsceneRemote
	end

	if isServer then
		local remote = ReplicatedStorage:FindFirstChild("CutsceneRemote")
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = "CutsceneRemote"
			remote.Parent = ReplicatedStorage
		end
		cutsceneRemote = remote :: RemoteEvent
	else
		cutsceneRemote = ReplicatedStorage:FindFirstChild("CutsceneRemote") :: RemoteEvent?
	end

	return cutsceneRemote
end

local CutscenePlayer = {}
CutscenePlayer.__index = CutscenePlayer

export type CutscenePlayerImpl = {
	_name: string,
	_id: string,
	_origin: CFrame,
	_characters: { CharacterEntry },
	_markerCallbacks: { MarkerCallback },
	_endCallbacks: { () -> () },
	_trove: typeof(Trove.new()),
	_destroyed: boolean,
	_playing: boolean,
	_cameraPart: BasePart?,
	_cameraAnimationName: string?,
	_cameraMoveset: string?,
	_cameraTrack: AnimationTrack?,
	_characterTracks: { [Model]: AnimationTrack },
	Ended: typeof(Signal.new()),
}

local function isPlayerCharacter(character: Model): boolean
	return Players:GetPlayerFromCharacter(character) ~= nil
end

local function resolveOptions(character: Model, options: CharacterOptions?): CharacterOptions
	local resolved: CharacterOptions = {
		position = false,
		lockCamera = true,
		animation = nil,
		moveset = nil,
	}

	if options then
		if options.position ~= nil then
			resolved.position = options.position
		end
		if options.lockCamera ~= nil then
			resolved.lockCamera = options.lockCamera
		end
		if options.animation ~= nil then
			resolved.animation = options.animation
		end
		if options.moveset ~= nil then
			resolved.moveset = options.moveset
		end
	end

	if not isPlayerCharacter(character) then
		resolved.lockCamera = false
	end

	return resolved
end

local function getAnimationId(animName: string, moveset: string?): string?
	if moveset then
		local movesetModule = ReplicatedStorage.Shared.Modules.Data.Moves.Movesets:FindFirstChild(moveset)
		if movesetModule then
			local ok, movesetData = pcall(require, movesetModule)
			if ok and movesetData.Animations and movesetData.Animations[animName] then
				return movesetData.Animations[animName]
			end
		end
	end

	local animId = Animations[animName]
	if animId and animId ~= "" and animId ~= "rbxassetid://" then
		return animId
	end

	if string.match(animName, "^rbxassetid://") then
		return animName
	end

	return nil
end

function CutscenePlayer.new(name: string): Types.CutsceneHandle
	local self = setmetatable({}, CutscenePlayer) :: CutscenePlayerImpl

	self._name = name
	self._id = name .. "_" .. tostring(tick()) .. "_" .. math.random(1000, 9999)
	self._origin = CFrame.new()
	self._characters = {}
	self._markerCallbacks = {}
	self._endCallbacks = {}
	self._trove = Trove.new()
	self._destroyed = false
	self._playing = false
	self._cameraPart = nil
	self._cameraAnimationName = nil
	self._cameraMoveset = nil
	self._cameraTrack = nil
	self._characterTracks = {}
	self.Ended = self._trove:Construct(Signal)

	return self :: any
end

function CutscenePlayer.SetOrigin(self: CutscenePlayerImpl, origin: CFrame): Types.CutsceneHandle
	self._origin = origin
	return self :: any
end

function CutscenePlayer.SetCameraAnimation(
	self: CutscenePlayerImpl,
	animationName: string,
	moveset: string?
): Types.CutsceneHandle
	self._cameraAnimationName = animationName
	self._cameraMoveset = moveset
	return self :: any
end

function CutscenePlayer.AddCharacter(
	self: CutscenePlayerImpl,
	character: Model,
	options: CharacterOptions?
): Types.CutsceneHandle
	local resolvedOptions = resolveOptions(character, options)

	table.insert(self._characters, {
		character = character,
		options = resolvedOptions,
		isPlayer = isPlayerCharacter(character),
		track = nil,
	})

	return self :: any
end

function CutscenePlayer.OnMarker(
	self: CutscenePlayerImpl,
	character: Model,
	markerName: string,
	callback: () -> ()
): Types.CutsceneHandle
	table.insert(self._markerCallbacks, {
		character = character,
		markerName = markerName,
		callback = callback,
	})
	return self :: any
end

function CutscenePlayer.OnEnd(self: CutscenePlayerImpl, callback: () -> ()): Types.CutsceneHandle
	table.insert(self._endCallbacks, callback)
	return self :: any
end

function CutscenePlayer._createCamera(self: CutscenePlayerImpl)
	local cameraRig = Instance.new("Model")
	cameraRig.Name = "CutsceneCamera_" .. self._id
	cameraRig.Parent = workspace

	local rootPart = Instance.new("Part")
	rootPart.Name = "Root"
	rootPart.Size = Vector3.new(1, 1, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.CanQuery = false
	rootPart.CanTouch = false
	rootPart.Anchored = true
	rootPart.CFrame = self._origin
	rootPart.Parent = cameraRig

	local cameraPart = Instance.new("Part")
	cameraPart.Name = "Camera"
	cameraPart.Size = Vector3.new(1, 1, 1)
	cameraPart.Transparency = 1
	cameraPart.CanCollide = false
	cameraPart.CanQuery = false
	cameraPart.CanTouch = false
	cameraPart.Anchored = false
	cameraPart.CFrame = self._origin
	cameraPart.Parent = cameraRig

	local motor = Instance.new("Motor6D")
	motor.Name = "CameraMotor"
	motor.Part0 = rootPart
	motor.Part1 = cameraPart
	motor.C0 = CFrame.new()
	motor.C1 = CFrame.new()
	motor.Parent = rootPart

	cameraRig.PrimaryPart = rootPart

	self._cameraPart = cameraPart
	self._trove:Add(cameraRig)

	task.wait() -- Ensure rig is fully parented before adding AnimationController

	if self._cameraAnimationName then
		local animController = Instance.new("AnimationController")
		animController.Parent = cameraRig
		self._trove:Add(animController)

		task.wait(0.1) -- Wait for AnimationController to initialize

		local animator = Instance.new("Animator")
		animator.Parent = animController

		task.wait(0.1) -- Wait for Animator to initialize

		local animId = getAnimationId(self._cameraAnimationName, self._cameraMoveset)
		if animId then
			print(`[CutscenePlayer] Loading camera animation: {self._cameraAnimationName} -> {animId}`)

			local animation = Instance.new("Animation")
			animation.AnimationId = animId
			self._trove:Add(animation)

			local success, track = pcall(function()
				return animator:LoadAnimation(animation)
			end)

			if success and track then
				self._cameraTrack = track
				print(`[CutscenePlayer] Camera animation loaded successfully, Length: {track.Length}`)

				track.Ended:Connect(function()
					print(`[CutscenePlayer] Camera animation ended`)
					self:_onEnd()
				end)
			else
				warn(`[CutscenePlayer] Failed to load camera animation '{self._cameraAnimationName}': {track}`)
			end
		else
			warn(`[CutscenePlayer] Camera animation '{self._cameraAnimationName}' not found in Animations.luau`)
		end
	end
end

function CutscenePlayer._getAnimator(self: CutscenePlayerImpl, target: Model): Animator?
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		return animator
	end

	local animController = target:FindFirstChildOfClass("AnimationController")
	if animController then
		local animator = animController:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = animController
		end
		return animator
	end

	return nil
end

function CutscenePlayer._positionCharacter(self: CutscenePlayerImpl, entry: CharacterEntry)
	local posOption = entry.options.position
	if not posOption then
		return
	end

	local character = entry.character
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not hrp then
		return
	end

	local targetCFrame: CFrame
	if typeof(posOption) == "CFrame" then
		targetCFrame = posOption
	else
		targetCFrame = hrp.CFrame
	end

	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		humanoid.AutoRotate = false
	end

	if typeof(posOption) == "CFrame" then
		local rayOrigin = targetCFrame.Position + Vector3.new(0, 5, 0)
		local rayDirection = Vector3.new(0, -20, 0)
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { character }

		local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
		if result then
			targetCFrame = CFrame.new(result.Position) * (targetCFrame - targetCFrame.Position)
		end

		local alignPosition = Instance.new("AlignPosition")
		alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
		alignPosition.Position = targetCFrame.Position + Vector3.new(0, 3, 0)
		alignPosition.MaxForce = 100000
		alignPosition.MaxVelocity = 50
		alignPosition.Responsiveness = 30

		local attachment = hrp:FindFirstChild("RootAttachment") :: Attachment?
		if not attachment then
			attachment = Instance.new("Attachment")
			attachment.Name = "RootAttachment"
			attachment.Parent = hrp
			self._trove:Add(attachment)
		end

		alignPosition.Attachment0 = attachment
		alignPosition.Parent = hrp
		self._trove:Add(alignPosition)

		local alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		alignOrientation.CFrame = targetCFrame
		alignOrientation.MaxTorque = 100000
		alignOrientation.Responsiveness = 30
		alignOrientation.Attachment0 = attachment
		alignOrientation.Parent = hrp
		self._trove:Add(alignOrientation)
	end
end

function CutscenePlayer._freezeCharacter(self: CutscenePlayerImpl, entry: CharacterEntry)
	local character = entry.character
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		local prevWalkSpeed = humanoid.WalkSpeed
		local prevJumpHeight = humanoid.JumpHeight
		local prevAutoRotate = humanoid.AutoRotate

		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		humanoid.AutoRotate = false

		character:SetAttribute("InCutscene", true)

		self._trove:Add(function()
			if humanoid and humanoid.Parent then
				humanoid.WalkSpeed = prevWalkSpeed
				humanoid.JumpHeight = prevJumpHeight
				humanoid.AutoRotate = prevAutoRotate
			end
			character:SetAttribute("InCutscene", nil)
		end)
	else
		character:SetAttribute("InCutscene", true)
		self._trove:Add(function()
			character:SetAttribute("InCutscene", nil)
		end)
	end
end

function CutscenePlayer._notifyCameraStart(self: CutscenePlayerImpl)
	if not isServer then
		return
	end

	local cameraPart = self._cameraPart
	if not cameraPart then
		return
	end

	local remote = getRemote()
	if not remote then
		return
	end

	task.wait()

	for _, entry in self._characters do
		if entry.isPlayer and entry.options.lockCamera == true then
			local player = Players:GetPlayerFromCharacter(entry.character)
			if player then
				remote:FireClient(player, "Start", {
					cutsceneId = self._id,
					cutsceneName = self._name,
				})
			end
		end
	end
end

function CutscenePlayer._notifyCameraEnd(self: CutscenePlayerImpl)
	if not isServer then
		return
	end

	local remote = getRemote()
	if not remote then
		return
	end

	for _, entry in self._characters do
		if entry.isPlayer and entry.options.lockCamera then
			local player = Players:GetPlayerFromCharacter(entry.character)
			if player then
				remote:FireClient(player, "End", {
					cutsceneId = self._id,
					cutsceneName = self._name,
				})
			end
		end
	end
end

function CutscenePlayer._setupMarkerCallbacks(self: CutscenePlayerImpl, character: Model, track: AnimationTrack)
	for _, markerData in self._markerCallbacks do
		if markerData.character == character then
			track:GetMarkerReachedSignal(markerData.markerName):Connect(function()
				task.spawn(markerData.callback)
			end)
		end
	end
end

function CutscenePlayer._playCharacterAnimation(self: CutscenePlayerImpl, entry: CharacterEntry): AnimationTrack?
	local animName = entry.options.animation
	if not animName then
		return nil
	end

	local animator = self:_getAnimator(entry.character)
	if not animator then
		warn(`[CutscenePlayer] No Animator found for '{entry.character.Name}'`)
		return nil
	end

	local animId = getAnimationId(animName, entry.options.moveset)
	if not animId then
		warn(`[CutscenePlayer] Animation '{animName}' not found`)
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animId
	self._trove:Add(animation)

	local track = animator:LoadAnimation(animation)
	self._characterTracks[entry.character] = track

	self:_setupMarkerCallbacks(entry.character, track)

	self._trove:Add(function()
		if track.IsPlaying then
			track:Stop()
		end
	end)

	return track
end

function CutscenePlayer._playAllAnimations(self: CutscenePlayerImpl)
	local allTracks: { AnimationTrack } = {}

	for _, entry in self._characters do
		local track = self:_playCharacterAnimation(entry)
		if track then
			table.insert(allTracks, track)
		end
	end

	if self._cameraTrack then
		table.insert(allTracks, self._cameraTrack)
	end

	task.wait(0.1) -- Small delay to ensure Animator is ready

	for _, track in allTracks do
		if track == self._cameraTrack then
			print(`[CutscenePlayer] Playing camera animation, Length: {track.Length}`)
		end
		local success = pcall(function()
			track:Play()
		end)
		if not success then
			warn(`[CutscenePlayer] Failed to play animation track`)
		end
	end

	local longestTrack: AnimationTrack? = nil
	local longestLength = 0

	for _, track in allTracks do
		if track.Length > longestLength then
			longestLength = track.Length
			longestTrack = track
		end
	end

	if longestTrack and not self._cameraTrack then
		longestTrack.Ended:Connect(function()
			self:_onEnd()
		end)
	elseif #allTracks == 0 then
		task.defer(function()
			self:_onEnd()
		end)
	end
end

function CutscenePlayer._onEnd(self: CutscenePlayerImpl)
	if not self._playing then
		return
	end

	self._playing = false

	self:_notifyCameraEnd()

	for _, callback in self._endCallbacks do
		task.spawn(callback)
	end

	self.Ended:Fire()
end

function CutscenePlayer.Play(self: CutscenePlayerImpl): Types.CutsceneHandle
	if self._destroyed or self._playing then
		return self :: any
	end

	self._playing = true

	self:_createCamera()

	for _, entry in self._characters do
		self:_freezeCharacter(entry)
		self:_positionCharacter(entry)
	end

	self:_notifyCameraStart()
	self:_playAllAnimations()

	return self :: any
end

function CutscenePlayer.AwaitEnd(self: CutscenePlayerImpl)
	if not self._playing then
		return
	end
	self.Ended:Wait()
end

function CutscenePlayer.Stop(self: CutscenePlayerImpl)
	if self._cameraTrack then
		self._cameraTrack:Stop()
	end

	for _, track in self._characterTracks do
		if track.IsPlaying then
			track:Stop()
		end
	end

	self:_onEnd()
end

function CutscenePlayer.Destroy(self: CutscenePlayerImpl)
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._trove:Destroy()
end

return CutscenePlayer
