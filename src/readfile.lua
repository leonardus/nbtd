return function(filename)
	local fd = io.open(filename, "r")
	local contents = fd:read("*a")
	fd:close()
	return contents
end