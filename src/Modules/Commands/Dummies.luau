local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local conch = require(ReplicatedStorage.Packages.conch)
local wcs = require(ReplicatedStorage.Packages.wcs)
local M1 = require(ReplicatedStorage.Shared.Wcs.Skills.Global.M1)
local StatServiceServer = require(ServerScriptService.Services.StatService.StatServiceServer)
local RagdollServiceServer = require(ServerScriptService.Services.RagdollService.RagdollServiceServer)
local InputServiceServer = require(ServerScriptService.Services.InputService.InputServiceServer)

local Character = wcs.Character

local function createDummy(name: string, position: Vector3): Model
	local dummyFolder = ReplicatedStorage.Assets:WaitForChild("Dummy")
	local dummyModel = dummyFolder:FindFirstChildOfClass("Model")

	if not dummyModel then
		for _, child in ipairs(dummyFolder:GetChildren()) do
			if child:IsA("Model") then
				dummyModel = child
				break
			end
		end
	end

	if not dummyModel then
		error("No Model found in ReplicatedStorage.Assets.Dummy")
	end

	local character = dummyModel:Clone()
	character.Name = name

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 5)
	end

	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	character:PivotTo(CFrame.new(position))

	return character
end

local function setupDummy(character: Model)
	character.Parent = workspace.World.Live

	local WCS_Character = Character.new(character)
	StatServiceServer:initCharacter(character)

	character:SetAttribute("Loaded", true)
	character:SetAttribute("TimeStoped", false)
	character:SetAttribute("Moveset", "TheWorld")
	character:SetAttribute("CanJump", true)
	character:SetAttribute("Stand", "TheWorld")

	InputServiceServer:bindCharacter(WCS_Character)

	WCS_Character:SetDefaultProps({
		WalkSpeed = character:GetAttribute("WalkSpeed"),
	})

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Once(function()
			WCS_Character:Destroy()
		end)
	end

	return WCS_Character
end

conch.register("SpawnDummies", {
	description = "Spawn 3 Dummies: Normal, Infinite Health, and Attacking",
	permissions = { "SpawnDummies" },
	arguments = function()
		return conch.args.player("player", "Player to spawn dummies near (optional)")
	end,

	callback = function(player: Player?)
		local targetPlayer = player
		if not targetPlayer then
			local players = Players:GetPlayers()
			if #players > 0 then
				targetPlayer = players[1]
			end
		end

		local spawnPosition = Vector3.new(0, 10, 0)
		if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
			spawnPosition = targetPlayer.Character.HumanoidRootPart.Position
		end

		local offset = 5

		local normalDummy = createDummy("NormalDummy", spawnPosition + Vector3.new(-offset, 0, 0))
		local infHealthDummy = createDummy("InfHealthDummy", spawnPosition + Vector3.new(0, 0, 0))
		local attackingDummy = createDummy("AttackingDummy", spawnPosition + Vector3.new(offset, 0, 0))

		task.wait(0.1)

		setupDummy(normalDummy)

		setupDummy(infHealthDummy)
		local infHealthHumanoid = infHealthDummy:FindFirstChildOfClass("Humanoid")
		if infHealthHumanoid then
			infHealthHumanoid.MaxHealth = math.huge
			infHealthHumanoid.Health = math.huge
			infHealthHumanoid.HealthChanged:Connect(function()
				if infHealthHumanoid.Health < infHealthHumanoid.MaxHealth then
					infHealthHumanoid.Health = infHealthHumanoid.MaxHealth
				end
			end)
		end

		local attackingWCS = setupDummy(attackingDummy)
		local attackingHumanoidRootPart = attackingDummy:FindFirstChild("HumanoidRootPart")
		if not attackingHumanoidRootPart then
			warn("AttackingDummy missing HumanoidRootPart")
			return
		end

		task.spawn(function()
			local attackingHumanoid = attackingDummy:FindFirstChildOfClass("Humanoid")
			while attackingDummy.Parent and attackingHumanoid and attackingHumanoid.Health > 0 do
				local nearestPlayer = nil
				local nearestDistance = math.huge

				for _, plr in ipairs(Players:GetPlayers()) do
					if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
						local distance = (attackingHumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
						if distance < nearestDistance and distance < 50 then
							nearestDistance = distance
							nearestPlayer = plr
						end
					end
				end

				local m1Skill = attackingWCS:GetSkillFromConstructor(M1)
				if m1Skill then
					local state = m1Skill:GetState()
					if not state.IsActive then
						m1Skill:Start()
					end
				end
				task.wait(0.5)
			end
		end)
	end,
})

return {}
