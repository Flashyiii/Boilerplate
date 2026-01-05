-- ReplicatedStorage/Combat/Input/InputServiceClient.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Wcs = require(ReplicatedStorage.Packages.wcs)
local MoveRegistry = require(ReplicatedStorage.Shared.Modules.Data.Moves.MoveRegistry)

local Input = require(ReplicatedStorage.Shared.Modules.Utility.Input)
local CharacterClass = Wcs.Character

local InputServiceClient = {}
InputServiceClient.__index = InputServiceClient

local function getWcsCharacter()
	local model = Players.LocalPlayer.Character
	if not model then
		return
	end
	return CharacterClass.GetCharacterFromInstance(model)
end

function InputServiceClient:init()
	self._inputs = {}
	self:_bindCharacter()
end

function InputServiceClient:_bindCharacter()
	local player = Players.LocalPlayer

	player.CharacterAdded:Connect(function(char)
		self:_onCharacter(char)
	end)

	if player.Character then
		self:_onCharacter(player.Character)
	end
end

function InputServiceClient:_onCharacter(character)
	local function onMovesetChanged()
		local newMoveset = character:GetAttribute("Moveset")

		self:_clearInputs()

		if newMoveset then
			self:_buildMoveset(newMoveset)
		end

		self._activeMoveset = newMoveset
	end

	onMovesetChanged()
	character:GetAttributeChangedSignal("Moveset"):Connect(onMovesetChanged)
end

function InputServiceClient:_buildMoveset(movesetName)
	local registry = MoveRegistry.get(movesetName)
	if not registry then
		return
	end

	for moveName, data in registry do
		local action = Input.New(movesetName, moveName, data.Input, data.Cooldown)

		action:Connect(function()
			local character = getWcsCharacter()
			if not character then
				return
			end

			character:GetSkillFromConstructor(data.Skill):Start()
		end)

		table.insert(self._inputs, action)
	end
end

function InputServiceClient:_clearInputs()
	for _, input in self._inputs do
		input:SetState(false)
	end
	table.clear(self._inputs)
end

export type InputServiceClient = typeof(InputServiceClient)

return InputServiceClient
