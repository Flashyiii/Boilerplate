local ReplicatedStorage = game:GetService("ReplicatedStorage")

local M1 = require(ReplicatedStorage.Shared.Wcs.Skills.Global.M1)

return {
	M1 = {
		Skill = M1,
		Cooldown = 0.1,
		Shown = false,
		Input = {
			KeyboardBinding = { Enum.KeyCode.MouseLeftButton },
		},

		Swings = 5,
		ComboTick = 1.5,
		EndCooldown = 2,
		EndLag = 1,

		M1234 = {
			CFrameOffset = CFrame.new(0, 0, -2),
			Part = Vector3.new(3, 4, 5),
			SwingSound = "Whoosh",
			HitSound = "Hit",
			Damage = 5,
		},

		M5 = {
			CFrameOffset = CFrame.new(0, 0, -2),
			Part = Vector3.new(3, 4, 5),
			SwingSound = "Whoosh",
			HitSound = "HeavyHit",
			Damage = 8,
			Knockback = 30,
		},

		--Stand = {},
	},
}
