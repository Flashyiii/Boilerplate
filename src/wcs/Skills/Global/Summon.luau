local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local MoveRegistry = require(ReplicatedStorage.Shared.Modules.Data.Moves.MoveRegistry)

local SkillBase = require(ReplicatedStorage.Shared.Wcs.Core.SkillBase)

local Summon = wcs.RegisterSkill("Summon")

function Summon:OnConstruct()
	SkillBase.OnConstruct(self)
end

function Summon:CanCancel(): boolean
	return false
end

function Summon:OnStartServer()
	local character = self.Character.Instance
	local ClientUtil = require(ReplicatedStorage.Shared.Modules.Game.ClientUtil)
	local Moveset = character:GetAttribute("Moveset")

	local Summoned = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Summoned)
	if self.Character:HasStatusEffects({ Summoned }) then
		local Stand = self.Character:GetAllActiveStatusEffectsOfType(Summoned)
		for i, StandObj in pairs(Stand) do
			self.StandObj = StandObj
			self.StandObj:End()
			ClientUtil.PlayAnimation("UnSummon", character, Moveset)
		end
	else
		ClientUtil.PlayAnimation("Summon", character, Moveset)
		self.summonedEffect = Summoned.new(self.Character)
		self.summonedEffect:Start()
	end
end

function Summon:OnEndServer()
	local character = self.Character.Instance
	local Cooldown = MoveRegistry.get(character:GetAttribute("Moveset")).Summon.Cooldown

	self:ApplyCooldown(Cooldown)
end

return Summon
