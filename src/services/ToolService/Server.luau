local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local MoveRegistry = require(ReplicatedStorage.Shared.Modules.Data.Moves.MoveRegistry)

local ToolServiceServer = {}

function ToolServiceServer.ChangeMoveset(Character, newMoveset, onComplete) end

function ToolServiceServer.init() end

export type ToolServiceServer = typeof(ToolServiceServer) & {}

return ToolServiceServer
