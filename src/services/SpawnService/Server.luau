local SpawnServiceServer = {}
SpawnServiceServer.__index = SpawnServiceServer

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InputServiceServer = require(ServerScriptService.Services.InputService.InputServiceServer)
local RagdollServiceServer = require(ServerScriptService.Services.RagdollService.RagdollServiceServer)
local StatServiceServer = require(ServerScriptService.Services.StatService.StatServiceServer)
local wcs = require(ReplicatedStorage.Packages.wcs)
local CustomShaker = require(ReplicatedStorage.Shared.Modules.Utility.CustomShaker)
local Character = wcs.Character

function SetAttributes(char: Model): ()
	char:SetAttribute("Loaded", true)
	char:SetAttribute("TimeStoped", false)
	char:SetAttribute("Moveset", "TheWorld")
	char:SetAttribute("CanJump", true)

	char:SetAttribute("Stand", "TheWorld") -- TODO: Implement proper stand selection
	task.delay(5, function()
		--char:SetAttribute("Stand", "TheWorld")
		--char:SetAttribute("Moveset", "TheWorld")
	end)
end

function SpawnServiceServer.setupCharacter(self: SpawnServiceServer, char: Model)
	local CharacterModel = char

	local Player: Player? = Players:GetPlayerFromCharacter(CharacterModel)
	if Player then
		Player:SetAttribute("Loaded", true)
		CollectionService:AddTag(char, "Player")
	else
		CollectionService:AddTag(char, "NPC")
	end

	char.Parent = workspace.World.Live

	local WCS_Character = Character.new(CharacterModel)
	StatServiceServer:initCharacter(CharacterModel)
	SetAttributes(char)

	WCS_Character:SetDefaultProps({
		WalkSpeed = char:GetAttribute("WalkSpeed"),
	})

	char:GetAttributeChangedSignal("WalkSpeed"):Connect(function()
		WCS_Character:SetDefaultProps({
			WalkSpeed = char:GetAttribute("WalkSpeed"),
		})
	end)

	local Humanoid = CharacterModel:WaitForChild("Humanoid")
	self:stateListener(char)

	Humanoid.Died:Once(function()
		WCS_Character:Destroy()
	end)
end

function SpawnServiceServer.stateListener(self: SpawnServiceServer, char: Model)
	local WCS_Character = Character.GetCharacterFromInstance(char)

	WCS_Character.StatusEffectStarted:Connect(function(status)
		local ActiveSkills = WCS_Character:GetAllActiveSkills()

		for _, skill in ActiveSkills do
			if skill.CancelOn and skill.KeepOn then
				warn("Skill", skill.Name, "cant cancel because CancelOn and KeepOn are defined at the same time")
				continue
			end

			if skill.CancelOn and table.find(skill.CancelOn, status.Name) then
				print("Cancelling", skill.Name)
				skill:End()
			end

			if skill.KeepOn and not table.find(skill.KeepOn, status.Name) then
				continue
			else
				skill:End()
			end
		end
	end)

	WCS_Character.StatusEffectEnded:Connect(function(status)
		local ActiveSkills = WCS_Character:GetAllActiveSkills()

		for _, skill in ActiveSkills do
			if skill.CancelOnEnd and skill.KeepOnEnd then
				warn("Skill", skill.Name, "cant cancel because CancelOnEnd and KeepOnEnd are defined at the same time")
				continue
			end

			if skill.CancelOnEnd and table.find(skill.CancelOnEnd, status) then
				print("Cancelling", skill.Name)
				skill:End()
			end

			if skill.KeepOnEnd and table.find(skill.KeepOnEnd, status) then
				continue
			elseif skill.KeepOnEnd and not table.find(skill.KeepOnEnd, status) then
				skill:End()
			end
		end
	end)
end

function SpawnServiceServer.init(self: SpawnServiceServer)
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("Loaded") == false then
			continue
		end
		self:setupCharacter(player.Character or player.CharacterAdded:Wait())
	end

	for _, char in pairs(workspace.World.Live:GetChildren()) do
		if char:GetAttribute("Loaded") == false then
			continue
		end
		self:setupCharacter(char)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(char: Model)
			if player:GetAttribute("Loaded") == false then
				return
			end
			self:setupCharacter(char)
		end)
	end)

	Character.CharacterCreated:Connect(function(Character)
		InputServiceServer:bindCharacter(Character)
	end)
end

export type SpawnServiceServer = typeof(SpawnServiceServer) & {}

return SpawnServiceServer
