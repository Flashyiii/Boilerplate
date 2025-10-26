local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local dataservice = require(ReplicatedStorage.Packages.dataservice).server
local conch = require(ReplicatedStorage.Packages.conch)
conch.initiate_default_lifecycle()

conch.set_role_permissions("admin", "use-capes", "use-server-command")

local super_admins = {
	"itzFlashyiii",
}

local CommandServiceServer = {}

for _, v in pairs(ReplicatedStorage.Shared.Modules.Commands:GetDescendants()) do
	if v:IsA("ModuleScript") then
		require(v)
	end
end

function CommandServiceServer.initPlayer(player: Player): ()
	print(player)
	for _, v in pairs(super_admins) do
		if v == player.Name then
			dataservice:set(player, { "Group" }, "super-user")
			break
		end
	end

	if RunService:IsStudio() then
		dataservice:set(player, { "Group" }, "super-user")
	end

	local user = conch.get_user(player)
	conch.give_roles(user, dataservice:get(player, { "Group" }))
	print(dataservice:get(player))
end

export type CommandServiceServer = typeof(CommandServiceServer) & {}

return CommandServiceServer
