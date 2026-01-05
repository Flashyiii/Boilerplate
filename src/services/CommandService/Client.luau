local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandServiceClient = {}

local conch = require(ReplicatedStorage.Packages.conch)
local ui = require(ReplicatedStorage.Packages.conch_ui)

function CommandServiceClient.init(self: CommandServiceClient)
	conch.initiate_default_lifecycle()
	ui.bind_to(Enum.KeyCode.F4)
end

export type CommandServiceClient = typeof(CommandServiceClient) & {}

return CommandServiceClient
