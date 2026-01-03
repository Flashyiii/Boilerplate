local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TouchInputService = game:GetService("TouchInputService")
local TweenService = game:GetService("TweenService")

local maid = require(ReplicatedStorage.Packages.maid)
local refx = require(ReplicatedStorage.Packages.refx)

local StandFX = refx.CreateEffect("StandFX")

-- Lifecycle: OnConstruct
function StandFX:OnConstruct()
	self.DestroyOnEnd = false
	self.DestroyOnLifecycleEnd = false
	self.DisableLeakWarning = false
end

-- Lifecycle: OnStart
function StandFX:OnStart(Target)
	self.Target = Target
	local Character = Target
	self._maid = maid.new()
	self.char = Players.LocalPlayer.Character
	self.StandObject = self.Target:FindFirstChild(self.Target:GetAttribute("Moveset"))

	local Stand = self.StandObject
	local Effect =
		ReplicatedStorage.Assets.Effects:FindFirstChild(self.Target:GetAttribute("Moveset")):FindFirstChild("Summon")
	local Attachment: Attachment = Effect.Attachment
	if Character:HasTag("Summoned") then
		for _, Inst in Character:GetDescendants() do
			if Inst:IsA("ParticleEmitter") or Inst:IsA("Beam") or Inst:IsA("Light") then
				Inst.Enabled = true
			end
		end

		FX = Attachment:Clone()
		FX.Parent = Stand["Torso"]
		for _, Particle in FX:GetDescendants() do
			if Particle:IsA("ParticleEmitter") then
				local count = Particle:GetAttribute("EmitCount") or 0
				local delayTime = Particle:GetAttribute("EmitDelay")

				if delayTime then
					task.delay(delayTime, function()
						Particle:Emit(count)
					end)
				else
					Particle:Emit(count)
				end
			end
		end

		task.delay(3, function()
			if FX and FX.Parent then
				FX:Destroy()
				FX = nil
				self:Destroy()
			end
		end)
	else
		for _, Inst in Character:GetDescendants() do
			if Inst:IsA("ParticleEmitter") or Inst:IsA("Beam") or Inst:IsA("Light") then
				Inst.Enabled = false
				task.delay(3, function()
					self:Destroy()
				end)
			end
		end
	end
end

-- Lifecycle: OnDestroy
function StandFX:OnDestroy() end

return StandFX
