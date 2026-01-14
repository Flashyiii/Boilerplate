local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Wcs = require(ReplicatedStorage.Packages.wcs)
local MoveRegistry = require(ReplicatedStorage.Shared.Modules.Data.Moves.MoveRegistry)
local InputServiceClient = require(ReplicatedStorage.Shared.Services.InputService.InputServiceClient)
local CharacterClass = Wcs.Character

local InputServiceServer = {}
InputServiceServer.__index = InputServiceServer

local cache = {}
local function getOrCreateWCSMoveset(movesetName)
	if not movesetName or movesetName == "None" or movesetName == "" then
		return nil
	end

	if cache[movesetName] then
		return cache[movesetName]
	end
	local registry = MoveRegistry.get(movesetName)
	if not registry then
		return nil
	end

	local skills = {}
	for _, moveData in pairs(registry) do
		if moveData.Skill then
			table.insert(skills, moveData.Skill)
		end
	end

	if #skills == 0 then
		return nil
	end

	print("Generating moveset:", movesetName)
	local moveset = Wcs.CreateMoveset(movesetName, skills)

	cache[movesetName] = moveset
	return moveset
end

function InputServiceServer:bindCharacter(character)
	local function applyMoveset()
		local movesetName = character.Instance:GetAttribute("Moveset")

		character:ClearMoveset()

		local globalMoveset = getOrCreateWCSMoveset("Global")
		if globalMoveset then
			character:ApplySkillsFromMoveset(globalMoveset)

			local globalRegistry = MoveRegistry.get("Global")
			if globalRegistry then
				for moveName, moveData in pairs(globalRegistry) do
					if moveData.Skill and moveName ~= "Summon" then
						local skill = character:GetSkillFromConstructor(moveData.Skill)
						if skill then
							skill:ApplyCooldown(1)
						end
					end
				end
			end
		end

		if not movesetName or movesetName == "None" or movesetName == "" then
			return
		end

		local moveset = getOrCreateWCSMoveset(movesetName)
		if moveset then
			character:ApplySkillsFromMoveset(moveset)

			local registry = MoveRegistry.get(movesetName)
			if registry then
				for moveName, moveData in pairs(registry) do
					if moveData.Skill and moveName ~= "Summon" then
						local skill = character:GetSkillFromConstructor(moveData.Skill)
						if skill then
							skill:ApplyCooldown(1)
						end
					end
				end
			end
		end
	end

	applyMoveset()

	character.Instance:GetAttributeChangedSignal("Moveset"):Connect(applyMoveset)

	character.Instance:WaitForChild("Humanoid").Died:Once(function()
		character:Destroy()
	end)
end

function InputServiceServer.init(self: InputServiceServer) end

export type InputServiceServer = typeof(InputServiceServer) & {}

return InputServiceServer
