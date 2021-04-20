local sendresponse = require("nbtd.sendresponse")
local torrents = require("nbtd.torrents")
local base64 = require("base64")

return function(context, message)
	if (not message.args) or (not message.args.metainfo) then
		return sendresponse(context, message, {
			success = 0,
			error = "not_enough_args",
		})
	end

	local addSuccess, err = pcall(function()
		return torrents.add(base64.decode(message.args.metainfo))
	end)
	if not addSuccess then
		return sendresponse(context, message, {
			success = 0,
			error = err.reason,
		})
	end

	return sendresponse(context, message, {success = 1})
end