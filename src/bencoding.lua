local bencoding = {}

bencoding.string = {}
function bencoding.string.encode(str)
	return tostring(str:len()) .. ":" .. str
end
function bencoding.string.decode(str)
	local delimiter = str:find(":")
	if not delimiter then
		error("Malformed string (no delimiter)")
	end
	local len = tonumber(str:sub(1, delimiter - 1))
	if not len then
		error("Malformed string (illegal length)")
	end
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
	if not marker then
		error("Malformed integer (no end marker)")
	end
	if (int:sub(2, 2) == "0" and marker ~= 3) or int:sub(2, 3) == "-0" then
		error("Malformed integer (leading zero)")
	end
	local typeconv = tonumber(int:sub(2, marker-1))
	if not typeconv then
		error("Malformed integer (failed to convert to string)")
	end
	return typeconv
end

local function encodeListOrDictionary(data)
	local function tblIsList(tbl)
		for k, v in pairs(tbl) do
			if type(k) == "string" then return false end
		end
		return true
	end
	local isList = tblIsList(data)

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
		if btype == "" then
			error("Malformed list or dictionary (no end marker)")
		end
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
		for i, key in ipairs(sortedKeys) do
			if keyOrder[i] ~= key then
				error("Malformed dictionary (keys not sorted)")
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