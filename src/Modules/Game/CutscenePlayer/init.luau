--!strict
--[[
	CutscenePlayer - Character-Animation Based Cutscene System
	
	USAGE:
	
	local cutscene = CutscenePlayer.new("RoadRoller")
		:SetOrigin(CFrame.lookAt(attackerPos, victimPos))
		:SetCameraAnimation("RoadRollerCamera")
		:AddCharacter(attacker, { position = true, animation = "RoadRollerAttacker" })
		:AddCharacter(victim, { position = victimCFrame, animation = "RoadRollerVictim" })
		:OnMarker(attacker, "Impact", function() end)
		:OnEnd(function() end)
		:Play()
	
	cutscene:AwaitEnd()
	cutscene:Destroy()
	
	OPTIONS:
	- position: CFrame | true (freeze) | false
	- lockCamera: true (players) / false (NPCs auto)
	- animation: name from Animations.luau or rbxassetid://
	- moveset: optional moveset lookup
]]

local Types = require(script.Types)
local CutscenePlayerModule = require(script.CutscenePlayer)

export type CharacterOptions = Types.CharacterOptions
export type CharacterEntry = Types.CharacterEntry
export type CutsceneHandle = Types.CutsceneHandle

return {
	new = CutscenePlayerModule.new,
}
