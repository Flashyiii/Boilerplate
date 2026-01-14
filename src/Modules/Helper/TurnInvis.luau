local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local trove = require(ReplicatedStorage.Packages.trove)

local cache = {}
local characterTroves = {}
local invisibleState = {}

local function isStandDescendant(instance: Instance): boolean
	local current = instance
	while current and current ~= game do
		if CollectionService:HasTag(current, "Stand") then
			return true
		end
		current = current.Parent
	end
	return false
end

local function processInvisibility(
	character: Model,
	child: Instance,
	_isStand: boolean,
	shouldBeInvisible: boolean,
	tween: number?
)
	if not cache[character] then
		cache[character] = {}
	end
	local childCacheAny: any = cache[character][child]
	if not childCacheAny then
		childCacheAny = {}
		cache[character][child] = childCacheAny
	end
	local childCache = childCacheAny :: { Transparency: number?, Enabled: boolean? }

	if child:IsA("BasePart") or child:IsA("Decal") or child:IsA("Texture") then
		if childCache.Transparency == nil then
			childCache.Transparency = child.Transparency
		end

		if shouldBeInvisible then
			if tween then
				local tweenInstance = TweenService:Create(
					child :: BasePart,
					TweenInfo.new(tween, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Transparency = 1 }
				)
				tweenInstance:Play()
				characterTroves[character]:Add(tweenInstance)
			else
				(child :: BasePart).Transparency = 1
			end
		else
			local cachedTransparency = childCache.Transparency
			if cachedTransparency ~= nil and cachedTransparency < 1 then
				if tween then
					local tweenInstance = TweenService:Create(
						child :: BasePart,
						TweenInfo.new(tween, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
						{ Transparency = cachedTransparency }
					)
					tweenInstance:Play()
					characterTroves[character]:Add(tweenInstance)
				else
					(child :: BasePart).Transparency = cachedTransparency
				end
			end
		end
	end

	if child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Light") or child:IsA("Highlight") then
		local childWithEnabled = child :: any
		if childCache.Enabled == nil then
			childCache.Enabled = childWithEnabled.Enabled
		end

		if shouldBeInvisible then
			childWithEnabled.Enabled = false
		else
			local cachedEnabled = childCache.Enabled
			if cachedEnabled ~= nil then
				childWithEnabled.Enabled = cachedEnabled
			end
		end
	end
end

return function(character: Model, char: boolean?, stand: boolean?, tween: number?)
	if not character then
		return
	end

	if not characterTroves[character] then
		characterTroves[character] = trove.new()
		characterTroves[character]:AttachToInstance(character)
	end

	if not invisibleState[character] then
		invisibleState[character] = { char = false, stand = false }
	end

	local currentState = invisibleState[character]
	local shouldMakeCharInvisible = char == true
	local shouldMakeStandInvisible = stand == true

	for _, child in character:GetDescendants() do
		local isStand = isStandDescendant(child)

		if isStand then
			if shouldMakeStandInvisible ~= currentState.stand then
				processInvisibility(character, child, true, shouldMakeStandInvisible, tween)
			end
		else
			if shouldMakeCharInvisible ~= currentState.char then
				processInvisibility(character, child, false, shouldMakeCharInvisible, tween)
			end
		end
	end

	currentState.char = shouldMakeCharInvisible
	currentState.stand = shouldMakeStandInvisible

	if shouldMakeCharInvisible or shouldMakeStandInvisible then
		CollectionService:AddTag(character, "Invisible")
	else
		CollectionService:RemoveTag(character, "Invisible")
		if cache[character] then
			local hasCachedParts = false
			for _ in pairs(cache[character]) do
				hasCachedParts = true
				break
			end
			if not hasCachedParts then
				cache[character] = nil
				if characterTroves[character] then
					characterTroves[character]:Destroy()
					characterTroves[character] = nil
				end
				invisibleState[character] = nil
			end
		end
	end
end
