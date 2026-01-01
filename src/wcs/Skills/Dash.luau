local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local ClientUtil = require(ReplicatedStorage.Shared.Modules.Game.ClientUtil)
local KnockbackHandler = require(ReplicatedStorage.Shared.Modules.Game.KnockbackHandler)
local Stun = require(ReplicatedStorage.Shared.WCS.Conditions.States.Stun)
local EndLagStatus = require(ReplicatedStorage.Shared.WCS.Conditions.States.EndLag)

local Dash = wcs.RegisterSkill("Dash")

function Dash:OnConstruct()
	self.MutualExclusives = {
		Stun,
		EndLagStatus,
	}
end

function Dash:OnStartServer()
	local character = self.Character.Instance

	local Duration = character:GetAttribute("DashDuration") or 0.25
	local EndLagDuration = Duration + 0.35

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		ClientUtil.PlaySound("HeavyHit", character.PrimaryPart, { Volume = 4, TimePosition = 0 })
		ClientUtil.PlayAnimation("TheWorld-TimeStopPlayer", character)

		local StunEffect = Stun.new(self.Character)
		StunEffect:Start(EndLagDuration)

		local EndLagEffect = EndLagStatus.new(self.Character)
		EndLagEffect:Start(EndLagDuration)

		KnockbackHandler.Knockback(character, character, {
			Speed = 100,
			Time = Duration,
			Relative = "Attacker",
		})

		task.delay(Duration, function()
			self:End()
		end)
	end
end

function Dash:OnEndServer()
	local character = self.Character.Instance
	local Cooldown = character:GetAttribute("DashCooldown") or 2
	self:ApplyCooldown(Cooldown)
end

return Dash
