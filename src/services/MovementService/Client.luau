local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local AnimationPlayer = require(ReplicatedStorage.Shared.Modules.Game.AnimationPlayer)
local MovementServiceClient = {}

local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Torso = Character:WaitForChild("Torso")

local RootJoint = HumanoidRootPart:WaitForChild("RootJoint")
local RootC0 = RootJoint.C0
local HeadJoint = Torso:WaitForChild("Neck")
local HeadC0 = HeadJoint.C0

local Floor = RaycastParams.new()
Floor.FilterType = Enum.RaycastFilterType.Include
Floor.FilterDescendantsInstances = { workspace.World.Map }

function MovementServiceClient._onRenderStep(
	self: MovementServiceClient,
	Delta: number,
	_Animator: any,
	MovementHandles: any
): ()
	local IsDowned = Character:GetAttribute("Downed")
	local IsMoving = Humanoid.MoveDirection.Magnitude > 0 and not IsDowned

	if IsDowned then
		return
	end

	if IsMoving and Humanoid.WalkSpeed ~= 0 then
		if Humanoid.WalkSpeed > Character:GetAttribute("WalkSpeed") then
			if not MovementHandles.Run:IsPlaying() then
				MovementHandles.Idle:Stop()
				MovementHandles.Walk:Stop()
				MovementHandles.Run:Play()
			end
		else
			if not MovementHandles.Walk:IsPlaying() then
				MovementHandles.Idle:Stop()
				MovementHandles.Run:Stop()
				MovementHandles.Walk:Play()
			end
		end
	else
		if not MovementHandles.Idle:IsPlaying() then
			MovementHandles.Walk:Stop()
			MovementHandles.Run:Stop()
			MovementHandles.Idle:Play()
		end
	end

	if Humanoid:GetState() == Enum.HumanoidStateType.Running then
		MovementHandles.Fall:Stop()
	elseif Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		if not MovementHandles.Jump:IsPlaying() and not MovementHandles.Fall:IsPlaying() then
			MovementHandles.Fall:Play()
		end
	end

	self:_lean(Delta)
end

local function StateChanged(HumanoidState: Enum.HumanoidStateType, MovementHandles: any)
	local CanJump = Character:GetAttribute("CanJump")

	local AllStates = Enum.HumanoidStateType
	Humanoid:SetStateEnabled(AllStates.Ragdoll, false)
	Humanoid:SetStateEnabled(AllStates.FallingDown, false)

	if HumanoidState == AllStates.Jumping and CanJump and Humanoid.JumpHeight ~= 0 then
		MovementHandles.Jump:Play()
		CanJump = false
		Humanoid:SetStateEnabled(AllStates.Jumping, false)
		task.delay(1.5, function()
			CanJump = true
			Humanoid:SetStateEnabled(AllStates.Jumping, true)
		end)
	elseif HumanoidState == AllStates.Landed then
		MovementHandles.Land:Play()
		MovementHandles.Jump:Stop()
		MovementHandles.Fall:Stop()
	end
end

function MovementServiceClient._lean(self: MovementServiceClient, Delta: number): ()
	local CheckGround =
		workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0, -HumanoidRootPart.Size.Y * 1.5 - 0.3), Floor)
	local MoveDirGroundSlope = Humanoid.MoveDirection.Magnitude == 0 and HumanoidRootPart.CFrame.LookVector
		or Humanoid.MoveDirection
	local MovementCF = CFrame.lookAt(HumanoidRootPart.Position, HumanoidRootPart.Position + MoveDirGroundSlope)
	local NormalObjectSpace = CheckGround and MovementCF:VectorToObjectSpace(CheckGround.Normal) or Vector3.zero
	local MovementClampZ = math.clamp(NormalObjectSpace.Z * 65, -46, 12)

	local MoveDirection = HumanoidRootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)

	local RootX = math.clamp(MoveDirection.Z * 25, -8.8, 20) + MovementClampZ
	local RootY = math.clamp(MoveDirection.X * 25, -11.2, 11.2)
	local RootZ = math.clamp(MoveDirection.X * 45, -38, 38)
	local HeadZ = math.clamp(MoveDirection.X * 35, -30, 30)
	if MoveDirection.Z > 0.5 then
		RootZ = -RootZ
		HeadZ = -HeadZ
	end

	RootJoint.C0 =
		RootJoint.C0:Lerp(RootC0 * CFrame.Angles(-math.rad(RootX), -math.rad(RootY), -math.rad(RootZ)), 4.5 * Delta)
	HeadJoint.C0 = HeadJoint.C0:Lerp(
		HeadC0
			* CFrame.Angles(
				math.rad(math.clamp(MoveDirection.Z * 25, -13.5, 23) + MovementClampZ / 3),
				math.rad(math.clamp(MoveDirection.X * 25, -8.2, 8.2)),
				math.rad(HeadZ)
			),
		3.7 * Delta
	)
end

local function CreateMovementHandles(Animator: any, Moveset: string?)
	local handles = {
		Idle = Animator:Play("Idle", Moveset):SetLooped(true):SetPriority(Enum.AnimationPriority.Idle),
		Walk = Animator:Play("Walk", Moveset):SetLooped(true):SetPriority(Enum.AnimationPriority.Idle),
		Run = Animator:Play("Run", Moveset):SetLooped(true):SetPriority(Enum.AnimationPriority.Idle),
		Jump = Animator:Play("Jump", Moveset):SetPriority(Enum.AnimationPriority.Idle),
		Fall = Animator:Play("Fall", Moveset):SetLooped(true):SetPriority(Enum.AnimationPriority.Idle),
		Land = Animator:Play("Land", Moveset):SetPriority(Enum.AnimationPriority.Idle),
	}
	return handles
end

function MovementServiceClient.init(self: MovementServiceClient)
	Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
	local Animator = AnimationPlayer.new(Character)
	local MovementHandles = CreateMovementHandles(Animator, Character:GetAttribute("Moveset"))
	MovementHandles.Idle:Play()

	game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
		Character = char
		Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
		HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
		Torso = Character:WaitForChild("Torso")

		RootJoint = HumanoidRootPart:WaitForChild("RootJoint")
		HeadJoint = Torso:WaitForChild("Neck")

		RootC0 = RootJoint.C0
		HeadC0 = HeadJoint.C0

		Animator = AnimationPlayer.new(Character)
		MovementHandles = CreateMovementHandles(Animator, Character:GetAttribute("Moveset"))
		MovementHandles.Idle:Play()

		Humanoid.StateChanged:Connect(function(_, state)
			StateChanged(state, MovementHandles)
		end)
	end)

	Character:GetAttributeChangedSignal("Moveset"):Connect(function()
		for _, handle in MovementHandles do
			handle:Destroy()
		end
		Animator = AnimationPlayer.new(Character)
		MovementHandles = CreateMovementHandles(Animator, Character:GetAttribute("Moveset"))
		MovementHandles.Idle:Play()
	end)

	Humanoid.StateChanged:Connect(function(_, state)
		StateChanged(state, MovementHandles)
	end)

	RunService.RenderStepped:Connect(function(Delta: number)
		self:_onRenderStep(Delta, Animator, MovementHandles)
	end)
end

export type MovementServiceClient = typeof(MovementServiceClient) & {}

return MovementServiceClient
