local ReplicatedStorage = game:GetService("ReplicatedStorage")

local M1 = require(ReplicatedStorage.Shared.Wcs.Skills.Global.M1)
local Summon = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Summon)
return {
	Summon = {
		Skill = Summon,
		Cooldown = 0.35,
		OnEquip = true,
		Input = {
			KeyboardBinding = {},
		},
		Shown = false,
	},
	M1 = {
		Skill = M1,
		Cooldown = 0,
		Shown = false,
		Input = {
			KeyboardBinding = { Enum.KeyCode.MouseLeftButton },
		},
	},
}
