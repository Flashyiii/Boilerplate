local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dash = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Dash)
local Summon = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Summon)
return {
	Dash = {
		Skill = Dash,
		Cooldown = 0,
		Shown = false,
		Input = {
			KeyboardBinding = { Enum.KeyCode.Q },
		},
	},
}
