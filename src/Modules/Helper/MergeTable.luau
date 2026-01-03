return function(...)
	local newTable = {}
	for _, t in pairs({ ... }) do
		for k, v in pairs(t) do
			if newTable[k] == nil then
				newTable[k] = v
			end
		end
	end
	return newTable
end
