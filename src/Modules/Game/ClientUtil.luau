local RepStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RNG = Random.new()

local _CurrentCamera = workspace.CurrentCamera

local FloorWhitelist = RaycastParams.new()
FloorWhitelist.FilterType = Enum.RaycastFilterType.Include
FloorWhitelist.FilterDescendantsInstances = { workspace.Map }

local ClientUtil = {
	AllAnimations = {},
}

export type TweenEasingTypes =
	"Sine"
	| "Circular"
	| "Back"
	| "Quad"
	| "Linear"
	| "Bounce"
	| "Elastic"
	| "Cubic"
	| "Quart"
	| "Exponential"
export type TweenDirectionTypes = "In" | "Out" | "InOut"

local clientLoops = {}

local SoundData = require(RepStorage.Shared.Modules.Assets.Sounds)
local Animations = require(ReplicatedStorage.Shared.Modules.Assets.Animations)
local AnimationData = nil
do
	local shared = RepStorage:FindFirstChild("Shared")
	if shared then
		local modules = shared:FindFirstChild("Modules")
		if modules then
			local assets = modules:FindFirstChild("Assets")
			if assets then
				local animModule = assets:FindFirstChild("Animations")
				if animModule and animModule:IsA("ModuleScript") then
					local ok, res = pcall(require, animModule)
					if ok and type(res) == "table" then
						AnimationData = res
					end
				end
			end
		end
	end
end

local _soundCache = {} -- name -> template Sound
local _activeSounds = {} -- list of playing sounds

local _animCache = {} -- name -> template Animation
local _animIdCache = {} -- animationId -> template Animation (for direct animation ID loading)
local _animatorCache = {} -- target -> animator (cache animators per model to avoid repeated searching)
local _activeAnimations = {} -- list of { track = AnimationTrack, name = string, target = Model, conn = RBXScriptConnection }

local function _getSoundId(name: string, weaponName: string?)
	if weaponName and type(weaponName) == "string" then
		local combo = weaponName .. "-" .. name
		if SoundData and SoundData[combo] then
			return SoundData[combo], combo
		end
	end
	if SoundData and SoundData[name] then
		return SoundData[name], name
	end
	warn(("Sound %q not found in SoundData."):format(name))
	return "", name
end

function ClientUtil.PlaySound(SoundName: string, PlaceToPlay: Instance | CFrame, Options: any?)
	local startTime = tick()
	Options = Options or {}
	local volume = Options.Volume or 1
	local looped = Options.Looped or false
	local pitch = Options.Pitch or 1
	local timePosition = Options.TimePosition

	local Moveset = Options.Moveset or Options.Weapon
	local soundId, resolvedName = _getSoundId(SoundName, Moveset)
	if soundId == "" then
		return
	end

	local template = _soundCache[resolvedName]
	if not template then
		template = Instance.new("Sound")
		template.Name = resolvedName
		template.SoundId = tostring(soundId)
		template.Volume = 1
		_soundCache[resolvedName] = template
	end

	local sound = template:Clone()
	sound.Volume = volume
	sound.Looped = looped
	sound.PlaybackSpeed = pitch
	if timePosition then
		sound.TimePosition = timePosition
	end

	local parent = workspace
	local createdParent = nil
	if typeof(PlaceToPlay) == "CFrame" then
		local part = Instance.new("Part")
		part.Name = "__soundPart"
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Size = Vector3.new(0.5, 0.5, 0.5)
		part.CFrame = PlaceToPlay
		part.Parent = workspace
		parent = part
		createdParent = part
	elseif typeof(PlaceToPlay) == "Instance" then
		parent = PlaceToPlay
	end

	sound.Parent = parent
	table.insert(_activeSounds, sound)

	local conn
	conn = sound.Ended:Connect(function()
		task.delay(2, function()
			for i = #_activeSounds, 1, -1 do
				if _activeSounds[i] == sound then
					table.remove(_activeSounds, i)
				end
			end
			sound:Destroy()
			if conn then
				conn:Disconnect()
				conn = nil
			end
			if createdParent and createdParent.Parent then
				createdParent:Destroy()
			end
		end)
	end)

	sound:Play()

	if not looped and createdParent then
		Debris:AddItem(createdParent, 10)
	end

	return sound
end

function ClientUtil.StopSound(SoundOrName: any, Time: number?) -- TODO: Apply to all sounds with that name
	if typeof(SoundOrName) == "string" then
		local name = SoundOrName
		for i = #_activeSounds, 1, -1 do
			local s = _activeSounds[i]
			if s then
				local match = (s.Name == name)
					or (s.Name:sub(-#name) == name and s.Name:sub(-(#name + 1), -(#name + 1)) == "-")
				if match then
					if Time and Time > 0 then
						task.spawn(function()
							local startVol = s.Volume
							local steps = math.max(1, math.floor(Time / 0.05))
							for j = 1, steps do
								if not s.Parent then
									break
								end
								s.Volume = startVol * (1 - j / steps)
								task.wait(0.05)
							end
							if s.Parent then
								s:Stop()
								s:Destroy()
							end
						end)
					else
						s:Stop()
						s:Destroy()
					end
					table.remove(_activeSounds, i)
				end
			end
		end
	elseif typeof(SoundOrName) == "Instance" and SoundOrName:IsA("Sound") then
		local s = SoundOrName
		if Time and Time > 0 then
			task.spawn(function()
				local startVol = s.Volume
				local steps = math.max(1, math.floor(Time / 0.05))
				for j = 1, steps do
					if not s.Parent then
						break
					end
					s.Volume = startVol * (1 - j / steps)
					task.wait(0.05)
				end
				if s.Parent then
					s:Stop()
					s:Destroy()
				end
			end)
		else
			s:Stop()
			s:Destroy()
		end
		for i = #_activeSounds, 1, -1 do
			if _activeSounds[i] == s then
				table.remove(_activeSounds, i)
			end
		end
	end
end

--* Animation Functions

ClientUtil.Animations = Animations
local AnimationCache = {}
setmetatable(AnimationCache, { __mode = "k" }) -- Weak keys so characters can be garbage collected

local MAX_CACHED_TRACKS = 50
local function GetAnimator(character: Model): Animator?
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Animator") then
			return descendant
		end
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			return animator
		end

		local newAnimator = Instance.new("Animator")
		newAnimator.Parent = humanoid
		return newAnimator
	end

	return nil
end

-- Helper function to clean up old/stopped animations for a character
local function CleanupOldTracks(character: Model)
	local cache = AnimationCache[character]
	if not cache then
		return
	end

	local stoppedTracks = {}

	for animName, track in cache do
		if not track.IsPlaying then
			table.insert(stoppedTracks, animName)
		end
	end

	-- Remove stopped tracks from cache
	for _, animName in stoppedTracks do
		local track = cache[animName]
		track:Destroy()
		cache[animName] = nil
	end
end

-- Get or create AnimationTrack for a character
local function GetOrLoadTrack(animationName: string, character: Model): AnimationTrack?
	-- Initialize cache for this character if needed
	if not AnimationCache[character] then
		AnimationCache[character] = {}
	end

	local cache = AnimationCache[character]

	-- Return cached track if it exists
	if cache[animationName] then
		return cache[animationName]
	end

	-- Check if we need to cleanup before loading new animation
	local trackCount = 0
	for _ in cache do
		trackCount = trackCount + 1
	end

	if trackCount >= MAX_CACHED_TRACKS then
		CleanupOldTracks(character)
	end

	-- Get animation ID
	local animationId = ClientUtil.Animations[animationName]
	if not animationId then
		warn("Animation not found: " .. animationName)
		return nil
	end

	-- Find animator
	local animator = GetAnimator(character)
	if not animator then
		local charName = typeof(character) == "Instance" and character.Name or tostring(character)
		warn("No Animator or Humanoid found in character: " .. charName)
		return nil
	end

	-- Create and load animation
	local animationInstance = Instance.new("Animation")
	animationInstance.AnimationId = animationId

	local track: AnimationTrack = nil
	if animator:IsA("Animator") then
		track = animator:LoadAnimation(animationInstance)
	end

	animationInstance:Destroy() -- Clean up the temporary instance

	if track then
		cache[animationName] = track

		track.Destroying:Connect(function()
			if cache[animationName] == track then
				cache[animationName] = nil
			end
		end)
	end

	return track
end

local function GetAnimationName(baseAnimName: string, moveset: string?): string
	if moveset then
		local movesetAnimName = moveset .. "-" .. baseAnimName
		if ClientUtil.Animations[movesetAnimName] then
			return movesetAnimName
		end
	end

	return baseAnimName
end

function ClientUtil.PlayAnimation(animName: string, character: Model, moveset: string?, speed: number?)
	local fullAnimName = GetAnimationName(animName, moveset)
	local track = GetOrLoadTrack(fullAnimName, character)

	if track then
		if not track.IsPlaying then
			if speed then
				track:Play(0, 1, speed)
			else
				track:Play()
			end
		end
		return track
	end

	return nil
end

function ClientUtil.StopAnimation(animName: string, character: Model, fadeTime: number?)
	local cache = AnimationCache[character]
	if not cache then
		return
	end

	local fade = fadeTime or 0.1

	for cachedAnimName, track in cache do
		if cachedAnimName == animName or cachedAnimName:match("%-" .. animName .. "$") then
			if track.IsPlaying then
				track:Stop(fade)
			end
		end
	end
end

function ClientUtil.StopAllAnimations(character: Model, fadeTime: number?)
	local cache = AnimationCache[character]
	if not cache then
		return
	end

	local fade = fadeTime or 0.1

	for _, track in cache do
		if track.IsPlaying then
			track:Stop(fade)
		end
	end
end

function ClientUtil.LoadAnimation(animName: string | Animation, character: Model, moveset: string?): AnimationTrack?
	if typeof(animName) == "Instance" and animName:IsA("Animation") then
		local animator = GetAnimator(character)
		if not animator then
			local charName = typeof(character) == "Instance" and character.Name or tostring(character)
			warn("No Animator or Humanoid found in character: " .. charName)
			return nil
		end

		local track: AnimationTrack = nil
		if animator:IsA("Animator") then
			track = animator:LoadAnimation(animName)
		end

		return track
	end

	local fullAnimName = GetAnimationName(animName, moveset)
	local track = GetOrLoadTrack(fullAnimName, character)

	return track
end

function ClientUtil.GetAnimationTrack(animName: string, character: Model, moveset: string?): AnimationTrack?
	local fullAnimName = GetAnimationName(animName, moveset)
	local cache = AnimationCache[character]

	if cache then
		return cache[fullAnimName]
	end

	return nil
end

function ClientUtil.IsAnimationPlaying(animName: string, character: Model, moveset: string?): boolean
	local fullAnimName = GetAnimationName(animName, moveset)
	local cache = AnimationCache[character]

	if cache and cache[fullAnimName] then
		return cache[fullAnimName].IsPlaying
	end

	return false
end

function ClientUtil.CleanupCharacterAnimations(character: Model)
	local cache = AnimationCache[character]
	if not cache then
		return
	end

	for _, track in cache do
		track:Destroy()
	end

	AnimationCache[character] = nil
end

function ClientUtil.Weld(BasePart: BasePart, BasePart2: BasePart, C0: CFrame?, C1: CFrame?)
	local NewWeld = Instance.new("Weld")
	NewWeld.Parent = BasePart2
	NewWeld.Part0 = BasePart
	NewWeld.Part1 = BasePart2
	NewWeld.C0 = C0 or CFrame.new()
	NewWeld.C1 = C1 or CFrame.new()

	return NewWeld
end

function ClientUtil.StringToInstance(pathto: string)
	if typeof(pathto) ~= "string" then
		return
	end
	local i, expectedresult = game, true

	local path = string.split(pathto, ".")
	for o = 1, #path do
		local e = path[o]
		i = i:FindFirstChild(e)
		if i == nil then
			expectedresult = false
			break
		end
	end

	local value = nil
	if expectedresult then
		value = i
	end
	return value
end

function ClientUtil.Lerp(Base, FinalValue, Alpha: number)
	return Base + (FinalValue - Base) * Alpha
end

function ClientUtil.CheckIfHurt(Target: Model)
	if not Target then
		return
	end
	local TargetHumanoid = Target:FindFirstChild("Humanoid") :: Humanoid
	if TargetHumanoid.Health <= 0 or Target:GetAttribute("TimeStoped") then
		return true
	else
		return false
	end
end

function ClientUtil.Tween(
	Instance: any,
	Time: number,
	Style: TweenEasingTypes,
	Direction: TweenDirectionTypes,
	Properties: {},
	RepeatAmount: number?,
	ReverseTween: boolean?,
	DelayTime: number?
)
	local TweenConnect: RBXScriptConnection = nil
	if not Instance then
		return
	end
	local NewTween: Tween = game:GetService("TweenService"):Create(
		Instance,
		TweenInfo.new(
			Time,
			Enum.EasingStyle[Style] :: Enum.EasingStyle,
			Enum.EasingDirection[Direction] :: Enum.EasingDirection,
			if RepeatAmount then RepeatAmount else 0,
			if ReverseTween then true else false,
			if DelayTime then DelayTime else 0
		),
		Properties
	)
	TweenConnect = NewTween.Completed:Connect(function()
		NewTween:Destroy()
		TweenConnect:Disconnect()
	end)
	NewTween:Play()
	return NewTween
end

function ClientUtil.RNG(Minimum: number, Maxiumum: number)
	return RNG:NextNumber(Minimum, Maxiumum)
end

return ClientUtil
