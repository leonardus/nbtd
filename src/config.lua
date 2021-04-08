local toml = require("toml")

local config = {}

local function readfile(filename)
	local fd = io.open(filename, "r")
	local contents = fd:read("*a")
	fd:close()
	return contents
end

config.init = function(configPath)
	config.parsed = toml.parse(readfile(configPath))
end

return config