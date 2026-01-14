local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local RagdollServiceClient = {}

local function OnRagdollChanged(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local isRagdoll = character:GetAttribute("Ragdoll")

	if isRagdoll then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	else
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function SetupCharacter(character: Model)
	if not character then
		return
	end

	character:GetAttributeChangedSignal("Ragdoll"):Connect(function()
		OnRagdollChanged(character)
	end)

	if character:GetAttribute("Ragdoll") then
		OnRagdollChanged(character)
	end
end

function RagdollServiceClient.init()
	local character = Player.Character
	if character then
		SetupCharacter(character)
	end

	Player.CharacterAdded:Connect(SetupCharacter)
end

export type RagdollServiceClient = typeof(RagdollServiceClient)

return RagdollServiceClient
