local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local KnockbackHandler = {
	KnockbackTable = {},
}

function KnockbackHandler.Knockback(Attacker: Model, Target: Model, KnockbackData)
	if Target:GetAttribute("TimeStoped") then
		if not KnockbackHandler.KnockbackTable[Target] then
			KnockbackHandler.KnockbackTable[Target] = { KnockbackData }
		else
			table.insert(KnockbackHandler.KnockbackTable[Target], KnockbackData)
		end
		repeat
			task.wait()
		until not Target:GetAttribute("TimeStoped")
	end

	local DefaultStats = {
		Speed = 0,
		Time = 0.2,
		Relative = "Attacker",
	}

	if KnockbackHandler.KnockbackTable[Target] then
		for i, v in pairs(KnockbackHandler.KnockbackTable[Target]) do
			if v.Speed > DefaultStats.Speed then
				DefaultStats.Speed = v.Speed
			end
		end
		KnockbackData = DefaultStats

		KnockbackHandler.KnockbackTable[Target] = nil
	end

	local AttackerRootPart = Attacker:FindFirstChild("HumanoidRootPart")
	local TargetRootPart = Target:FindFirstChild("HumanoidRootPart")

	local KnockbackTime = KnockbackData.Time
	local KnockbackSpeed = KnockbackData.Speed or 1

	local KnockbackVelocity = KnockbackData.Velocity
	local Relative = KnockbackData.Relative
	local RelativeNegative = KnockbackData.RelativeNegative

	if KnockbackData.Override then
		for i, v in pairs(AttackerRootPart:GetChildren()) do
			if v.Name == "KnockbackVelocity" then
				v:Destroy()
			end
		end
	end

	KnockbackVelocity = KnockbackVelocity or Vector3.zero

	local BodyVelocity = Instance.new("BodyVelocity") :: BodyVelocity
	BodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 100000
	BodyVelocity.P = math.huge
	BodyVelocity.Name = "KnockbackVelocity"

	if Relative then
		if Relative == "Attacker" then
			BodyVelocity.Velocity = (AttackerRootPart.CFrame.LookVector * KnockbackSpeed) + KnockbackVelocity
		elseif Relative == "Target" then
			BodyVelocity.Velocity = (TargetRootPart.CFrame.LookVector * KnockbackSpeed) + KnockbackVelocity
		elseif Relative.X then
			BodyVelocity.Velocity = Relative * KnockbackSpeed + KnockbackVelocity
		end
	elseif RelativeNegative then
		if RelativeNegative == "Attacker" then
			BodyVelocity.Velocity = (-AttackerRootPart.CFrame.LookVector * KnockbackSpeed) + KnockbackVelocity
		elseif RelativeNegative == "Target" then
			BodyVelocity.Velocity = (-TargetRootPart.CFrame.LookVector * KnockbackSpeed) + KnockbackVelocity
		end
	end

	Debris:AddItem(BodyVelocity, KnockbackTime)
	BodyVelocity.Parent = TargetRootPart

	if Players:GetPlayerFromCharacter(Target) then
		TargetRootPart:SetNetworkOwner(Players:GetPlayerFromCharacter(Target))
	end
end

return KnockbackHandler
