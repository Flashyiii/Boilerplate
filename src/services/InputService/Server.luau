-- ServerScriptService/Combat/Input/InputServiceServer.lua
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
	if cache[movesetName] then
		return cache[movesetName]
	end
	local registry = MoveRegistry.get(movesetName)
	if not registry then
		return
	end

	local skills = {}
	for _, moveData in pairs(registry) do
		table.insert(skills, moveData.Skill)
	end

	print("Generating moveset:", movesetName)
	local moveset = Wcs.CreateMoveset(movesetName, skills)

	cache[movesetName] = moveset
	return moveset
end

function InputServiceServer:bindCharacter(character)
	local function applyMoveset()
		local movesetName = character.Instance:GetAttribute("Moveset")
		if not movesetName then
			return
		end

		character:ClearMoveset()

		local moveset = getOrCreateWCSMoveset(movesetName)
		if moveset then
			character:ApplyMoveset(moveset)
		end
	end

	applyMoveset()

	character.Instance:GetAttributeChangedSignal("Moveset"):Connect(applyMoveset)

	character.Instance:WaitForChild("Humanoid").Died:Once(function()
		character:Destroy()
	end)
end

function InputServiceServer.init(self: InputServiceServer)
	print("InputServiceServer initialized")
end

export type InputServiceServer = typeof(InputServiceServer) & {}

return InputServiceServer
