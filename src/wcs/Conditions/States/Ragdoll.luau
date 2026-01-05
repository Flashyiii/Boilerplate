local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local ClientUtil = require(ReplicatedStorage.Shared.Modules.Game.ClientUtil)
local RagdollService = require(ReplicatedStorage.Shared.Services.RagdollService.Util)
local Highlight = require(ReplicatedStorage.Shared.Visuals.Highlight)
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

	ClientUtil.PlayAnimation("UnRagdoll", self.Character.Instance)

	local highlightEffect = Highlight.new(self.Character.Instance, { Color = Color3.fromRGB(124, 124, 124) })
	highlightEffect:Start(game.Players:GetPlayers())

	RagdollService:unRagdoll(self.Character.Instance)
end

return Ragdoll
