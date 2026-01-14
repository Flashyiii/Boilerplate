local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Busy = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Busy)
local Ragdoll = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Ragdoll)
local Stun = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Stun)
local Carrying = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Carrying)
local EndLag = require(ReplicatedStorage.Shared.Wcs.Conditions.States.EndLag)

local WCS = require(game:GetService("ReplicatedStorage").Packages.wcs)
local Base = WCS.RegisterSkill("Base")
type Base = WCS.Skill & typeof(Base)

function Base.OnConstruct(self: Base)
	self.MutualExclusives = {
		Ragdoll,
		Stun,
		Carrying,
		Busy,
		EndLag,
	}
end

return Base
