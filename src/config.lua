local readfile = require("readfile")
local toml = require("toml")

local config = {}

config.init = function(configPath)
	config.parsed = toml.parse(readfile(configPath))
end

return config