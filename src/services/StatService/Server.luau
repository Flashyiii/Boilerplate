local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatIndex = {}
local StatServiceServer = {}

local DefaultStats = require(ReplicatedStorage.Shared.Modules.Core.CharacterData.DefaultStats)

function StatServiceServer.initCharacter(self: StatServiceServer, character: Model, stats: any): ()
	local Stats = stats or DefaultStats
	for statName, statValue in pairs(Stats) do
		character:SetAttribute(statName, statValue)
	end
end

function StatServiceServer.init(self: StatServiceServer) end

export type StatServiceServer = typeof(StatServiceServer) & {}

return StatServiceServer
