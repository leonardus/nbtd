local bencoding = require("nbtd.bencoding")

return function(context, message, response)
	response.id = message.id
	context.client:write(bencoding.dictionary.encode(response) .. "\n")
end