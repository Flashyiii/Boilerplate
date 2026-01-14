local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local conch = require(ReplicatedStorage.Packages.conch)
local wcs = require(ReplicatedStorage.Packages.wcs)
local Dash = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Dash)

local Testing = {}

conch.register("Knockback", {
	description = "Apply Knockback to a Player",
	permissions = { "Knockback" },
	arguments = function()
		return conch.args.player("target", "Target"),
			conch.args.player("attacker", "Attacker"),
			conch.args.number("speed", "Knockback Speed"),
			conch.args.number("time", "Knockback Time")
	end,

	callback = function(target, attacker, speed, time)
		local KnockbackHandler = require(ReplicatedStorage.Shared.Modules.Utility.KnockbackHandler)

		local targetCharacter = target.Character
		local attackerCharacter = attacker.Character

		if targetCharacter and attackerCharacter then
			KnockbackHandler.Knockback(attackerCharacter, targetCharacter, {
				Speed = speed,
				Time = time,
				Relative = "Attacker",
			})
		end
	end,
})

conch.register("Ragdoll", {
	description = "Ragdoll a Player",
	permissions = { "Ragdoll" },
	arguments = function()
		return conch.args.player("target", "Target"), conch.args.number("time", "Ragdoll Time")
	end,

	callback = function(target, time)
		local TargetCharacter = target.Character
		if TargetCharacter then
			local Target = wcs.Character.GetCharacterFromInstance(TargetCharacter)
			local RagdollStatus = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Ragdoll)
			local Ragdoll = RagdollStatus.new(Target)
			Ragdoll:Start(time)
		end
	end,
})

conch.register("Run", {
	description = "Make a Player Run",
	permissions = { "Run" },
	arguments = function()
		return conch.args.player("target", "Target"), conch.args.number("time", "Run Time")
	end,

	callback = function(target, time)
		local TargetCharacter = target.Character
		if TargetCharacter then
			local Target = wcs.Character.GetCharacterFromInstance(TargetCharacter)
			local RunningStatus = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Running)
			local Running = RunningStatus.new(Target)
			Running:Start(time)
		end
	end,
})

conch.register("Dash", {
	description = "Make a Player Dash",
	permissions = { "Dash" },
	arguments = function()
		return conch.args.player("target", "Target")
	end,

	callback = function(target)
		local TargetCharacter = target.Character
		if TargetCharacter then
			local Target = wcs.Character.GetCharacterFromInstance(TargetCharacter)
			Target:GetSkillFromConstructor(Dash):Start()
		end
	end,
})

conch.register("Summon", {
	description = "Make a Player Summon",
	permissions = { "Summon" },
	arguments = function()
		return conch.args.player("target", "Target")
	end,

	callback = function(target)
		local Summon = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Summon)

		local TargetCharacter = target.Character
		if TargetCharacter then
			local Target = wcs.Character.GetCharacterFromInstance(TargetCharacter)
			Target:GetSkillFromConstructor(Summon):Start()
		end
	end,
})

conch.register("Stun", {
	description = "Stun a Player",
	permissions = { "Stun" },
	arguments = function()
		return conch.args.player("target", "Target"),
			conch.args.number("time", "Stun Time"),
			conch.args.number("delay", "Delay Before Stun")
	end,

	callback = function(target, time, delay)
		local TargetCharacter = target.Character
		if TargetCharacter then
			local Stun = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Stun)
			task.delay(delay, function()
				local Target = wcs.Character.GetCharacterFromInstance(TargetCharacter)
				Stun.new(Target):Start(time)
			end)
		end
	end,
})

return Testing
