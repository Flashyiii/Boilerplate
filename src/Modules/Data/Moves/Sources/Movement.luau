local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dash = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Dash)
local Run = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Run)
local Summon = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Summon)
return {
	Dash = {
		Skill = Dash,
		Cooldown = 0.5,
		Shown = false,
		InputMode = "Press",
		Input = {
			KeyboardBinding = { Enum.KeyCode.Q },
		},
	},
	Run = {
		Skill = Run,
		Cooldown = 0.5,
		Shown = false,
		InputMode = "Holdable",
		Input = {
			KeyboardBinding = { Enum.KeyCode.F },
		},
	},
}
