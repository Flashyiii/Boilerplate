--!strict
--[[
	StandBase Move Data
	
	Base move data shared across all stand-type movesets.
	Contains common skills like Barrage and Summon.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Barrage = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Barrage)
local M1 = require(ReplicatedStorage.Shared.Wcs.Skills.Global.M1)
local Summon = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Summon)

return {

	Summon = {
		Skill = Summon,
		Cooldown = 0.3,
		OnEquip = true,
		Input = {
			KeyboardBinding = {},
		},
		InputMode = "Press",
	},

	M1 = {
		Skill = M1,

		M1234 = {

			Damage = 10,
		},

		M5 = {
			Damage = 15,
			--	Knockback = 60,
		},

		--Stand = {},
	},

	Barrage = {
		Skill = Barrage,
		Cooldown = 3,
		Shown = true,
		Input = {
			KeyboardBinding = { Enum.KeyCode.E },
		},
		InputMode = "Holdable",

		-- Timing
		MaxDuration = 5, -- Max hold time before forced end
		MinHoldTime = 1.0, -- Must hold for at least 1 second before release is honored
		StartupDuration = 0.4, -- Time in startup phase
		EndDuration = 0.35, -- Time in end phase

		HitInterval = 0.08,
		BaseDamage = 2,

		Animations = {
			Startup = "BarrageStart",
			Loop = "BarrageLoop",
			End = "BarrageEnd",
		},

		Hitbox = {
			Size = Vector3.new(4, 5, 4),
			Offset = CFrame.new(0, 0, -3),
		},

		Sounds = {
			Startup = "BarrageStart",
			Hit = "BarrageHit",
			End = "BarrageEnd",
		},
	},
}
