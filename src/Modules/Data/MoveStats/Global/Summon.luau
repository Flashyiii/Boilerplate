return {
	MoveName = script.Name,
	Actioned = {
		Active = {
			Block = true,
		},
		Disabled = true,
		Summoned = false,
	},
	Cooldown = 1.5,

	AuraColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	}),
	Unsummon = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	}),
}
