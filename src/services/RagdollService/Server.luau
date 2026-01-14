local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RagdollUtil = require(ReplicatedStorage.Shared.Services.RagdollService.RagdollUtil)

local RAGDOLL_COLLISION_GROUP = "RagdollLimbs"

local RagdollServiceServer = {}

local function InitializeRagdollCollisionGroups()
	if not PhysicsService:IsCollisionGroupRegistered(RAGDOLL_COLLISION_GROUP) then
		PhysicsService:RegisterCollisionGroup(RAGDOLL_COLLISION_GROUP)
	end
	PhysicsService:CollisionGroupSetCollidable(RAGDOLL_COLLISION_GROUP, RAGDOLL_COLLISION_GROUP, false)
end

function RagdollServiceServer.init()
	InitializeRagdollCollisionGroups()
end

function RagdollServiceServer.Ragdoll(character: Model)
	RagdollUtil:Ragdoll(character)
end

function RagdollServiceServer.UnRagdoll(character: Model)
	RagdollUtil:UnRagdoll(character)
end

function RagdollServiceServer.Toggle(character: Model)
	RagdollUtil:Toggle(character)
end

function RagdollServiceServer.IsRagdolled(character: Model): boolean
	return RagdollUtil:IsRagdolled(character)
end

export type RagdollServiceServer = typeof(RagdollServiceServer)

return RagdollServiceServer
