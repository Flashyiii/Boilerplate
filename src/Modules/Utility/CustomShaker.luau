local ReplicatedStorage = game:GetService("ReplicatedStorage")
local camerashaker = require(ReplicatedStorage.Packages.camerashaker)
local CameraShakePresets = camerashaker.Presets
local CameraShakeInstance = camerashaker.CameraShakeInstance

local CustomPresets = {}

-- Your extra presets:
function CustomPresets.BossSmash()
	local c = CameraShakeInstance.new(7, 8, 0.15, 0.6)
	c.PositionInfluence = Vector3.new(0.3, 0.4, 0.3)
	c.RotationInfluence = Vector3.new(1.5, 1.2, 1)
	return c
end

function CustomPresets.ShortExplosion()
	local c = CameraShakeInstance.new(4.5, 1, 0.1, 0.1)
	c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
	c.RotationInfluence = Vector3.new(1, 1, 1)
	return c
end

function CustomPresets.SmallRumble()
	local c = CameraShakeInstance.new(1, 2, 0.05, 0.3)
	c.PositionInfluence = Vector3.new(0.1, 0.1, 0.1)
	c.RotationInfluence = Vector3.new(0.3, 0.3, 0.3)
	return c
end

-- Merge originals with your customs
local AllPresets = {}
for k, v in pairs(CameraShakePresets) do
	AllPresets[k] = v
end
for k, v in pairs(CustomPresets) do
	AllPresets[k] = v
end

return AllPresets
