local base64 = require("base64")
local bencoding = require("bencoding")
local cjson = require("cjson")
local lfs = require("lfs")
local readfile = require("readfile")
local sha1 = require("sha1")

local torrents = {}
torrents.list = {}
torrents.dataDir = nil

function torrents.init(dataDir)
	torrents.dataDir = dataDir
	for filename in lfs.dir(dataDir) do
		local fullPath = dataDir .. "/" .. filename
		local success, decodedContents = pcall(function()
			return cjson.decode(readfile(fullPath))
		end)
		if success then
			local binaryPieces = base64.decode(decodedContents.metainfo.info.pieces)
			decodedContents.metainfo.info.pieces = binaryPieces
			decodedContents.state = {}
			torrents.list[decodedContents.hexHash] = decodedContents
		end
	end
end

function torrents.write(t)
	local binaryPieces = t.metainfo.info.pieces
	t.metainfo.info.pieces = base64.encode(binaryPieces)
	local state = t.state
	t.state = nil

	local serializedData = cjson.encode(t)

	t.metainfo.info.pieces = binaryPieces
	t.state = state

	local fd = io.open(torrents.dataDir .. "/" .. t.hexHash, "w")
	fd:write(serializedData)
	fd:close()
end

function torrents.add(metainfo)
	-- !! TODO: Validation, Checking for duplicates, ...
	metainfo = bencoding.dictionary.decode(metainfo)
	local hexHash = sha1.sha1(metainfo.info.pieces)

	local t = {
		metainfo = metainfo,
		hexHash = hexHash,
		version = 1, -- BitTorrent protocol version
		state = {},
	}

	torrents.list[hexHash] = t
	torrents.write(t)

	return t
end

function torrents.remove(hexHash)
	for filename in lfs.dir(torrents.dataDir) do
		if filename == hexHash then
			local fullPath = torrents.dataDir .. "/" .. filename
			os.remove(fullPath)
		end
	end
	torrents.list[hexHash] = nil
end

return torrents