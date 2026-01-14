local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)

local Attacking = wcs.RegisterStatusEffect("Attacking")

function Attacking:OnStartServer(HumanoidData: { WalkSpeed: number, JumpHeight: number }, priority: number)
	self:SetHumanoidData({
		WalkSpeed = { HumanoidData.WalkSpeed, "Set", priority },
		JumpHeight = { HumanoidData.JumpHeight, "Set", priority },
	})
end

function Attacking:OnEndServer()
	self:ClearHumanoidData()
end

return Attacking
