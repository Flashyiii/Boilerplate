local SpawnServiceServer = {}

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StatServiceServer = require(ServerScriptService.Services.StatService.StatServiceServer)
local wcs = require(ReplicatedStorage.Packages.wcs)
local Dash = require(ReplicatedStorage.Shared.WCS.Skills.Dash)
local Character = wcs.Character

function SetAttributes(char: Model): ()
	char:SetAttribute("Loaded", true)
	char:SetAttribute("TimeStoped", false)
end

function SetSkills(char: Model): ()
	-- TODO : Testing system for Skill Development

	local WCS_Character = Character.GetCharacterFromInstance(char)
	if not WCS_Character then
		return
	end
	warn("Setting Skills for ", char.Name)

	--* Skills
	Dash.new(WCS_Character)
end

function Char(char: Model): ()
	local CharacterModel = char

	local Player: Player? = Players:GetPlayerFromCharacter(CharacterModel)
	if Player then
		Player:SetAttribute("Loaded", true)
	end

	char.Parent = workspace.Live

	local WCS_Character = Character.new(CharacterModel)
	StatServiceServer:initCharacter(CharacterModel)

	SetSkills(char)
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

	for _, char in pairs(workspace.Live:GetChildren()) do
		if char:GetAttribute("Loaded") == false then
			continue
		end
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
end

export type SpawnServiceServer = typeof(SpawnServiceServer) & {}

return SpawnServiceServer
