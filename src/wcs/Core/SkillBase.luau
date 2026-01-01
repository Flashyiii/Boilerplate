local WCS = require(game:GetService("ReplicatedStorage").Packages.wcs)
local Base = WCS.RegisterSkill("Base")
type Base = WCS.Skill & typeof(Base)

function Base.OnConstruct(self: Base)
	warn(self:GetName())
	
end

return Base
