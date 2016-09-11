function table.Filter(tab, func)
	local c = 1
	for i = 1, #tab do
		if func(tab[i]) then
			tab[c] = tab[i]
			c = c + 1
		end
	end
	for i = c, #tab do
		tab[i] = nil
	end
	return tab
end

function table.FilterCopy(tab, func)
	local ret = {}
	for i = 1, #tab do
		if func(tab[i]) then
			ret[#ret + 1] = tab[i]
		end
	end
	return ret
end

function table.ConcatKeys(tab, concatenator)
	concatenator = concatenator or ''
	local str = ''
	
	for k, v in pairs(tab) do
		str = (str ~= '' and concatenator or str) .. k
	end
	
	return str
end