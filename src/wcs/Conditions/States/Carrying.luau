local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)

local Carrying = wcs.RegisterStatusEffect("Carrying")

function Carrying:OnStartServer()
	local Character = self.Character.Instance
	self:SetHumanoidData({
		WalkSpeed = { Character:GetAttribute("WalkSpeed") / 2, "Set", 2 },
		JumpHeight = { 0, "Set", 2 },
	})
end

function Carrying:OnEndServer()
	self:ClearHumanoidData()
end

return Carrying
