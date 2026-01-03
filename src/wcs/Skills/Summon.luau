local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)

local Stun = require(ReplicatedStorage.Shared.WCS.Conditions.States.Stun)
local EndLagStatus = require(ReplicatedStorage.Shared.WCS.Conditions.States.EndLag)

local Summon = wcs.RegisterSkill("Summon")

function Summon:OnConstruct()
	self.MutualExclusives = {
		Stun,
		EndLagStatus,
	}
end

function Summon:OnStartServer()
	local character = self.Character.Instance

	local Summoned = require(ReplicatedStorage.Shared.WCS.Conditions.States.Summoned)
	if self.Character:HasStatusEffects({ Summoned }) then
		local Stand = self.Character:GetAllActiveStatusEffectsOfType(Summoned)
		for i, StandObj in pairs(Stand) do
			self.StandObj = StandObj
			self.StandObj:End()
		end
	else
		self.summonedEffect = Summoned.new(self.Character)
		self.summonedEffect:Start()
	end
end

function Summon:OnEndServer()
	local character = self.Character.Instance
	local SummonData =
		require(ReplicatedStorage.Shared.Modules.Data.MoveStats[character:GetAttribute("Moveset")].Summon)
	local Cooldown = SummonData.Cooldown or 2

	self:ApplyCooldown(Cooldown)
end

return Summon
