local base64 = require("base64")
local bencoding = require("nbtd.bencoding")
local json = require("JSON")
local lfs = require("lfs")
local readfile = require("nbtd.readfile")
local sha1 = require("sha1")

local torrents = {}
torrents.list = {}
torrents.dataDir = nil

local function readyState(t)
	local peerId = ""
	for _ = 1, 20 do
		peerId = peerId .. string.char(math.random(0,255))
	end

	t.state = {
		peerId = peerId,
	}
end

function torrents.init(dataDir)
	torrents.dataDir = dataDir
	for filename in lfs.dir(dataDir) do
		local fullPath = dataDir .. "/" .. filename
		local success, decodedContents = pcall(function()
			return json:decode(readfile(fullPath))
		end)
		if success then
			local binaryPieces = base64.decode(decodedContents.metainfo.info.pieces)
			decodedContents.metainfo.info.pieces = binaryPieces
			readyState(decodedContents)
			torrents.list[decodedContents.hexHash] = decodedContents
		end
	end
end

function torrents.write(t)
	local binaryPieces = t.metainfo.info.pieces
	t.metainfo.info.pieces = base64.encode(binaryPieces)
	local state = t.state
	t.state = nil

	local serializedData = json:encode(t)

	t.metainfo.info.pieces = binaryPieces
	t.state = state

	local fd = io.open(torrents.dataDir .. "/" .. t.hexHash, "w")
	fd:write(serializedData)
	fd:close()
end

function torrents.add(bencodedMetainfo)
	-- !! TODO: Validation, Checking for duplicates, ...
	local decodeSuccess, metainfo = pcall(function()
		return bencoding.dictionary.decode(bencodedMetainfo)
	end)
	if not decodeSuccess then
		error({reason = "decoding_failure"})
	end
	if (not metainfo.info) or (not metainfo.info.pieces) then
		error({reason = "incomplete_metainfo"})
	end
	local hexHash = sha1.sha1(bencoding.dictionary.encode(metainfo.info))

	local t = {
		metainfo = metainfo,
		hexHash = hexHash,
		version = 1, -- BitTorrent protocol version
	}

	readyState(t)
	if not pcall(function() torrents.write(t) end) then
		error({reason = "writing_failure"})
	end
	torrents.list[hexHash] = t

	return t
end

function torrents.remove(hexHash)
	if hexHash:sub(hexHash:find("[0-9A-Fa-f]+")) ~= hexHash then
		error({reason = "invalid_infohash"})
	end
	local fileExists = false
	for filename in lfs.dir(torrents.dataDir) do
		if filename == hexHash then
			fileExists = true
			local fullPath = torrents.dataDir .. "/" .. filename
			if not pcall(function() os.remove(fullPath) end) then
				error({reason = "file_removal_failure"})
			else
				torrents.list[hexHash] = nil
			end
		end
	end
	if not fileExists then
		error({reason = "file_not_exists"})
	end
end

return torrents