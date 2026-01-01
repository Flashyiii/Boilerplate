local Players = game:GetService("Players")

local Player: Player = Players.LocalPlayer
local Character: Model = Player.Character or Player.CharacterAdded:Wait()

local Torso = Character:WaitForChild("Torso")
local Humanoid = Character:FindFirstChildWhichIsA("Humanoid") or Character:WaitForChild("Humanoid")

local function PushCharacter()
	Torso:ApplyImpulse(Torso.CFrame.LookVector * -100)
end

Character:GetAttributeChangedSignal("Ragdoll"):Connect(function()
	local IsRagdoll = Character:GetAttribute("Ragdoll")

	if IsRagdoll then
		Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

		PushCharacter()
	else
		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end)

return {}
