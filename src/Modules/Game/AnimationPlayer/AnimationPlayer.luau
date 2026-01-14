--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local Trove = require(ReplicatedStorage.Packages.trove)

local Types = require(script.Parent.Types)
local AnimationHandle = require(script.Parent.AnimationHandle)
local ChainHandle = require(script.Parent.ChainHandle)

local Animations = require(script.Parent.Parent.Parent.Assets.Animations)

type AnimationInfo = Types.AnimationInfo
type MarkerData = Types.MarkerData
type KeyframeData = Types.KeyframeData

local MAX_CACHED_TRACKS = 50
local DEFAULT_FRAME_RATE = 30

local KeyframeCache: { [string]: AnimationInfo } = {}
local PreloadedAssets: { [string]: boolean } = {}
local PlayerCache: { [Model]: Types.AnimationPlayer } = {}

local AnimationPlayer = {}
AnimationPlayer.__index = AnimationPlayer

export type AnimationPlayerImpl = {
	_character: Model,
	_humanoid: Humanoid?,
	_animator: Animator?,
	_animationController: AnimationController?,
	_trove: typeof(Trove.new()),
	_trackCache: { [string]: AnimationTrack },
	_activeHandle: Types.AnimationHandle?,
	_activeChain: Types.ChainHandle?,
	_destroyed: boolean,
	_timeStopped: boolean,
	_pausedTracks: { AnimationTrack },
}

function AnimationPlayer.new(character: Model): Types.AnimationPlayer?
	local cachedPlayer = PlayerCache[character]
	if cachedPlayer and not cachedPlayer._destroyed then
		return cachedPlayer :: any
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator: Animator?
	local animationController: AnimationController?

	if humanoid then
		animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
	else
		animationController = character:FindFirstChildOfClass("AnimationController")
		if not animationController then
			animationController = Instance.new("AnimationController")
			animationController.Parent = character
		end
	end

	if not animator and not animationController then
		warn("[AnimationPlayer] No Humanoid or AnimationController found in character")
		return nil
	end

	local self = setmetatable({}, AnimationPlayer) :: AnimationPlayerImpl

	self._character = character
	self._humanoid = humanoid
	self._animator = animator
	self._animationController = animationController
	self._trove = Trove.new()
	self._trackCache = {}
	self._activeHandle = nil
	self._activeChain = nil
	self._destroyed = false
	self._timeStopped = false
	self._pausedTracks = {}

	self._trove:AttachToInstance(character)
	self:_SetupTimeStopListener()

	PlayerCache[character] = self :: any

	local ancestryConnection = character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(game) then
			PlayerCache[character] = nil
		end
	end)
	self._trove:Add(ancestryConnection)

	return self :: any
end

function AnimationPlayer.Play(self: AnimationPlayerImpl, animName: string, moveset: string?): Types.AnimationHandle
	if self._destroyed then
		error("[AnimationPlayer] Cannot play on destroyed player")
	end

	local track = self:GetTrack(animName, moveset)
	if not track then
		error(`[AnimationPlayer] Failed to get track for animation: {animName}`)
	end

	local info = self:GetAnimationInfo(animName, moveset)
	local handle = AnimationHandle.new(self :: any, animName, track, info)

	self._trove:Add(handle)
	self._activeHandle = handle

	if self._activeChain then
		self._activeChain = nil
	end

	return handle
end

function AnimationPlayer.Chain(self: AnimationPlayerImpl, animations: { string }, moveset: string?): Types.ChainHandle
	if self._destroyed then
		error("[AnimationPlayer] Cannot chain on destroyed player")
	end

	for _, animName in animations do
		self:_EnsureTrackLoaded(animName, moveset)
	end

	local chain = ChainHandle.new(self :: any, animations, moveset)
	self._trove:Add(chain)
	self._activeChain = chain

	if self._activeHandle then
		self._activeHandle:Destroy()
		self._activeHandle = nil
	end

	return chain
end

function AnimationPlayer.Pause(self: AnimationPlayerImpl): Types.AnimationPlayer
	if self._destroyed then
		return self :: any
	end

	if self._activeHandle then
		self._activeHandle:Pause()
	end

	if self._activeChain then
		self._activeChain:Pause()
	end

	return self :: any
end

function AnimationPlayer.Resume(self: AnimationPlayerImpl): Types.AnimationPlayer
	if self._destroyed then
		return self :: any
	end

	if self._activeHandle then
		self._activeHandle:Resume()
	end

	if self._activeChain then
		self._activeChain:Resume()
	end

	return self :: any
end

function AnimationPlayer.Stop(self: AnimationPlayerImpl, fadeTime: number?): Types.AnimationPlayer
	if self._destroyed then
		return self :: any
	end

	if self._activeHandle then
		self._activeHandle:Stop(fadeTime)
		self._activeHandle:Destroy()
		self._activeHandle = nil
	end

	if self._activeChain then
		self._activeChain:Stop(fadeTime)
		self._activeChain:Destroy()
		self._activeChain = nil
	end

	return self :: any
end

function AnimationPlayer.StopAll(self: AnimationPlayerImpl, fadeTime: number?): Types.AnimationPlayer
	if self._destroyed then
		return self :: any
	end

	self:Stop(fadeTime)

	for _, track in self._trackCache do
		if track.IsPlaying then
			track:Stop(fadeTime or 0.1)
		end
	end

	return self :: any
end

function AnimationPlayer.StopLast(self: AnimationPlayerImpl, animNames: { string }, fadeTime: number?): Types.AnimationPlayer
	if self._destroyed then
		return self :: any
	end

	local nameSet: { [string]: boolean } = {}
	for _, name in animNames do
		nameSet[name] = true
	end

	local function matchesName(name: string?): boolean
		if not name then
			return false
		end
		if nameSet[name] then
			return true
		end
		for patternName in nameSet do
			if name:find(patternName, 1, true) or name:match("^[^:]+:" .. patternName .. "$") then
				return true
			end
		end
		return false
	end

	if self._activeHandle and self._activeHandle:IsPlaying() then
		local animName = self._activeHandle:GetAnimationName()
		if matchesName(animName) then
			self._activeHandle:Stop(fadeTime)
			self._activeHandle:Destroy()
			self._activeHandle = nil
		end
	end

	if self._activeChain and self._activeChain:IsPlaying() then
		local currentAnim = self._activeChain:GetCurrentAnimation()
		if matchesName(currentAnim) then
			self._activeChain:Stop(fadeTime)
			self._activeChain:Destroy()
			self._activeChain = nil
		else
			for _, animName in self._activeChain._animations do
				if matchesName(animName) then
					self._activeChain:Stop(fadeTime)
					self._activeChain:Destroy()
					self._activeChain = nil
					break
				end
			end
		end
	end

	for cacheKey, track in self._trackCache do
		if track.IsPlaying and matchesName(cacheKey) then
			track:Stop(fadeTime or 0.1)
		end
	end

	return self :: any
end

function AnimationPlayer.IsPlaying(self: AnimationPlayerImpl, animName: string?): boolean
	if self._destroyed then
		return false
	end

	if animName then
		local track = self._trackCache[animName]
		return track ~= nil and track.IsPlaying
	end

	if self._activeHandle and self._activeHandle:IsPlaying() then
		return true
	end

	if self._activeChain and self._activeChain:IsPlaying() then
		return true
	end

	return false
end

function AnimationPlayer.GetActiveHandle(self: AnimationPlayerImpl): Types.AnimationHandle?
	return self._activeHandle
end

function AnimationPlayer.GetActiveChain(self: AnimationPlayerImpl): Types.ChainHandle?
	return self._activeChain
end

function AnimationPlayer.GetTrack(self: AnimationPlayerImpl, animName: string, moveset: string?): AnimationTrack?
	if self._destroyed then
		return nil
	end

	local controller = self._animator or self._animationController
	if not controller then
		return nil
	end

	local cacheKey = self:_GetCacheKey(animName, moveset)

	if self._trackCache[cacheKey] then
		return self._trackCache[cacheKey]
	end

	local animId = self:_GetAnimationId(animName, moveset)
	if not animId then
		warn(`[AnimationPlayer] Animation not found: {animName}`)
		return nil
	end

	self:_CleanupTrackCache()

	local animation = Instance.new("Animation")
	animation.AnimationId = animId

	local track = controller:LoadAnimation(animation)
	animation:Destroy()

	self._trackCache[cacheKey] = track

	task.spawn(function()
		self:_ExtractAndCacheKeyframes(animId, animName, moveset)
	end)

	return track
end

function AnimationPlayer.GetAnimationInfo(self: AnimationPlayerImpl, animName: string, moveset: string?): AnimationInfo?
	local animId = self:_GetAnimationId(animName, moveset)
	if not animId then
		return nil
	end

	if KeyframeCache[animId] then
		return KeyframeCache[animId]
	end

	self:_ExtractAndCacheKeyframes(animId, animName, moveset)
	return KeyframeCache[animId]
end

function AnimationPlayer.GetLength(self: AnimationPlayerImpl, animName: string, moveset: string?): number
	local track = self:GetTrack(animName, moveset)
	if track then
		return track.Length
	end
	return 0
end

function AnimationPlayer.GetMarkerTime(
	self: AnimationPlayerImpl,
	animName: string,
	markerName: string,
	moveset: string?
): number?
	local info = self:GetAnimationInfo(animName, moveset)
	if info and info.Markers[markerName] then
		return info.Markers[markerName]
	end
	return nil
end

function AnimationPlayer.Preload(
	self: AnimationPlayerImpl,
	animations: { string },
	moveset: string?
): Types.AnimationPlayer
	if self._destroyed then
		return self :: any
	end

	for _, animName in animations do
		task.spawn(function()
			self:_EnsureTrackLoaded(animName, moveset)
		end)
	end

	return self :: any
end

function AnimationPlayer.Destroy(self: AnimationPlayerImpl): ()
	if self._destroyed then
		return
	end

	self._destroyed = true

	if self._activeHandle then
		self._activeHandle:Destroy()
		self._activeHandle = nil
	end

	if self._activeChain then
		self._activeChain:Destroy()
		self._activeChain = nil
	end

	for _, track in self._trackCache do
		track:Stop(0)
		track:Destroy()
	end

	table.clear(self._trackCache)
	
	if PlayerCache[self._character] == self then
		PlayerCache[self._character] = nil
	end
	
	self._trove:Destroy()
end

function AnimationPlayer._GetAnimationId(self: AnimationPlayerImpl, animName: string, moveset: string?): string?
	if moveset then
		local movesetAnims = Animations[moveset]
		if movesetAnims and movesetAnims[animName] then
			return movesetAnims[animName]
		end
	end

	return Animations[animName]
end

function AnimationPlayer._GetCacheKey(self: AnimationPlayerImpl, animName: string, moveset: string?): string
	if moveset then
		return `{moveset}:{animName}`
	end
	return animName
end

function AnimationPlayer._EnsureTrackLoaded(self: AnimationPlayerImpl, animName: string, moveset: string?): ()
	local animId = self:_GetAnimationId(animName, moveset)
	if not animId or PreloadedAssets[animId] then
		return
	end

	PreloadedAssets[animId] = true

	local animation = Instance.new("Animation")
	animation.AnimationId = animId

	pcall(function()
		ContentProvider:PreloadAsync({ animation })
	end)

	animation:Destroy()

	self:GetTrack(animName, moveset)
end

function AnimationPlayer._ExtractAndCacheKeyframes(
	self: AnimationPlayerImpl,
	animId: string,
	animName: string,
	moveset: string?
): ()
	if KeyframeCache[animId] then
		return
	end

	local success, keyframeSequence = pcall(function()
		return KeyframeSequenceProvider:GetKeyframeSequenceAsync(animId)
	end)

	if not success or not keyframeSequence then
		KeyframeCache[animId] = {
			Id = animId,
			Length = 0,
			Keyframes = {},
			Markers = {},
			FrameRate = DEFAULT_FRAME_RATE,
			TotalFrames = 0,
		}
		return
	end

	local keyframes: { KeyframeData } = {}
	local markers: { [string]: number } = {}
	local maxTime = 0

	for _, keyframe in keyframeSequence:GetKeyframes() do
		local time = keyframe.Time
		maxTime = math.max(maxTime, time)

		local keyframeMarkers: { MarkerData } = {}

		for _, marker in keyframe:GetMarkers() do
			local markerData: MarkerData = {
				Name = marker.Name,
				Time = time,
				Value = marker.Value,
			}
			table.insert(keyframeMarkers, markerData)
			markers[marker.Name] = time
		end

		if #keyframeMarkers > 0 then
			table.insert(keyframes, {
				Time = time,
				Markers = keyframeMarkers,
			})
		end
	end

	keyframeSequence:Destroy()

	local track = self:GetTrack(animName, moveset)
	local length = if track then track.Length else maxTime
	local totalFrames = math.ceil(length * DEFAULT_FRAME_RATE)

	KeyframeCache[animId] = {
		Id = animId,
		Length = length,
		Keyframes = keyframes,
		Markers = markers,
		FrameRate = DEFAULT_FRAME_RATE,
		TotalFrames = totalFrames,
	}
end

function AnimationPlayer._CleanupTrackCache(self: AnimationPlayerImpl): ()
	local count = 0
	for _ in self._trackCache do
		count += 1
	end

	if count < MAX_CACHED_TRACKS then
		return
	end

	local toRemove: { string } = {}

	for key, track in self._trackCache do
		if not track.IsPlaying then
			table.insert(toRemove, key)
			if #toRemove >= 10 then
				break
			end
		end
	end

	for _, key in toRemove do
		local track = self._trackCache[key]
		if track then
			track:Destroy()
			self._trackCache[key] = nil
		end
	end
end

function AnimationPlayer._SetupTimeStopListener(self: AnimationPlayerImpl): ()
	local character = self._character

	local function handleTimeStop(stopped: boolean)
		if self._destroyed then
			return
		end

		self._timeStopped = stopped

		if stopped then
			self._pausedTracks = {}
			for _, track in self._trackCache do
				if track.IsPlaying then
					table.insert(self._pausedTracks, track)
					track:AdjustSpeed(0)
				end
			end
		else
			for _, track in self._pausedTracks do
				track:AdjustSpeed(1)
			end
			table.clear(self._pausedTracks)
		end
	end

	local currentValue = character:GetAttribute("TimeStopped")
	if currentValue == true then
		handleTimeStop(true)
	end

	local conn = character:GetAttributeChangedSignal("TimeStopped"):Connect(function()
		local value = character:GetAttribute("TimeStopped")
		handleTimeStop(value == true)
	end)

	self._trove:Add(conn)
end

function AnimationPlayer.ClearCache(): ()
	table.clear(KeyframeCache)
	table.clear(PreloadedAssets)
end

function AnimationPlayer.GetKeyframeCache(): { [string]: AnimationInfo }
	return KeyframeCache
end

function AnimationPlayer.GetAnimationNames(moveset: string?): { string }
	local names: { string } = {}

	if moveset then
		local movesetAnims = Animations[moveset]
		if movesetAnims and type(movesetAnims) == "table" then
			for name in movesetAnims do
				table.insert(names, name)
			end
		end
	else
		for name, value in Animations do
			if type(value) == "string" then
				table.insert(names, name)
			end
		end
	end

	return names
end

return AnimationPlayer
