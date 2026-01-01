local SpawnServiceClient = {}

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function SpawnServiceClient._createCameraController(self: SpawnServiceClient)
	local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local CameraPositionObject = Instance.new("Part")
	CameraPositionObject.Name = "CameraPosition"
	CameraPositionObject.Size = Vector3.new(1, 1, 1)
	CameraPositionObject.CanCollide = false
	CameraPositionObject.CanQuery = false
	CameraPositionObject.CanTouch = false
	CameraPositionObject.Transparency = 1
	CameraPositionObject.Parent = Character.Head
	CameraPositionObject.CFrame = Character.Head.CFrame

	local CameraMotor = Instance.new("Motor6D")
	CameraMotor.Name = "CameraMotor"
	CameraMotor.Part0 = Character.Head
	CameraMotor.Part1 = CameraPositionObject

	CameraMotor.C0 = CFrame.new(0, 0, 0)
	CameraMotor.C1 = CFrame.new(0, 0, 0)

	CameraMotor.Parent = Character.Head

	local Camera = workspace.CurrentCamera
	Camera.CameraSubject = CameraPositionObject
	Character:SetAttribute("ShiftLock", false)

	self:_shiftLock()
end

function SpawnServiceClient._rotateCamera(self: SpawnServiceClient)
	local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()

	local Camera = workspace.CurrentCamera
	local HumanoidRootPart = Character.HumanoidRootPart
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	if Humanoid and Humanoid.AutoRotate then
		Humanoid.AutoRotate = true
	end

	local CameraDirection = Camera.CFrame.LookVector
	local TargetCFrame = CFrame.new(
		HumanoidRootPart.Position,
		HumanoidRootPart.Position + Vector3.new(CameraDirection.X, 0, CameraDirection.Z)
	)
	HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:Lerp(TargetCFrame, 0.3)
end

function SpawnServiceClient._shiftLock(self: SpawnServiceClient)
	local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local UIS = game:GetService("UserInputService")

	UIS.InputBegan:Connect(function(input, inputProcessed)
		if UIS:GetFocusedTextBox() then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
			Character:SetAttribute("ShiftLock", not Character:GetAttribute("ShiftLock"))
		end
	end)

	local Connection
	local RunService = game:GetService("RunService")

	if Character:GetAttribute("ShiftLock") == true then
		Connection = RunService.RenderStepped:Connect(function()
			self:_rotateCamera()
		end)
	else
		if Connection then
			Connection:Disconnect()
		end
	end

	Character:GetAttributeChangedSignal("ShiftLock"):Connect(function()
		if Character:GetAttribute("ShiftLock") == true then
			Connection = RunService.RenderStepped:Connect(function()
				self:_rotateCamera()
			end)
		else
			if Connection then
				Connection:Disconnect()
			end
		end
	end)
end

function SpawnServiceClient.init(self: SpawnServiceClient)
	self:_createCameraController()
end

export type SpawnServiceClient = typeof(SpawnServiceClient) & {}

return SpawnServiceClient
