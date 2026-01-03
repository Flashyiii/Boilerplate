local function Deep(_table: { any }, seen: table?): { any }
	seen = seen or {}
	if seen[_table] then
		return seen[_table]
	end

	local Copy: { any } = {}
	seen[_table] = Copy -- Track this table to avoid circular references

	for Index, Data in pairs(_table) do
		Copy[Index] = if typeof(Data) == "table" then Deep(Data, seen) else Data
	end
	return Copy
end

return function(
	Table0: { any },
	Table1: { any },
	Favors: boolean?
): { any } -- Table0: table, Table1: table, Favors: true or false (true favors keeping non-table values from Table0, false favors Table1 (false is default))
	Favors = if Favors == nil then false else Favors
	local Copy: { any } = Deep(Table0) -- No need to worry about your initial values. This also deepcopied any Table0 tables that would be missed.
	for Index, Data in pairs(Table1) do
		local T0Value = Table0[Index]
		Copy[Index] = if T0Value == nil
			then -- If Table0 doesn't have this value,
				if typeof(Data) == "table"
					then -- And Table1 does and is a table,
						Deep(Data) -- We need to deepcopy and set it.
					else Data -- Otherwise, we set it to the current value of Table1
			else -- Instead, if Table0 does have that index then:
				if typeof(T0Value) == "table"
					then -- If Table0 it's a table value,
						if type(Data) == "table"
							then -- And Table1 also has a table value here,
								Reconcile(T0Value, Data, Favors) -- We need to Reconcile them again.
							else -- Otherwise, if Table1's value is NOT a Table, we need to:
								if Favors
									then -- Check our favoring, if true we:
										T0Value -- Use the value from Table0.
									else -- Otherwise, when favor is false (or default)
										Data -- We use the value from Table1.
					else -- If T0Value is not nil and T0Value is ALSO not a table, we again:
						if Favors
							then -- Check our favoring, if true we:
								T0Value -- Use the value from Table0.
							else -- Otherwise, when favor is false (or default)
								Data -- We use the value from Table1.
	end
	return Copy
end :: (Table0: { any }, Table1: { any }, Favors: boolean?) -> { any }
