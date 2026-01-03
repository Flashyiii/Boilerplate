local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dataservice = require(ReplicatedStorage.Packages.dataservice).client
dataservice:init()

local refx = require(ReplicatedStorage.Packages.refx)
local Preloader = require(ReplicatedStorage.Shared.Modules.Game.Preloader)
Preloader.Start()

local WCS = require(ReplicatedStorage.Packages.wcs)
local Client = WCS.CreateClient()
Client:RegisterDirectory(ReplicatedStorage.Shared.WCS)

Client:Start()

refx.Register(game.ReplicatedStorage.Shared.Visuals)
refx.Start()

local Services = {}
local function initclient(): ()
	for _, moduleScript in ipairs(ReplicatedStorage.Shared.Services:GetDescendants()) do
		if moduleScript:IsA("ModuleScript") and string.find(moduleScript.Name, "Client") then
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

initclient()
