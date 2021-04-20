local sendresponse = require("nbtd.sendresponse")
local torrents = require("nbtd.torrents")

return function(context, message)
	if (not message.args) or (not message.args.infohash) then
		return sendresponse(context, message, {
			success = 0,
			error = "not_enough_args",
		})
	end

	local removeSuccess, err = pcall(function()
		return torrents.remove(message.args.infohash)
	end)
	if not removeSuccess then
		return sendresponse(context, message, {
			success = 0,
			error = err.reason,
		})
	end

	return sendresponse(context, message, {success = 1})
end