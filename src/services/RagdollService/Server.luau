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

export type RagdollServiceServer = typeof(RagdollServiceServer)

return RagdollServiceServer
