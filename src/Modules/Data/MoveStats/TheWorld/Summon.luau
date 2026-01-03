local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Summon = require(ReplicatedStorage.Shared.Modules.Data.MoveStats.Global.Summon)
return {
	MoveName = script.Name,
	Cooldown = Summon.Cooldown,
	AuraColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 180, 72)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 180, 72)),
	}),
	Unsummon = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 180, 72)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 180, 72)),
	}),
}
