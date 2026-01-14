local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local hitbox = require(ReplicatedStorage.Packages.hitbox)
local trove = require(ReplicatedStorage.Packages.trove)
local wcs = require(ReplicatedStorage.Packages.wcs)
local MoveRegistry = require(ReplicatedStorage.Shared.Modules.Data.Moves.MoveRegistry)
local AnimationPlayer = require(ReplicatedStorage.Shared.Modules.Game.AnimationPlayer)
local M1 = wcs.RegisterSkill("M1")
local ClientUtil = require(ReplicatedStorage.Shared.Modules.Game.ClientUtil)
local KnockbackHandler = require(ReplicatedStorage.Shared.Modules.Utility.KnockbackHandler)
local Ragdoll = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Ragdoll)

local EndLag = require(ReplicatedStorage.Shared.Wcs.Conditions.States.EndLag)
local Hit = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Hit)
local Stun = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Stun)
local Summoned = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Summoned)

local SkillBase = require(ReplicatedStorage.Shared.Wcs.Core.SkillBase)

local function getHitData(Data, Combo)
	local searchString = tostring(Combo)
	for key, data in pairs(Data) do
		if type(data) == "table" and string.find(key, searchString) then
			return data, key
		end
	end
	warn("No data found for number: " .. searchString)
	return nil
end

local function destroyChain(chain)
	if chain then
		chain:Destroy()
	end
end

function M1:OnConstruct()
	SkillBase.OnConstruct(self)

	self.CancelOn = {
		"Hit",
		"Stun",
		"Ragdoll",
	}

	self.Combo = 1
	self.LastAttackTime = 0
	self._Trove = trove.new()
	self._completed = false
end

function M1:OnStartServer()
	self._completed = false

	local character = self.Character.Instance
	local moveset = character:GetAttribute("Moveset")

	self.char = character

	self.Animator = AnimationPlayer.new(
		CollectionService:HasTag(character, "Summoned") and character:WaitForChild(moveset) or character
	)

	local moveData = MoveRegistry.get(moveset).M1 or {}

	self.isSummoned = CollectionService:HasTag(character, "Summoned")
	self.Data = moveData
	self.Moveset = moveset

	local comboTick = self.Data.ComboTick or 1.5
	local timeSinceLastAttack = tick() - self.LastAttackTime
	local shouldResetCombo = timeSinceLastAttack > comboTick

	if shouldResetCombo then
		self.Combo = 1
		destroyChain(self.chain)
		self.chain = nil
	end

	self.LastAttackTime = tick()

	self._currentCombo = self.Combo
	self:Animation(self.isSummoned)

	self.Combo = self.Combo + 1

	local swings = self.Data.Swings or 5
	if self.Combo >= swings + 1 then
		destroyChain(self.chain)
		self.chain = nil
		self.Combo = 1
		self:ApplyCooldown(self.Data.EndCooldown or 2)
	end

	self._completed = true
	self:End()
end

function M1:Animation(isSummoned)
	local prefix = isSummoned and "S" or "M"

	local HitData = getHitData(self.Data, self._currentCombo)
	ClientUtil.PlaySound(HitData.SwingSound, self.Character.Instance)

	if self.chain then
		self.chain:Continue()
	else
		local Set = self.Moveset

		destroyChain(self.chain)

		local anims = { prefix .. "1-1", prefix .. "1-2", prefix .. "1-3", prefix .. "1-4", prefix .. "1-5" }
		local newChain = self.Animator
			:Chain(anims, Set)
			:PauseOnLastFrame()
			:SetAutoStopDelay(0.40)
			:OnMarker("Hit", function()
				self:Hitbox(getHitData(self.Data, self._currentCombo), self._currentCombo)
			end)
			:OnAutoStopDelay(function()
				destroyChain(self.chain)
				self.chain = nil
			end)
			:SetFadeTime(0.3)
			:SetPriority(Enum.AnimationPriority.Movement)
			:OnChainEnd(function()
				destroyChain(self.chain)
				self.chain = nil
			end)
			:Play()
			:SetIndex(self._currentCombo)

		self.chain = newChain
	end

	if self.chain then
		self.chain:AwaitAnimation()
	end
end

function M1:Hitbox(HitData, combo)
	local box = hitbox.new({
		SizeOrPart = HitData.Part,
		InitialPosition = self.char.HumanoidRootPart.CFrame * HitData.CFrameOffset,
		SpatialOption = "InBox",
		DebounceTime = 1,
		Debris = 0.2,
		Debug = _G.Debug,
		Blacklist = { self.char },
	})

	box.HitSomeone:Connect(function(hitChars)
		for _, char in pairs(hitChars) do
			if not char:IsDescendantOf(self.char) then
				self:HitSomeone(HitData, char, combo)
			end
		end
	end)

	box:Start()
end

function M1:HitSomeone(HitData, Target, combo)
	local DamageServiceServer = require(ServerScriptService.Services.DamageService.DamageServiceServer)
	local swings = self.Data.Swings or 5

	local function HitReaction(status)
		if self.Data[status] then
			self.Data[status](self.char, Target)
		end
		if status == "Hit" then
			ClientUtil.PlaySound(HitData.HitSound, self.Character.Instance)

			if HitData.Effect then
				local effect = HitData.Effect(self.char, Target).new(self.Character)
				effect:Start(game.Players:GetPlayers())
			end

			if combo == swings then
				local knockback = HitData.Knockback or 50
				KnockbackHandler.Knockback(self.char, Target, {
					Speed = knockback,
					Time = 0.25,
					Relative = "Attacker",
				})
				Ragdoll.new(wcs.Character.GetCharacterFromInstance(Target)):Start(1.5)
			else
				local TargetAnimator = AnimationPlayer.new(Target)
				TargetAnimator:StopLast({ "H1-1", "H1-2", "H1-3", "H1-4", "H1-5" })

				TargetAnimator:Play("H1-" .. combo, self.Moveset)
					:SetPriority(Enum.AnimationPriority.Movement)
					:PauseOnLastFrame()
					:SetAutoStopDelay(0.40)
					:SetFadeTime(0.1)
					:Play()
			end
			return true
		end
		return false
	end

	DamageServiceServer:Attack(self.char, Target, {
		BaseDamage = HitData.Damage or 5,
		BlockDamage = 1,
		Stun = 0.4,
		CancleMoves = true,
		Callback = HitReaction,
	})
end

function M1:OnEndServer()
	self._Trove:Destroy()
	self._Trove = trove.new()

	if not self._completed then
		destroyChain(self.chain)
		self.chain = nil
	end
end

return M1
