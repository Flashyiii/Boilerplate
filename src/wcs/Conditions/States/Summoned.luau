local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local Summoned = wcs.RegisterStatusEffect("Summoned")

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local maid = require(ReplicatedStorage.Packages.maid)
local wcs = require(ReplicatedStorage.Packages.wcs)

local ClientUtil = require(ReplicatedStorage.Shared.Modules.Game.ClientUtil)
local CameraMover = require(ReplicatedStorage.Shared.Modules.Helper.CameraMover)
local Stun = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Stun)
local EndLagStatus = require(ReplicatedStorage.Shared.Wcs.Conditions.States.EndLag)
local Highlight = require(ReplicatedStorage.Shared.Visuals.Highlight)

local Settings = {
	SpawnScaleDuration = 0.2,
	SpawnTransparencyDuration = 0.2,
	DespawnDuration = 0.25,
	CameraSpawn = 0.2,
	CameraDespawn = 0.2,
	CameraHeight = 1,
}

local function AdjustTransparency(Model: Model, Trans: number, dur: number?, maidInstance: any?)
	local duration = dur or Settings.DespawnDuration
	for _, v in pairs(Model:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
			if v.Name == "HumanoidRootPart" then
			else
				local tween = TweenService:Create(
					v,
					TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Transparency = Trans }
				)
				tween:Play()
				if maidInstance then
					maidInstance:GiveTask(tween)
				end
			end
		end
	end
end

local function AdjustSize(Model: Model, Size: number, dur: number?)
	local duration = dur or 0.1
	local elapsed = 0
	local currentScale = Model:GetScale()
	local targetScale = Size

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		local easedAlpha = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local newScale = currentScale + (targetScale - currentScale) * easedAlpha
		Model:ScaleTo(newScale)

		if elapsed >= duration then
			connection:Disconnect()
		end
	end)

	return connection
end

function Summoned:OnConstruct()
	self.MutualExclusives = {
		Stun,
		EndLagStatus,
	}
	self._maid = maid.new()
end

function Summoned:_newStand()
	local Stand = self.Character.Instance:GetAttribute("Moveset")
	local Character = self.Character.Instance

	local success, err = pcall(function()
		self.StandObject = ReplicatedStorage.Assets.StandModels[Stand]:Clone()
	end)
	if err then
		self:End()
		warn("No stand model found for moveset:", Stand)
		return
	end

	self.StandObject.Parent = Character
	self.StandObject:AddTag("Stand")

	self._maid:GiveTask(self.StandObject)
	AdjustTransparency(self.StandObject, 1, 0, self._maid)

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	local StandRootPart = self.StandObject.PrimaryPart
		or self.StandObject:FindFirstChild("HumanoidRootPart")
		or self.StandObject:FindFirstChildWhichIsA("BasePart")

	if HumanoidRootPart and StandRootPart then
		self.StandObject:PivotTo(HumanoidRootPart.CFrame * CFrame.Angles(math.pi, 0, 0)) -- For some reason the stand is upside down by default
		self.StandObject:ScaleTo(0.05)

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = StandRootPart
		weld.Part1 = HumanoidRootPart
		weld.Parent = HumanoidRootPart
	end

	AdjustTransparency(self.StandObject, 0, Settings.SpawnTransparencyDuration, self._maid)

	local sizeTweenConn = AdjustSize(self.StandObject, 1, Settings.SpawnScaleDuration)
	self._maid:GiveTask(sizeTweenConn)

	ClientUtil.PlaySound("Summon", Character.PrimaryPart, { Volume = 1, TimePosition = 0, Moveset = Stand })

	local SummonFX = require(ReplicatedStorage.Shared.Visuals.SummonFX)
	local Effect = SummonFX.new(self.Character.Instance)
	Effect:Start(game.Players:GetPlayers())

	local highlightEffect = Highlight.new(self.Character.Instance, { Color = Color3.fromRGB(245, 180, 72) }) -- Player highlight
	highlightEffect:Start(game.Players:GetPlayers())
end

function Summoned:OnStartServer()
	local Character = self.Character.Instance

	if CollectionService:HasTag(Character, "Summoned") then
		print("Character", Character.Name, "is already summoned.")
	else
		self:_newStand()
		Character:AddTag("Summoned")
	end
end

function Summoned:OnEndServer()
	local Character = self.Character.Instance

	local Moveset = Character:GetAttribute("Moveset")
	ClientUtil.PlaySound("DeSummon", Character.PrimaryPart, { Volume = 1, TimePosition = 0, Moveset = Moveset })

	local highlightEffect = Highlight.new(self.StandObject, { Color = Color3.fromRGB(245, 180, 72) })
	highlightEffect:Start(game.Players:GetPlayers())

	if self.StandObject then
		AdjustTransparency(self.StandObject, 1, Settings.DespawnDuration, self._maid)
	end
	task.delay(Settings.DespawnDuration, function()
		if self.StandObject then
			self.StandObject:Destroy()
			self._maid:Cleanup()
		end
	end)

	Character:RemoveTag("Summoned")
end

function Summoned:OnStartClient()
	local Character = self.Character.Instance
	CameraMover(Character, CFrame.new(0, Settings.CameraHeight, 0), Settings.CameraSpawn)
end

function Summoned:OnEndClient()
	local Character = self.Character.Instance
	CameraMover(Character, CFrame.new(0, 0, 0), Settings.CameraDespawn)
end

return Summoned
