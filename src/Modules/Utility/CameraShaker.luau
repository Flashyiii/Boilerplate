-- CameraShakerModule.lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CustomShaker = require(script.Parent.CustomShaker)
local MergeTable = require(ReplicatedStorage.modules.Helper.MergeTable)

local CameraShakeInstance = require(ReplicatedStorage.Packages.camerashaker).CameraShakeInstance
local CameraShakePresets = require(ReplicatedStorage.Packages.camerashaker).Presets

local CameraShaker = {}
CameraShaker.__index = CameraShaker
--// Create a new shaker manually
function CameraShaker.new(renderPriority, applyShakeCallback)
	assert(type(renderPriority) == "number", "renderPriority must be a number")
	assert(type(applyShakeCallback) == "function", "applyShakeCallback must be a function")

	local self = setmetatable({
		_running = false,
		_priority = renderPriority,
		_callback = applyShakeCallback,
		_instances = {},
		_toRemove = {},
	}, CameraShaker)

	return self
end

--// One-line setup for local player's camera
function CameraShaker.AttachToCamera()
	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera

	local shaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
		camera.CFrame = camera.CFrame * shakeCFrame
	end)

	shaker:Start()
	return shaker
end

function CameraShaker:Start()
	if self._running then
		return
	end
	self._running = true
	RunService:BindToRenderStep("CameraShaker_" .. tostring(self), self._priority, function(dt)
		local totalPos, totalRot = Vector3.zero, Vector3.zero

		for i, inst in ipairs(self._instances) do
			local state = inst:GetState()
			if state == inst.CameraShakeState.Inactive and inst.DeleteOnInactive then
				table.insert(self._toRemove, i)
			elseif state ~= inst.CameraShakeState.Inactive then
				local delta = inst:UpdateShake(dt)
				totalPos += delta * inst.PositionInfluence
				totalRot += delta * inst.RotationInfluence
			end
		end

		for i = #self._toRemove, 1, -1 do
			table.remove(self._instances, self._toRemove[i])
		end
		table.clear(self._toRemove)

		if totalPos.Magnitude > 0 or totalRot.Magnitude > 0 then
			self._callback(
				CFrame.new(totalPos) * CFrame.Angles(math.rad(totalRot.X), math.rad(totalRot.Y), math.rad(totalRot.Z))
			)
		end
	end)
end

function CameraShaker:Stop()
	if not self._running then
		return
	end
	RunService:UnbindFromRenderStep("CameraShaker_" .. tostring(self))
	self._running = false
end

--// Shakes
function CameraShaker:ShakeOnce(magnitude, roughness, fadeIn, fadeOut, posInf, rotInf)
	local inst = CameraShakeInstance.new(magnitude, roughness, fadeIn, fadeOut)
	inst.PositionInfluence = posInf or Vector3.new(0.15, 0.15, 0.15)
	inst.RotationInfluence = rotInf or Vector3.new(1, 1, 1)
	table.insert(self._instances, inst)
	return inst
end

function CameraShaker:ShakePreset(name)
	local preset = CustomShaker[name]
	if type(preset) == "function" then
		preset = preset() -- call the function to get the instance
	end
	assert(preset, ("Preset '%s' not found"):format(name))
	return self:ShakeOnce(
		preset.Magnitude,
		preset.Roughness,
		preset.fadeInDuration,
		preset.fadeOutDuration,
		preset.PositionInfluence,
		preset.RotationInfluence
	)
end

function CameraShaker:ShakeSustain(name)
	local preset = CameraShakePresets[name]
	assert(preset, ("Preset '%s' not found"):format(name))
	local inst = self:ShakeOnce(
		preset.Magnitude,
		preset.Roughness,
		preset.fadeInDuration,
		0,
		preset.PositionInfluence,
		preset.RotationInfluence
	)
	return inst
end

function CameraShaker:StopSustained(fadeOutTime)
	for _, inst in ipairs(self._instances) do
		if inst.fadeOutDuration == 0 then
			inst:StartFadeOut(fadeOutTime or 0.5)
		end
	end
end

CameraShaker.Presets = CameraShakePresets

return CameraShaker
