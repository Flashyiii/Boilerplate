local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EndLag = require(ReplicatedStorage.Shared.Wcs.Conditions.States.EndLag)
local M1 = require(ReplicatedStorage.Shared.Wcs.Skills.Global.M1)

return {
	M1 = {
		ComboTick = 1.5,
		Skill = M1,
		Cooldown = 0.1,
		Shown = false,
		Input = {
			KeyboardBinding = { Enum.KeyCode.MouseLeftButton },
		},

		EndCooldown = 2,
		EndLag = 1,

		M1234 = {
			CFrameOffset = CFrame.new(0, 0, -2),
			Part = Vector3.new(3, 4, 5),
			SwingSound = "Whoosh",
			HitSound = "Hit",
		},

		M5 = {
			CFrameOffset = CFrame.new(0, 0, -2),
			Part = Vector3.new(3, 4, 5),
			SwingSound = "Whoosh",
			HitSound = "HeavyHit",
		},

		Swings = 5,
		Stand = {
			Swings = 5,
			EndCooldown = 2,

			M1234 = {
				CFrameOffset = CFrame.new(0, 0, -3),
				Part = Vector3.new(3, 4, 5),
				SwingSound = "Whoosh",
				HitSound = "Hit",
			},

			M5 = {
				CFrameOffset = CFrame.new(0, 0, -3),
				Part = Vector3.new(3, 4, 5),
				SwingSound = "Whoosh",
				HitSound = "HeavyHit",
			},
		},
	},
}
