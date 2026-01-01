local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local EndLag = wcs.RegisterStatusEffect("EndLag")

function EndLag:OnStartServer() end

function EndLag:OnEndServer() end

return EndLag
