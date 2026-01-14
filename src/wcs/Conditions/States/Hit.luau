local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)

local Hit = wcs.RegisterStatusEffect("Hit")

function Hit:OnStartServer() end

function Hit:OnEndServer() end

return Hit
