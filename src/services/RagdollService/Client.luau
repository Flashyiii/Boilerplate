local Players = game:GetService("Players")

local Player: Player = Players.LocalPlayer

local function PushCharacter(Torso)
	Torso:ApplyImpulse(Torso.CFrame.LookVector * -100)
end

local function AttributeChangedSignal(Char)
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

local Character = Players.LocalPlayer.Character or Players.LocalPlayer.Character:Wait()
AttributeChangedSignal(Character)

return {}
