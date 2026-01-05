local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local maid = require(ReplicatedStorage.Packages.maid)
local ClientUtil = require(ReplicatedStorage.Shared.Modules.Game.ClientUtil)
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

function MovementServiceClient._onRenderStep(self: MovementServiceClient, Delta: number): ()
	local IsDowned = Character:GetAttribute("Downed")
	local IsMoving = Humanoid.MoveDirection.Magnitude > 0 and not IsDowned
	local IsSummoned = CollectionService:HasTag(Character, "Summoned")
	local WalkSpeed = Character:GetAttribute("WalkSpeed")
	local Moveset = Character:GetAttribute("Moveset")

	if IsDowned then
		return
	end

	if IsMoving then
		if Humanoid.WalkSpeed > WalkSpeed then
			ClientUtil.PlayAnimation("Run", Character, Moveset)
			ClientUtil.StopAnimation("Walk", Character)
			ClientUtil.StopAnimation("Idle", Character)
			--[[if IsSummoned then
					if not ClientUtil.ReturnAnimInfo("StandRun").IsPlaying then
						ClientUtil.PlayAnim("StandRun")
						ClientUtil.StopAnim("StandWalk")
					end
				end--]]
		else
			ClientUtil.PlayAnimation("Walk", Character, Moveset)
			ClientUtil.StopAnimation("Run", Character)
			ClientUtil.StopAnimation("Idle", Character)

			--[[if IsSummoned then
					if not ClientUtil.ReturnAnimInfo("StandWalk").IsPlaying then
						ClientUtil.PlayAnim("StandWalk")
						ClientUtil.StopAnimation("StandRun")
					end
				end--]]
		end
	else
		ClientUtil.PlayAnimation("Idle", Character, Moveset)
		ClientUtil.StopAnimation("Walk", Character)
		ClientUtil.StopAnimation("Run", Character)
	end

	if Humanoid:GetState() == Enum.HumanoidStateType.Running then
		ClientUtil.StopAnimation("Fall", Character)
	elseif Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		if not ClientUtil.IsAnimationPlaying("Jump", Character, Moveset) then
			ClientUtil.PlayAnimation("Fall", Character, Moveset)
		end
	end

	self:_lean(Delta)
end

local function StateChanged(_, HumanoidState)
	local Moveset = Character:GetAttribute("Moveset")
	local CanJump = Character:GetAttribute("CanJump")

	local AllStates = Enum.HumanoidStateType
	Humanoid:SetStateEnabled(AllStates.Ragdoll, false)
	Humanoid:SetStateEnabled(AllStates.FallingDown, false)

	if HumanoidState == AllStates.Jumping and CanJump then
		ClientUtil.PlayAnimation("Jump", Character, Moveset)
		CanJump = false
		Humanoid:SetStateEnabled(AllStates.Jumping, false)
		task.delay(1.5, function()
			CanJump = true
			Humanoid:SetStateEnabled(AllStates.Jumping, true)
		end)
	elseif HumanoidState == AllStates.Landed then
		ClientUtil.PlayAnimation("Land", Character, Moveset)
		ClientUtil.StopAnimation("Jump", Character)
		ClientUtil.StopAnimation("Fall", Character)
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

function MovementServiceClient.init(self: MovementServiceClient)
	Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()

	game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
		Character = char
		Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
		HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
		Torso = Character:WaitForChild("Torso")

		RootJoint = HumanoidRootPart:WaitForChild("RootJoint")
		HeadJoint = Torso:WaitForChild("Neck")

		RootC0 = RootJoint.C0
		HeadC0 = HeadJoint.C0

		Humanoid.StateChanged:Connect(StateChanged)
	end)

	Humanoid.StateChanged:Connect(StateChanged)

	RunService.RenderStepped:Connect(function(Delta: number)
		self:_onRenderStep(Delta)
	end)
end

export type MovementServiceClient = typeof(MovementServiceClient) & {}

return MovementServiceClient
