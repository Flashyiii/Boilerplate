local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local RagdollUtil = require(ReplicatedStorage.Shared.Services.RagdollService.RagdollUtil)
local Highlight = require(ReplicatedStorage.Shared.Visuals.Highlight)

local Ragdoll = wcs.RegisterStatusEffect("Ragdoll")

function Ragdoll:OnStartServer()
	self:SetHumanoidData({
		WalkSpeed = { 0, "Set", 10 },
		JumpHeight = { 0, "Set", 10 },
	})

	local character = self.Character.Instance
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			RagdollUtil:Ragdoll(character)
		end
	end
end

function Ragdoll:OnEndServer()
	self:ClearHumanoidData()

	local character = self.Character.Instance
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			RagdollUtil:UnRagdoll(character)
			local highlightEffect = Highlight.new(character, { Color = Color3.fromRGB(122, 122, 122) })
			highlightEffect:Start(game.Players:GetPlayers())
		end
	end
end

return Ragdoll
