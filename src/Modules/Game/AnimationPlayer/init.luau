--!strict
--[[
	AnimationPlayer - Production-Grade Luau Animation System
	
	A unified animation management system providing fluent API design,
	animation chaining, frame-accurate callbacks, and memory safety.
	
	USAGE:
	
	local AnimationPlayer = require(path.to.AnimationPlayer)
	
	-- Create player for character
	local player = AnimationPlayer.new(character)
	
	-- Basic play with callbacks
	player:Play("M1-1")
		:OnMarker("Hit", function(time, value)
			print("Hit at", time)
		end)
		:OnEnd(function()
			print("Done")
		end)
		:Play()
	
	-- Chain animations
	player:Chain({"M1-1", "M1-2", "M1-3"})
		:AutoContinue()
		:OnMarker("Hit", function(animName, index, time)
			print("Hit on", animName, "at", time)
		end)
		:OnChainEnd(function()
			print("Chain complete")
		end)
		:Play()
	
	-- Cleanup
	player:Destroy()
]]

local Types = require(script.Types)
local AnimationPlayerModule = require(script.AnimationPlayer)
local AnimationHandleModule = require(script.AnimationHandle)
local ChainHandleModule = require(script.ChainHandle)

export type MarkerData = Types.MarkerData
export type KeyframeData = Types.KeyframeData
export type AnimationInfo = Types.AnimationInfo
export type ChainMode = Types.ChainMode
export type MarkerCallback = Types.MarkerCallback
export type ChainMarkerCallback = Types.ChainMarkerCallback
export type FrameCallback = Types.FrameCallback
export type EndCallback = Types.EndCallback
export type IndexCallback = Types.IndexCallback
export type AnimationEndCallback = Types.AnimationEndCallback
export type AnimationHandle = Types.AnimationHandle
export type ChainHandle = Types.ChainHandle
export type AnimationPlayer = Types.AnimationPlayer

return {
	new = AnimationPlayerModule.new,
	ClearCache = AnimationPlayerModule.ClearCache,
	GetKeyframeCache = AnimationPlayerModule.GetKeyframeCache,
	GetAnimationNames = AnimationPlayerModule.GetAnimationNames,

	AnimationHandle = AnimationHandleModule,
	ChainHandle = ChainHandleModule,
}
