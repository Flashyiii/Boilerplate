local RepStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RNG = Random.new()

local _CurrentCamera = workspace.CurrentCamera

local FloorWhitelist = RaycastParams.new()
FloorWhitelist.FilterType = Enum.RaycastFilterType.Include
FloorWhitelist.FilterDescendantsInstances = { workspace.Map }

local ClientUtil = {}

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

local function _getSoundId(name: string)
	if SoundData and SoundData[name] then
		return SoundData[name]
	end
	warn(("Sound %q not found in SoundData."):format(name))
	return ""
end

function ClientUtil.PlaySound(SoundName: string, PlaceToPlay: Instance | CFrame, Options: any?)
	local startTime = tick()
	Options = Options or {}
	local volume = Options.Volume or 1
	local looped = Options.Looped or false
	local pitch = Options.Pitch or 1
	local timePosition = Options.TimePosition

	local soundId = _getSoundId(SoundName)
	if soundId == "" then
		return
	end

	local template = _soundCache[SoundName]
	if not template then
		template = Instance.new("Sound")
		template.Name = SoundName
		template.SoundId = tostring(soundId)
		template.Volume = 1
		_soundCache[SoundName] = template
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

	warn("[ClientUtil] Played Sound:", SoundName, "in", tick() - startTime, "seconds")
	sound:Play()

	if not looped and createdParent then
		Debris:AddItem(createdParent, 10)
	end

	return sound
end

function ClientUtil.StopSound(SoundOrName: any, Time: number?)
	if typeof(SoundOrName) == "string" then
		local name = SoundOrName
		for i = #_activeSounds, 1, -1 do
			local s = _activeSounds[i]
			if s and s.Name == name then
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

-- Animation helpers (name-based)
local function _getAnimationId(name: string)
	if AnimationData and AnimationData[name] then
		return AnimationData[name]
	end
	warn(("Animation %q not found in AnimationData."):format(name))
	return ""
end

function ClientUtil.LoadAnimationByName(Name: string, Target: Model): AnimationTrack?
	local animId = _getAnimationId(Name)
	if animId == "" then
		return nil
	end
	local template = _animCache[Name]
	if not template then
		template = Instance.new("Animation")
		template.Name = Name
		template.AnimationId = tostring(animId)
		_animCache[Name] = template
	end
	return ClientUtil.LoadAnimation(template, Target)
end

function ClientUtil.PlayAnimation(Name: string, Target: Model, Speed: number?)
	local track = ClientUtil.LoadAnimationByName(Name, Target)
	if not track then
		return nil
	end

	if Speed then
		track:Play(nil, nil, Speed)
	else
		track:Play()
	end
	return track
end

function ClientUtil.AddClientLoop(LoopFunc: any, LoopID: any)
	if type(LoopFunc) ~= "function" then
		return
	end

	local function LoopCallback(DeltaTime: number)
		local FuntionResult = LoopFunc(DeltaTime)
		if FuntionResult == true then
			clientLoops[LoopID] = nil
			return
		end
	end

	clientLoops[LoopID] = LoopCallback
end

function ClientUtil.LoadAndPlayAnimation(Animation: Animation, Target: Model, Speed: number?)
	if Animation.AnimationId == "" then
		return nil
	end
	local TargetAnimation = ClientUtil.LoadAnimation(Animation, Target)
	if Speed then
		TargetAnimation:Play(nil, nil, Speed)
	else
		TargetAnimation:Play()
	end
	return TargetAnimation
end

function ClientUtil.LoadAnimation(Animation: Animation, Target: Model): AnimationTrack?
	if Animation.AnimationId == "" then
		return nil
	end
	local NewAnim = Instance.new("Animation")
	NewAnim.AnimationId = Animation.AnimationId

	local LoadedAnimation: AnimationTrack = nil
	for _, chil in Target:GetDescendants() do
		if chil:IsA("Animator") then
			print("Animator found, loading animation:", Animation.Name, "on", chil)
			LoadedAnimation = chil:LoadAnimation(NewAnim)
			break
		end
	end

	return LoadedAnimation
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
