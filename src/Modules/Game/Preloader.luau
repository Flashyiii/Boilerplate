local RepStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExtraFolder = ReplicatedStorage:WaitForChild("Assets").Load

local ClientUtil = require(RepStorage.Shared.Modules.Game.ClientUtil)

local Preloader = {}

local function CheckId(Id: string): boolean
	if Id == "" or Id == "rbxassetid://0" then
		return false
	end
	return true
end

function Preloader.LoadAnimations()
	local AnimationTable = {}
	do
		local Animations = nil
		do
			local shared = RepStorage:FindFirstChild("Shared")
			if shared then
				local modules = shared:FindFirstChild("Modules")
				if modules then
					local assets = modules:FindFirstChild("Assets")
					if assets then
						local animModule = assets:FindFirstChild("Animations")
						if animModule and animModule:IsA("ModuleScript") then
							local ok, res = pcall(require, animModule)
							if ok and type(res) == "table" then
								Animations = res
							end
						end
					end
				end
			end
		end
		if not Animations then
			print("Preloader: No Animations table found, skipping animations preload")
			return
		end
		for name, id in pairs(Animations) do
			if not CheckId(id) then
				continue
			end
			local anim = Instance.new("Animation")
			anim.Name = name
			anim.AnimationId = id
			table.insert(AnimationTable, anim)
		end
	end

	local TotalAnimations = #AnimationTable
	local LoadedAnimations = 0
	local UseSecondRig = false

	local Rig = ExtraFolder.R6:Clone()
	Rig.Parent = workspace.Effects

	for _, Animation in AnimationTable do
		if LoadedAnimations >= 255 and not UseSecondRig then
			UseSecondRig = true

			Rig:Destroy()
			Rig = ExtraFolder.R6:Clone()
			Rig.Parent = workspace.Effects
		end

		local TimeElapsed = 0
		local Track
		task.spawn(function()
			Track = ClientUtil.LoadAnimation(Animation, Rig)
		end)

		repeat
			TimeElapsed += task.wait()
		until Track or TimeElapsed >= 10

		LoadedAnimations += 1

		if TimeElapsed >= 10 then
			continue
		end
	end

	print(`Loaded ({LoadedAnimations}/{TotalAnimations}) animations`)
end
function Preloader.LoadExtra()
	local toPreload = { RepStorage }

	local shared = RepStorage:FindFirstChild("Shared")
	local modules = shared and shared:FindFirstChild("Modules")
	local assets = modules and modules:FindFirstChild("Assets")
	local animModule = assets and assets:FindFirstChild("Animations")

	if animModule and animModule:IsA("ModuleScript") then
		local ok, res = pcall(require, animModule)
		if ok and type(res) == "table" then
			for _, id in pairs(res) do
				if CheckId(id) then
					table.insert(toPreload, id)
				end
			end
		end
	end

	local ok, err = pcall(function()
		ContentProvider:PreloadAsync(toPreload)
	end)
	if not ok then
		warn("PreloadAsync failed:", err)
	end
end
local function LoadAll()
	Preloader.LoadAnimations()
	Preloader.LoadExtra()
end

function Preloader.Start()
	task.spawn(LoadAll)
end

return Preloader
