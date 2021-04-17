local bencoding = require("nbtd.bencoding")
local config = require("nbtd.config")
local cqueues = require("cqueues")
local socket = require("cqueues.socket")
local torrents = require("nbtd.torrents")

math.randomseed(cqueues.monotime()*10000000)

config.init(arg[1] or "/etc/nbtd/ntbd.toml")
torrents.init(
	config.parsed.fs.data_dir
		or os.getenv("XDG_DATA_HOME") .. "/nbtd"
		or "/usr/share/nbtd"
)

local controller = cqueues.new()

local function main()
	local host, port = config.parsed.net.addr, config.parsed.net.port
	local server = socket.listen(host, port)
	print("[nbtd] Listening on " .. host .. ":" .. tostring(port))
	while true do
		local client = server:accept()
		client:setmaxline(2^20) -- 1MiB
		controller:wrap(function()
			while true do
				if socket.type(client) == "closed socket" then
					break
				end
				local line = client:read("*l")
				if line == nil then client:close() break end

				local decodeSuccess, decoded = pcall(function()
					return bencoding.dictionary.decode(line)
				end)
				if decodeSuccess and decoded.command then
					local command = decoded.command:lower()
				end
			end
		end)
	end
end

controller:wrap(main)
assert(controller:loop())