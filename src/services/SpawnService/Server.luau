local SpawnServiceServer = {}

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
		char:SetAttribute("Stand", "TheWorld")
		--char:SetAttribute("Moveset", "TheWorld")
	end)
end

function Char(char: Model): ()
	local CharacterModel = char

	local Player: Player? = Players:GetPlayerFromCharacter(CharacterModel)
	if Player then
		Player:SetAttribute("Loaded", true)
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
	Humanoid.Died:Once(function()
		WCS_Character:Destroy()
	end)
end

function SpawnServiceServer.init(self: SpawnServiceServer)
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("Loaded") == false then
			continue
		end
		Char(player.Character or player.CharacterAdded:Wait())
	end

	for _, char in pairs(workspace.World.Live:GetChildren()) do
		if char:GetAttribute("Loaded") == false then
			continue
		end
		RagdollServiceServer.NPC(char)
		Char(char)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(char: Model)
			if player:GetAttribute("Loaded") == false then
				return
			end
			Char(char)
		end)
	end)

	Character.CharacterCreated:Connect(function(Character)
		InputServiceServer:bindCharacter(Character)
	end)
end

export type SpawnServiceServer = typeof(SpawnServiceServer) & {}

return SpawnServiceServer
