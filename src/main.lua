local config = require("nbtd.config")
local torrents = require("nbtd.torrents")

-- !! TODO: This is not random enough and will make peer_id collisions possible.
-- (Clients started within the same second will be generating identical peer_ids.)
-- Find a better number to use as a random seed.
math.randomseed(os.time())

config.init(arg[1] or "/etc/nbtd/ntbd.toml")
torrents.init(
	config.parsed.fs.data_dir
		or os.getenv("XDG_DATA_HOME") .. "/nbtd"
		or "/usr/share/nbtd"
)