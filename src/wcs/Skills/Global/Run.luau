local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local Running = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Running)
local SkillBase = require(ReplicatedStorage.Shared.Wcs.Core.SkillBase)

local Run = wcs.RegisterHoldableSkill("Run")

function Run:OnConstruct()
	SkillBase.OnConstruct(self)
	self.CheckOthersActive = false
	self.CheckedByOthers = false
	--self.Toggle = true -- Determines if the skill can be toggled on and off or just held down
end

function Run:CanCancel(): boolean
	return true
end

function Run:OnStartServer()
	self.RunningEffect = Running.new(self.Character)
	self.RunningEffect:Start()
end

function Run:OnEndServer()
	if self.RunningEffect then
		self.RunningEffect:End()
	end
	self:ApplyCooldown(0.1)
end

return Run
