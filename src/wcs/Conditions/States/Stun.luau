local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local Stun = wcs.RegisterStatusEffect("Stun")

function Stun:OnStartServer()
	self:SetHumanoidData({
		WalkSpeed = { 0, "Set", 10 },
		JumpHeight = { 0, "Set", 10 },
	})
end

function Stun:OnEndServer()
	self:ClearHumanoidData()
end

return Stun
