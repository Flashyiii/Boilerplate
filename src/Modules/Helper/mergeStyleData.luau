local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shallowMerge = require(ReplicatedStorage.Shared.Modules.Helper.shallowMerge)

return function(styleData, standOverrides)
	if not standOverrides then
		return styleData
	end

	local merged = {}
	for key, value in pairs(styleData) do
		if type(value) == "table" and standOverrides[key] then
			merged[key] = shallowMerge(value, standOverrides[key])
		else
			merged[key] = value
		end
	end

	for key, value in pairs(standOverrides) do
		if merged[key] == nil then
			merged[key] = value
		end
	end

	return merged
end
