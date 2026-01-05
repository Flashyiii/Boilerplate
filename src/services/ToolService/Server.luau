local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerScriptService = game:GetService("ServerScriptService")
local ThirdPartyUserService = game:GetService("ThirdPartyUserService")

local wcs = require(ReplicatedStorage.Packages.wcs)
local MoveRegistry = require(ReplicatedStorage.Shared.Modules.Data.Moves.MoveRegistry)
local ToolServiceClient = require(ReplicatedStorage.Shared.Services.ToolService.ToolServiceClient)

local ToolServiceServer = {}
local currentlySwitching = {}

function getCurrentWCS_Character(Character)
	local Char = wcs.Character
	return Char.GetCharacterFromInstance(Character)
end

function ToolServiceServer.ChangeMoveset(Char, newMoveset)
	local Character = Char
	local WCS_Char = getCurrentWCS_Character(Character)
	local Moveset = Character:GetAttribute("Moveset")

	if currentlySwitching[Character] == true then
		warn("Already Switching")
		repeat
			task.wait(0.1)
		until currentlySwitching[Character] == false
	end

	currentlySwitching[Character] = true

	local Data = MoveRegistry.get(Moveset)
	for i, v in pairs(Data) do
		if v.OnEquip then
			local ActiveSkills = WCS_Char:GetAllActiveSkills()

			for _, x in pairs(ActiveSkills) do
				if x.Name == i then
					repeat
						task.wait(0.1)
						print("Waiting")
					until x:GetState().IsActive == false and x:GetState().Debounce == false
				else
					repeat
						task.wait(0.1)
						print("Waiting")
					until x:GetState().IsActive == false
				end
			end

			local Skill = WCS_Char:GetSkillFromConstructor(v.Skill)
			Skill:CancelCooldown()
			Skill:Start()
			WCS_Char.DisableSkills = true
			print("SkillStarted")

			repeat
				task.wait(0.1)
				print("Waiting Again")
			until Skill:GetState().IsActive == false and Skill:GetState().Debounce == false
		end
	end
	--	Character:SetAttribute("Moveset", newMoveset)
	currentlySwitching[Character] = false
	WCS_Char.DisableSkills = false
	return true
end

export type ToolServiceServer = typeof(ToolServiceServer) & {}

return ToolServiceServer
