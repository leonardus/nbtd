local config = require("nbtd.config")
local cqueues = require("cqueues")
local torrents = require("nbtd.torrents")

math.randomseed(cqueues.monotime()*10000000)

config.init(arg[1] or "/etc/nbtd/ntbd.toml")
torrents.init(
	config.parsed.fs.data_dir
		or os.getenv("XDG_DATA_HOME") .. "/nbtd"
		or "/usr/share/nbtd"
)