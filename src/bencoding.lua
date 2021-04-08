local bencoding = {}

-- !! TODO: Handle malformed encodings

bencoding.string = {}
function bencoding.string.encode(str)
	return tostring(str:len()) .. ":" .. str
end
function bencoding.string.decode(str)
	local delimiter = str:find(":")
	local len = tonumber(str:sub(1, delimiter - 1))
	local bdecodedStr = str:sub(delimiter + 1, delimiter+len)
	local size = bdecodedStr:len() + delimiter
	return bdecodedStr, size
end

bencoding.integer = {}
function bencoding.integer.encode(int)
	return "i" .. tostring(int) .. "e"
end
function bencoding.integer.decode(int)
	return tonumber(int:sub(2, int:find("e")-1))
end

local function encodeListOrDictionary(data)
	local function tblIsList(tbl)
		for k, v in pairs(tbl) do
			if type(k) == "string" then return false end
		end
		return true
	end
	local isList = tblIsList(data)
	local bencodedStr = isList and "l" or "d"
	for k, v in pairs(data) do
		local encodedItem
		if type(v) == "string" then
			encodedItem = bencoding.string.encode(v)
		elseif type(v) == "number" then
			encodedItem = bencoding.integer.encode(v)
		elseif (not isList) and type(v) == "table" then
			encodedItem = encodeListOrDictionary(v)
		end
		if not isList then
			bencodedStr = bencodedStr .. bencoding.string.encode(k)
		end
		bencodedStr = bencodedStr .. encodedItem
	end
	return bencodedStr .. "e"
end

local function decodeListOrDictionary(data)
	local bdecodedData = {}
	local pos = 2
	local btype
	local isList = data:sub(1, 1) == "l"
	local key, readingKey
	readingKey = not isList
	while data:sub(pos, pos) ~= "e" do
		btype = data:sub(pos, pos)
		if btype == "" then break end
		if readingKey and tonumber(btype) then
			key, size = bencoding.string.decode(data:sub(pos))
			pos = pos + size
			readingKey = false
		else
			local value
			if tonumber(btype) then -- string type encoding
				value, size = bencoding.string.decode(data:sub(pos))
				pos = pos + size
			elseif btype == "i" then
				value = bencoding.integer.decode(data:sub(pos))
				pos = data:find("e", pos)+1
			elseif (not isList) and btype == "l" then
				value, size = decodeListOrDictionary(data:sub(pos))
				pos = pos + size
			end
			if isList then
				table.insert(bdecodedData, value)
			else
				bdecodedData[key] = value
				readingKey = true
			end
		end
	end
	return bdecodedData, pos
end

bencoding.list = {}
bencoding.list.encode = encodeListOrDictionary
bencoding.list.decode = decodeListOrDictionary

bencoding.dictionary = {}
bencoding.dictionary.encode = encodeListOrDictionary
bencoding.dictionary.decode = decodeListOrDictionary

return bencoding