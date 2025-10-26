local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local conch = require(ReplicatedStorage.Packages.conch)
local DataService = require(ReplicatedStorage.Packages.dataservice).server

local Datastore = {}

conch.register("GetData", {
	description = "Get Players Datastore Data",
	permissions = { "GetData" },
	arguments = function()
		return conch.args.player("player", "Player Name")
	end,

	callback = function(player)
		local profile = DataService:getProfile(player)
		print(profile.Data)
	end,
})

return Datastore
