--[[
	VFXHelper Module
	A comprehensive VFX system for Roblox Studio that handles particles, parts, and attachments
	
	Usage:
		local VFXHelper = require(path.to.VFXHelper)
		VFXHelper:PlayVFX(character, vfxFolder, duration)
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local maid = require(ReplicatedStorage.Packages.maid)

local VFXHelper = {}
VFXHelper.__index = VFXHelper

local Maid = maid

-- Cache for better performance
local particleCache = {}
local function getParticleClass(instance)
	local className = instance.ClassName
	if not particleCache[className] then
		particleCache[className] = className:match("Emitter$")
			or className == "Fire"
			or className == "Smoke"
			or className == "Sparkles"
			or className == "PointLight"
			or className == "SpotLight"
			or className == "Beam"
			or className == "Trail"
	end
	return particleCache[className]
end

local function getBaseParts(model)
	local parts = {}
	for _, descendant in ipairs(model:GetChildren()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function applyVFXToPart(targetPart, vfxInstance, cleanupList, instanceMaid)
	local clone = vfxInstance:Clone()
	clone.Parent = targetPart

	if instanceMaid then
		instanceMaid:GiveTask(clone)
	else
		table.insert(cleanupList, clone)
	end

	return clone
end

local function calculateParticleLifetime(particle)
	if particle:IsA("ParticleEmitter") then
		-- Get the maximum possible lifetime from the ParticleEmitter
		local lifetime = particle.Lifetime
		if typeof(lifetime) == "NumberRange" then
			return lifetime.Max
		else
			return lifetime
		end
	end
	return 0
end

local function processParticleEffect(particle, emitCount, emitDelay, cleanupList, instanceMaid, skipAutoCleanup)
	task.spawn(function()
		if emitDelay and emitDelay > 0 then
			task.wait(emitDelay)
		end

		if emitCount and emitCount > 0 then
			if particle:IsA("ParticleEmitter") then
				particle:Emit(emitCount)

				-- Only auto-cleanup if not using a maid system and not skipped
				if not instanceMaid and not skipAutoCleanup then
					-- Calculate cleanup time: particle lifetime + 1 second
					local particleLifetime = calculateParticleLifetime(particle)
					local cleanupDelay = particleLifetime + 1

					-- Schedule automatic cleanup after emission
					task.spawn(function()
						task.wait(cleanupDelay)
						if particle and particle.Parent then
							particle:Destroy()
							-- Remove from cleanup list if it exists there
							if cleanupList then
								for i, item in ipairs(cleanupList) do
									if item == particle then
										table.remove(cleanupList, i)
										break
									end
								end
							end
						end
					end)
				end
			elseif particle.Enabled ~= nil then
				particle.Enabled = true
				task.wait(0.1)
				particle.Enabled = false
			end
		else
			if particle.Enabled ~= nil then
				particle.Enabled = true
			end
		end
	end)
end

local function processAttachment(sourceAttachment, targetPart, cleanupList, instanceMaid)
	local newAttachment = sourceAttachment:Clone()
	newAttachment.Parent = targetPart

	if instanceMaid then
		instanceMaid:GiveTask(newAttachment)
	else
		table.insert(cleanupList, newAttachment)
	end

	for _, child in ipairs(newAttachment:GetChildren()) do
		if getParticleClass(child) then
			local emitCount = child:GetAttribute("EmitCount")
			local emitDelay = child:GetAttribute("EmitDelay")
			-- Skip auto cleanup for attachment children when using maid
			processParticleEffect(child, emitCount, emitDelay, cleanupList, instanceMaid, instanceMaid ~= nil)
		end
	end

	return newAttachment
end

function VFXHelper:PlayVFX(model, vfxFolder, duration)
	if not model or not model:IsA("Model") then
		warn("VFXHelper: Invalid model provided")
		return nil
	end

	if not vfxFolder or not vfxFolder:IsA("Folder") then
		warn("VFXHelper: Invalid VFX folder provided")
		return nil
	end

	-- Each PlayVFX call gets its own isolated cleanup system
	local cleanupList = {}
	local instanceMaid = Maid and Maid.new() or nil

	local modelParts = getBaseParts(model)
	local modelPartsByName = {}
	for _, part in ipairs(modelParts) do
		modelPartsByName[part.Name] = part
	end

	task.spawn(function()
		for _, vfxElement in ipairs(vfxFolder:GetChildren()) do
			if getParticleClass(vfxElement) then
				for _, targetPart in ipairs(modelParts) do
					task.spawn(function()
						local clone = applyVFXToPart(targetPart, vfxElement, cleanupList, instanceMaid)
						local emitCount = vfxElement:GetAttribute("EmitCount")
						local emitDelay = vfxElement:GetAttribute("EmitDelay")
						-- Skip auto cleanup when using maid system
						processParticleEffect(
							clone,
							emitCount,
							emitDelay,
							cleanupList,
							instanceMaid,
							instanceMaid ~= nil
						)
					end)
				end
			elseif vfxElement:IsA("BasePart") then
				local targetPart = modelPartsByName[vfxElement.Name]
				if targetPart then
					task.spawn(function()
						for _, child in ipairs(vfxElement:GetChildren()) do
							if child:IsA("Attachment") then
								processAttachment(child, targetPart, cleanupList, instanceMaid)
							elseif getParticleClass(child) then
								local clone = applyVFXToPart(targetPart, child, cleanupList, instanceMaid)
								local emitCount = child:GetAttribute("EmitCount")
								local emitDelay = child:GetAttribute("EmitDelay")
								-- Skip auto cleanup when using maid system
								processParticleEffect(
									clone,
									emitCount,
									emitDelay,
									cleanupList,
									instanceMaid,
									instanceMaid ~= nil
								)
							end
						end
					end)
				end
			elseif vfxElement:IsA("Attachment") then
				local targetPart = modelPartsByName["HumanoidRootPart"] or modelPartsByName["RootPart"] or modelParts[1]
				if targetPart then
					task.spawn(function()
						processAttachment(vfxElement, targetPart, cleanupList, instanceMaid)
					end)
				end
			end
		end
	end)

	-- Duration-based cleanup with isolated maid
	if duration and duration > 0 then
		task.spawn(function()
			task.wait(duration)
			if instanceMaid then
				instanceMaid:Cleanup()
			else
				for _, vfx in ipairs(cleanupList) do
					if vfx and vfx.Parent then
						Debris:AddItem(vfx, 0)
					end
				end
			end
		end)
	end

	return {
		Cleanup = function()
			if instanceMaid then
				instanceMaid:Cleanup()
			else
				for _, vfx in ipairs(cleanupList) do
					if vfx and vfx.Parent then
						vfx:Destroy()
					end
				end
			end
		end,
		Maid = instanceMaid,
		CleanupList = cleanupList,
	}
end

function VFXHelper:PlayVFXBatch(models, vfxFolder, duration)
	local handles = {}
	for _, model in ipairs(models) do
		task.spawn(function()
			local handle = self:PlayVFX(model, vfxFolder, duration)
			if handle then
				table.insert(handles, handle)
			end
		end)
	end

	return {
		CleanupAll = function()
			for _, handle in ipairs(handles) do
				if handle and handle.Cleanup then
					handle.Cleanup()
				end
			end
		end,
		Handles = handles,
	}
end

function VFXHelper:PreloadVFX(vfxFolder)
	if not vfxFolder or not vfxFolder:IsA("Folder") then
		return false
	end

	for _, vfx in ipairs(vfxFolder:GetDescendants()) do
		if vfx:IsA("ParticleEmitter") then
			local _ = vfx.Texture
		end
	end

	return true
end

function VFXHelper:CreateManagedPlayer()
	local player = {
		activeVFX = {},
		maid = Maid and Maid.new() or nil,
	}

	function player:Play(model, vfxFolder, duration)
		local handle = VFXHelper:PlayVFX(model, vfxFolder, duration)
		if handle then
			table.insert(self.activeVFX, handle)
			return handle
		end
	end

	function player:CleanupAll()
		for _, handle in ipairs(self.activeVFX) do
			if handle and handle.Cleanup then
				handle.Cleanup()
			end
		end
		self.activeVFX = {}

		if self.maid then
			self.maid:Cleanup()
			self.maid = Maid and Maid.new() or nil
		end
	end

	return player
end

return VFXHelper
