local sendresponse = require("nbtd.sendresponse")
local torrents = require("nbtd.torrents")

return function(context, message)
	if (not message.args) or (not message.args.metainfo) then
		return sendresponse(context, message, {
			success = 0,
			error = "not_enough_args",
		})
	end

	local addSuccess, err = pcall(function()
		return torrents.add(message.args.metainfo)
	end)
	if not addSuccess then
		return sendresponse(context, message, {
			success = 0,
			error = err.reason,
		})
	end

	return sendresponse(context, message, {success = 1})
end