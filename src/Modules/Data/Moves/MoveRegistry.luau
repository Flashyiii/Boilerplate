-- ReplicatedStorage/Shared/Modules/Data/Moves/MoveRegistry.lua
local MoveRegistry = {}

local MoveSourcesFolder = script.Parent.Sources
local MovesetsFolder = script.Parent.Movesets

local cache = {}

local function isPlainData(tbl)
	if type(tbl) ~= "table" then
		return false
	end
	if getmetatable(tbl) then
		return false
	end
	if type(rawget(tbl, "Start")) == "function" or type(rawget(tbl, "OnStartServer")) == "function" then
		return false
	end
	return true
end

local function shallowClone(tbl)
	return table.clone(tbl)
end

local function deepMerge(target, source)
	for key, value in pairs(source) do
		if isPlainData(value) and isPlainData(target[key]) then
			deepMerge(target[key], value)
		else
			target[key] = value
		end
	end
	return target
end

local function loadSource(path)
	local current = MoveSourcesFolder

	for part in string.gmatch(path, "[^/]+") do
		current = current:FindFirstChild(part)
		if not current then
			error("[MoveRegistry] Missing source: " .. path)
		end
	end

	return require(current)
end

function MoveRegistry.get(movesetName: string)
	if cache[movesetName] then
		return cache[movesetName]
	end

	local movesetModule = MovesetsFolder:FindFirstChild(movesetName)
	if not movesetModule then
		warn("[MoveRegistry] Unknown moveset:", movesetName)
		return {}
	end

	local merged = {}
	cache[movesetName] = merged

	local sources = require(movesetModule)

	for _, sourcePath in ipairs(sources) do
		local sourceTable = loadSource(sourcePath)
		for moveName, moveData in pairs(sourceTable) do
			if merged[moveName] then
				deepMerge(merged[moveName], moveData)
			else
				merged[moveName] = shallowClone(moveData)
			end
		end
	end

	print(merged)

	return merged
end

return MoveRegistry
