return function(target, source)
	local result = table.clone(target)
	for key, value in pairs(source) do
		result[key] = value
	end
	return result
end
