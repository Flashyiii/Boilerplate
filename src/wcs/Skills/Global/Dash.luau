local ReplicatedStorage = game:GetService("ReplicatedStorage")

local trove = require(ReplicatedStorage.Packages.trove)
local wcs = require(ReplicatedStorage.Packages.wcs)
local ClientUtil = require(ReplicatedStorage.Shared.Modules.Game.ClientUtil)
local KnockbackHandler = require(ReplicatedStorage.Shared.Modules.Utility.KnockbackHandler)
local Stun = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Stun)
local EndLagStatus = require(ReplicatedStorage.Shared.Wcs.Conditions.States.EndLag)
local AnimationPlayer = require(ReplicatedStorage.Shared.Modules.Game.AnimationPlayer)
local SkillBase = require(ReplicatedStorage.Shared.Wcs.Core.SkillBase)

local function GetDashDirection(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return hrp.CFrame.LookVector
	end

	local velocity = hrp.AssemblyLinearVelocity
	velocity = Vector3.new(velocity.X, 0, velocity.Z)

	if velocity.Magnitude < 1 then
		return hrp.CFrame.LookVector
	end

	local moveDir = velocity.Unit

	local presets = {
		Forward = hrp.CFrame.LookVector,
		Backward = -hrp.CFrame.LookVector,
		Right = hrp.CFrame.RightVector,
		Left = -hrp.CFrame.RightVector,
	}

	local bestDir
	local bestDot = -math.huge

	for _, dir in presets do
		local dot = moveDir:Dot(dir)
		if dot > bestDot then
			bestDot = dot
			bestDir = dir
		end
	end

	return bestDir.Unit
end

local Dash = wcs.RegisterSkill("Dash")

function Dash:OnConstruct()
	SkillBase.OnConstruct(self)
end

function Dash:CanCancel(): boolean
	return false
end

function Dash:OnStartServer()
	local character = self.Character.Instance

	local Duration = character:GetAttribute("DashDuration") or 0.25
	local EndLagDuration = Duration + 0.35
	local SpeedStat = character:GetAttribute("DashSpeed") or 60

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")

	if humanoid and hrp then
		ClientUtil.PlaySound("Whoosh", hrp, { Volume = 1, TimePosition = 0 })

		local Animator = AnimationPlayer.new(character)
		Animator:Play("Dash", character:GetAttribute("Moveset")):SetPriority(Enum.AnimationPriority.Movement):Play()

		local StunEffect = Stun.new(self.Character)
		StunEffect:Start(EndLagDuration)

		local EndLagEffect = EndLagStatus.new(self.Character)
		EndLagEffect:Start(EndLagDuration)

		local dashDirection = GetDashDirection(character)

		KnockbackHandler.Knockback(character, character, {
			Speed = SpeedStat,
			Time = Duration,
			Relative = dashDirection,
		})

		task.delay(Duration, function()
			self:End()
		end)
	end
end

function Dash:OnEndServer()
	local character = self.Character.Instance
	local Cooldown = character:GetAttribute("DashCooldown") or 2
	self:ApplyCooldown(Cooldown)
end

return Dash
