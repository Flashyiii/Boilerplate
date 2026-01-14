local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoadRoller = require(ReplicatedStorage.Shared.Wcs.Skills.TheWorld.RoadRoller)
return {
	Summon = {
		AuraColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 180, 72)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 180, 72)),
		}),
		Unsummon = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 180, 72)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 180, 72)),
		}),
	},
	RoadRoller = {
		Skill = RoadRoller,
		Cooldown = 3,
		Shown = true,
		CanCancel = false,
		MaxDuration = 15,
		Input = {
			KeyboardBinding = { Enum.KeyCode.X },
		},
		InputMode = "Press",
	},

}
