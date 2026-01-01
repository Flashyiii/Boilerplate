local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local IFRame = wcs.RegisterStatusEffect("IFRame")

function IFRame:OnStartServer() end

function IFRame:OnEndServer() end

return IFRame
