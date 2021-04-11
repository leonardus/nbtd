return function(str)
	return str:gsub(".", function(b)
		return "%" .. string.format("%02x", string.byte(b))
	end)
end