local RepStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtraFolder = ReplicatedStorage:WaitForChild("Assets").Load
local ClientUtil = require(RepStorage.Shared.Modules.Game.ClientUtil)

local Preloader = {}

local function CheckId(Id: string): boolean
	if Id == "" or Id == "rbxassetid://0" or Id == "rbxassetid://" then
		return false
	end
	return true
end

local function GetAnimationsTable()
	if ClientUtil.Animations then
		return ClientUtil.Animations
	end

	return nil
end

function Preloader.LoadAnimations()
	local Animations = GetAnimationsTable()

	if not Animations then
		warn("Preloader: No Animations table found, skipping animations preload")
		return
	end

	local AnimationTable = {}

	-- Convert animation table to instances
	for name, id in pairs(Animations) do
		if not CheckId(id) then
			continue
		end
		local anim = Instance.new("Animation")
		anim.Name = name
		anim.AnimationId = id
		table.insert(AnimationTable, anim)
	end

	local TotalAnimations = #AnimationTable
	local LoadedAnimations = 0
	local FailedAnimations = 0
	local UseSecondRig = false

	-- Create first rig
	local Rig = ExtraFolder.R6:Clone()
	Rig.Parent = workspace.Effects

	print(`Preloader: Starting to load {TotalAnimations} animations...`)

	for i, Animation in AnimationTable do
		-- Switch to second rig after 255 animations to avoid limit
		if LoadedAnimations >= 255 and not UseSecondRig then
			UseSecondRig = true
			Rig:Destroy()
			Rig = ExtraFolder.R6:Clone()
			Rig.Parent = workspace.Effects
			print("Preloader: Switching to second rig (255+ animations)")
		end

		local TimeElapsed = 0
		local Track = nil
		local Success = false

		-- Try to load the animation
		task.spawn(function()
			local ok, result = pcall(function()
				return ClientUtil.LoadAnimation(Animation, Rig)
			end)
			if ok then
				Track = result
				Success = true
			else
				warn(`Preloader: Failed to load animation {Animation.Name}: {result}`)
			end
		end)

		-- Wait for load or timeout
		repeat
			TimeElapsed += task.wait()
		until Track or TimeElapsed >= 10

		if Success and Track then
			LoadedAnimations += 1

			-- Progress updates every 50 animations
			if LoadedAnimations % 50 == 0 then
				print(`Preloader: Loaded {LoadedAnimations}/{TotalAnimations} animations...`)
			end
		else
			FailedAnimations += 1
			if TimeElapsed >= 10 then
				warn(`Preloader: Timeout loading animation {Animation.Name}`)
			end
		end

		-- Small yield to prevent lag
		if i % 10 == 0 then
			task.wait()
		end
	end

	-- Cleanup rig
	Rig:Destroy()

	print(
		`Preloader: Finished loading animations - Success: {LoadedAnimations}/{TotalAnimations}, Failed: {FailedAnimations}`
	)
end

function Preloader.LoadExtra()
	local toPreload = { RepStorage }

	local Animations = GetAnimationsTable()

	if Animations then
		for _, id in pairs(Animations) do
			if CheckId(id) then
				table.insert(toPreload, id)
			end
		end
	end

	print(`Preloader: Starting to preload {#toPreload} assets...`)

	local ok, err = pcall(function()
		ContentProvider:PreloadAsync(toPreload, function(assetId, status) end)
	end)

	if not ok then
		warn("Preloader: PreloadAsync failed:", err)
	else
		print("Preloader: Asset preloading complete")
	end
end

local function LoadAll()
	local startTime = tick()
	print("=== Preloader: Starting ===")

	-- Load animations first (they take longer)
	Preloader.LoadAnimations()

	-- Then preload other assets
	Preloader.LoadExtra()

	local totalTime = math.floor((tick() - startTime) * 100) / 100
	print(`=== Preloader: Complete ({totalTime}s) ===`)
end

function Preloader.Start()
	task.spawn(LoadAll)
end

return Preloader
