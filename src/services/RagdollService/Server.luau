local RagdollServiceServer = {}

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local PlayersCollisionGroup = "Char"
local UncollidableGroup = "Uncollidable"

local function InitializeRagdollCollisionGroups()
	if not PhysicsService:IsCollisionGroupRegistered(PlayersCollisionGroup) then
		PhysicsService:RegisterCollisionGroup(PlayersCollisionGroup)
	end

	if not PhysicsService:IsCollisionGroupRegistered(UncollidableGroup) then
		PhysicsService:RegisterCollisionGroup(UncollidableGroup)
	end

	PhysicsService:CollisionGroupSetCollidable(UncollidableGroup, PlayersCollisionGroup, false)
	PhysicsService:CollisionGroupSetCollidable(UncollidableGroup, UncollidableGroup, false)
end

function RagdollServiceServer.init()
	InitializeRagdollCollisionGroups()
end

function RagdollServiceServer.NPC(Char)
	local function PushCharacter(Torso)
		Torso:ApplyImpulse(Torso.CFrame.LookVector * -100)
	end

	print("Setting up npc")
	local Torso = Char:WaitForChild("Torso")
	local Humanoid = Char:FindFirstChildWhichIsA("Humanoid") or Char:WaitForChild("Humanoid")

	Char:GetAttributeChangedSignal("Ragdoll"):Connect(function()
		local IsRagdoll = Char:GetAttribute("Ragdoll")

		if IsRagdoll then
			Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

			PushCharacter(Torso)
		else
			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

export type RagdollServiceServer = typeof(RagdollServiceServer)

return RagdollServiceServer
