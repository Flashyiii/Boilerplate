local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Movement = require(script.Parent.Movement)
local Run = require(ReplicatedStorage.Shared.Wcs.Skills.Global.Run)

local result = table.clone(Movement)
result.Carry = {
	Skill = Run,
	Cooldown = 0.5,
	Shown = false,
	InputMode = "Toggle",
	Input = {
		KeyboardBinding = { Enum.KeyCode.V },
	},
} -- Avoid mixed tables.

return result
