local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local Busy = wcs.RegisterStatusEffect("Busy")

function Busy:OnStartServer() end

function Busy:OnEndServer() end

return Busy
