local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local RAGDOLL_TAG = "RagdollConstraint"
local COLLIDER_TAG = "RagdollCollider"
local RAGDOLL_COLLISION_GROUP = "RagdollLimbs"

local RagdollModule = {}

local R6_JOINTS = {
	["Head"] = {
		limb = "Head",
		torsoAttach = CFrame.new(0, 1, 0),
		limbAttach = CFrame.new(0, -0.5, 0),
		limits = { upper = 30, twist = 30 },
		friction = 50,
	},
	["Left Arm"] = {
		limb = "Left Arm",
		torsoAttach = CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(-15)),
		limbAttach = CFrame.new(0.5, 0.5, 0),
		limits = { upper = 60, twist = 45 },
		friction = 25,
	},
	["Right Arm"] = {
		limb = "Right Arm",
		torsoAttach = CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(15)),
		limbAttach = CFrame.new(-0.5, 0.5, 0),
		limits = { upper = 60, twist = 45 },
		friction = 25,
	},
	["Left Leg"] = {
		limb = "Left Leg",
		torsoAttach = CFrame.new(-0.5, -1, 0) * CFrame.Angles(math.rad(-10), 0, math.rad(15)),
		limbAttach = CFrame.new(0, 1, 0),
		limits = { upper = 45, twist = 10 },
		friction = 35,
	},
	["Right Leg"] = {
		limb = "Right Leg",
		torsoAttach = CFrame.new(0.5, -1, 0) * CFrame.Angles(math.rad(-10), 0, math.rad(-15)),
		limbAttach = CFrame.new(0, 1, 0),
		limits = { upper = 45, twist = 10 },
		friction = 35,
	},
}

local COLLIDER_PHYSICAL_PROPERTIES = PhysicalProperties.new(0.7, 0.5, 0.05, 1, 1)

local R6_LIMBS = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

local function EnsureCollisionGroups()
	if not PhysicsService:IsCollisionGroupRegistered(RAGDOLL_COLLISION_GROUP) then
		PhysicsService:RegisterCollisionGroup(RAGDOLL_COLLISION_GROUP)
	end
	PhysicsService:CollisionGroupSetCollidable(RAGDOLL_COLLISION_GROUP, RAGDOLL_COLLISION_GROUP, true)
	PhysicsService:CollisionGroupSetCollidable(RAGDOLL_COLLISION_GROUP, "Default", true)
end

local function GetPlayerFromCharacter(character: Model): Player?
	return Players:GetPlayerFromCharacter(character)
end

local function SetNetworkOwner(character: Model, player: Player?)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			pcall(function()
				part:SetNetworkOwner(player)
			end)
		end
	end
end

local COLLIDER_SIZE_MULTIPLIERS = {
	["Head"] = Vector3.new(0.9, 0.9, 0.9),
	["Torso"] = Vector3.new(1, 1, 1),
	["Left Arm"] = Vector3.new(1, 1, 1),
	["Right Arm"] = Vector3.new(1, 1, 1),
	["Left Leg"] = Vector3.new(1, 1, 1),
	["Right Leg"] = Vector3.new(1, 1, 1),
}

local function CreateColliderForLimb(limb: BasePart): Part
	local sizeMultiplier = COLLIDER_SIZE_MULTIPLIERS[limb.Name] or Vector3.new(1, 1, 1)

	local trans = 1
	if _G.Debug then
		trans = 0.75
	end

	local collider = Instance.new("Part")
	collider.Name = limb.Name .. "_Collider"
	collider.Size = limb.Size * sizeMultiplier
	collider.CFrame = limb.CFrame
	collider.Transparency = trans
	collider.CanCollide = true
	collider.CanQuery = false
	collider.CanTouch = false
	collider.Massless = true
	collider.Color = Color3.fromRGB(255, 0, 0)
	collider.CustomPhysicalProperties = COLLIDER_PHYSICAL_PROPERTIES
	collider.CollisionGroup = RAGDOLL_COLLISION_GROUP
	collider:AddTag(COLLIDER_TAG)
	collider:AddTag(RAGDOLL_TAG)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = limb
	weld.Part1 = collider
	weld.Parent = collider

	return collider
end

local function CreateCollisionProxies(character: Model)
	EnsureCollisionGroups()

	local colliderFolder = Instance.new("Folder")
	colliderFolder.Name = "_RagdollColliders"
	colliderFolder:AddTag(RAGDOLL_TAG)
	colliderFolder.Parent = character

	for _, limbName in R6_LIMBS do
		local limb = character:FindFirstChild(limbName)
		if limb and limb:IsA("BasePart") then
			local collider = CreateColliderForLimb(limb)
			collider.Parent = colliderFolder
		end
	end
end

local function CreateConstraints(character: Model)
	local torso = character:FindFirstChild("Torso")
	if not torso then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	for jointName, jointData in R6_JOINTS do
		local limb = character:FindFirstChild(jointData.limb)
		if not limb then
			continue
		end

		local torsoAttachment = Instance.new("Attachment")
		torsoAttachment.Name = jointName .. "_TorsoAttach"
		torsoAttachment.CFrame = jointData.torsoAttach
		torsoAttachment:AddTag(RAGDOLL_TAG)
		torsoAttachment.Parent = torso

		local limbAttachment = Instance.new("Attachment")
		limbAttachment.Name = jointName .. "_LimbAttach"
		limbAttachment.CFrame = jointData.limbAttach
		limbAttachment:AddTag(RAGDOLL_TAG)
		limbAttachment.Parent = limb

		local ballSocket = Instance.new("BallSocketConstraint")
		ballSocket.Name = jointName .. "_Socket"
		ballSocket.Attachment0 = torsoAttachment
		ballSocket.Attachment1 = limbAttachment
		ballSocket.LimitsEnabled = true
		ballSocket.UpperAngle = jointData.limits.upper
		ballSocket.TwistLimitsEnabled = true
		ballSocket.TwistLowerAngle = -jointData.limits.twist
		ballSocket.TwistUpperAngle = jointData.limits.twist
		ballSocket.Restitution = 0
		ballSocket.MaxFrictionTorque = jointData.friction
		ballSocket:AddTag(RAGDOLL_TAG)
		ballSocket.Parent = hrp
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and torso then
		local weld = Instance.new("Weld")
		weld.Name = "RagdollRootWeld"
		weld.Part0 = torso
		weld.Part1 = hrp
		weld.C0 = CFrame.new()
		weld:AddTag(RAGDOLL_TAG)
		weld.Parent = torso
	end
end

local function RemoveRagdollComponents(character: Model)
	for _, obj in character:GetDescendants() do
		if obj:HasTag(RAGDOLL_TAG) then
			obj:Destroy()
		end
	end
end

local function DisableMotors(character: Model)
	for _, motor in character:GetDescendants() do
		if motor:IsA("Motor6D") then
			motor.Enabled = false
		end
	end
end

local function EnableMotors(character: Model)
	for _, motor in character:GetDescendants() do
		if motor:IsA("Motor6D") then
			motor.Enabled = true
		end
	end
end

function RagdollModule:Ragdoll(character: Model)
	if not character then
		return
	end
	if character:GetAttribute("Ragdoll") then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local torso = character:FindFirstChild("Torso")
	if not humanoid or not torso then
		return
	end

	local player = GetPlayerFromCharacter(character)

	humanoid.BreakJointsOnDeath = false
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	CreateCollisionProxies(character)
	CreateConstraints(character)
	DisableMotors(character)

	SetNetworkOwner(character, player)

	character:SetAttribute("Ragdoll", true)
end

function RagdollModule:UnRagdoll(character: Model)
	if not character then
		return
	end
	if not character:GetAttribute("Ragdoll") then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local torso = character:FindFirstChild("Torso")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid then
		return
	end

	RemoveRagdollComponents(character)
	EnableMotors(character)

	humanoid.AutoRotate = true
	humanoid.PlatformStand = false

	if hrp and torso then
		hrp.CFrame = torso.CFrame
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	local player = GetPlayerFromCharacter(character)
	SetNetworkOwner(character, player)

	task.defer(function()
		if humanoid and humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)

	character:SetAttribute("Ragdoll", false)
end

function RagdollModule:Toggle(character: Model)
	if character:GetAttribute("Ragdoll") then
		self:UnRagdoll(character)
	else
		self:Ragdoll(character)
	end
end

function RagdollModule:IsRagdolled(character: Model): boolean
	return character:GetAttribute("Ragdoll") == true
end

return RagdollModule
