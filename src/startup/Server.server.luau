local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(game:GetService("ReplicatedStorage").Packages.dataservice).server
local DataTemplate = require(ReplicatedStorage.Shared.Modules.Core.DataTemplate)

local Services = {}

local function HandlePlayer(player: Player): ()
	task.spawn(function()
		for _, service in pairs(Services) do
			if type(service.initPlayer) == "function" then
				task.spawn(function()
					local success, err = pcall(function()
						service.initPlayer(player)
					end)
					if not success then
						warn(`[initPlayer] Failed in {service}: {err}`)
					end
				end)
			end
		end
	end)
end

local function init(): ()
	for _, moduleScript in ipairs(ServerScriptService.Services:GetDescendants()) do
		if moduleScript:IsA("ModuleScript") and string.find(moduleScript.Name, "Server") then
			task.spawn(function()
				local ok, service = pcall(require, moduleScript)
				if not ok then
					warn(`[ServiceLoader] Failed to load {moduleScript:GetFullName()}: {service}`)
					return
				end

				if service.init then
					if type(service.init) == "function" then
						local success, err = pcall(service.init, service)
						if not success then
							warn(`[ServiceLoader] init() error in {moduleScript.Name}: {err}`)
						end
					end
				end

				table.insert(Services, service)
			end)
		end
	end
end

init()

_G.SaveData = false

local ProfileStoreIndex = "Production"

if game:GetService("RunService"):IsStudio() then
	ProfileStoreIndex = "Development"
end

DataService:init({
	template = DataTemplate,
	profileStoreIndex = ProfileStoreIndex,
	useMock = false,
	resetData = _G.SaveData,
})

function DataService:onPlayerInit(player: Player, data): ()
	local Information = data.Information

	if Information.FirstJoined == 0 then
		Information.FirstJoined = os.time()
	end

	Information.LastJoined = os.time()
	Information.TimesSeen += 1

	player:SetAttribute("ProfileLoaded", true)
	HandlePlayer(player)
end

function DataService:onPlayerRemoving(_: Player, data): ()
	local Information = data.Information
	Information.PlayTime += os.time() - Information.LastJoined
end
