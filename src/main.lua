local config = require("config")
local torrents = require("torrents")

config.init(arg[1] or "config.toml")
torrents.init(
	config.parsed.fs.data_dir
		or os.getenv("XDG_DATA_HOME") .. "/nbtd"
		or "/usr/share/nbtd"
)