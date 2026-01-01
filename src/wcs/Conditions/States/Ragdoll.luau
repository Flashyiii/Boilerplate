local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local RagdollService = require(ReplicatedStorage.Shared.Services.RagdollService.Util)
local Ragdoll = wcs.RegisterStatusEffect("Ragdoll")

function Ragdoll:OnStartServer()
	RagdollService:Ragdoll(self.Character.Instance)
	self:SetHumanoidData({
		WalkSpeed = { 0, "Set", 10 },
		JumpHeight = { 0, "Set", 10 },
	})
end

function Ragdoll:OnEndServer()
	self:ClearHumanoidData()
	RagdollService:unRagdoll(self.Character.Instance)
end

return Ragdoll
