local bencoding = {}

bencoding.string = {}
function bencoding.string.encode(str)
	return tostring(str:len()) .. ":" .. str
end
function bencoding.string.decode(str)
	local delimiter = str:find(":")
	assert(delimiter, "Malformed string (no delimiter)")
	local len = tonumber(str:sub(1, delimiter - 1))
	assert(len, "Malformed string (illegal length)")
	local bdecodedStr = str:sub(delimiter + 1, delimiter+len)
	local size = bdecodedStr:len() + delimiter
	return bdecodedStr, size
end

bencoding.integer = {}
function bencoding.integer.encode(int)
	return "i" .. tostring(int) .. "e"
end
function bencoding.integer.decode(int)
	local marker = int:find("e")
	assert(marker, "Malformed integer (no end marker)")
	local hasLeadingZero = (int:sub(2, 2) == "0" and marker ~= 3) or int:sub(2, 3) == "-0"
	assert(not hasLeadingZero, "Malformed integer (leading zero)")
	local typeconv = tonumber(int:sub(2, marker-1))
	assert(typeconv, "Malformed integer (failed to convert string to number)")
	return typeconv
end

local function encodeListOrDictionary(data, which)
	local function tblIsList(tbl)
		local mt = getmetatable(tbl)
		if mt and mt.isList then
			return mt.isList
		end
		for k in pairs(tbl) do
			if type(k) == "string" then return false end
		end
		return true
	end
	local isList
	if which then
		isList = (which == "l") and true or false
	else
		isList = tblIsList(data)
	end

	local sortedKeys = {}
	for i_k in pairs(data) do table.insert(sortedKeys, i_k) end
	table.sort(sortedKeys)

	local bencodedStr = isList and "l" or "d"
	for _, i_k in ipairs(sortedKeys) do
		local v = data[i_k]
		local encodedItem
		if type(v) == "string" then
			encodedItem = bencoding.string.encode(v)
		elseif type(v) == "number" then
			encodedItem = bencoding.integer.encode(v)
		elseif type(v) == "table" then
			encodedItem = encodeListOrDictionary(v)
		end
		if not isList then
			bencodedStr = bencodedStr .. bencoding.string.encode(i_k)
		end
		bencodedStr = bencodedStr .. encodedItem
	end
	return bencodedStr .. "e"
end

local function decodeListOrDictionary(data)
	local isList = data:sub(1, 1) == "l"
	local key, readingKey
	readingKey = not isList
	local keyOrder = {}
	local bdecodedData = {}
	local pos = 2
	local btype
	while data:sub(pos, pos) ~= "e" do
		btype = data:sub(pos, pos)
		assert(btype ~= "", "Malformed list or dictionary (no end marker)")
		local size
		if readingKey and tonumber(btype) then
			key, size = bencoding.string.decode(data:sub(pos))
			table.insert(keyOrder, key)
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
			elseif btype == "l" or btype == "d" then
				value, size = decodeListOrDictionary(data:sub(pos))
				pos = pos + size
			else
				error("Unknown bencoding type: `" .. btype .. "`")
			end
			if isList then
				table.insert(bdecodedData, value)
			else
				bdecodedData[key] = value
				readingKey = true
			end
		end
	end

	if not isList then
		local function shallowCopy(t)
			local t_2 = {}
			for k, v in ipairs(t) do
				t_2[k] = v
			end
			return t_2
		end
		local sortedKeys = shallowCopy(keyOrder)
		table.sort(sortedKeys)
		for i, sortedKey in ipairs(sortedKeys) do
			assert(keyOrder[i] == sortedKey, "Malformed dictionary (keys not sorted)")
		end
	end

	setmetatable(bdecodedData, {isList = isList})

	return bdecodedData, pos
end

bencoding.list = {}
bencoding.list.encode = function(data)
	return encodeListOrDictionary(data, "l")
end
bencoding.list.decode = decodeListOrDictionary
bencoding.list.new = function()
	local t = {}
	setmetatable(t, {isList = true})
	return t
end

bencoding.dictionary = {}
bencoding.dictionary.encode = function(data)
	return encodeListOrDictionary(data, "d")
end
bencoding.dictionary.decode = decodeListOrDictionary
bencoding.dictionary.new = function()
	local t = {}
	setmetatable(t, {isList = false})
	return t
end

return bencoding