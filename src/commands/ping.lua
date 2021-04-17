local sendresponse = require("nbtd.sendresponse")

return function(context, command)
	local response = {
		success = 1,
		args = {
			pong = os.time(),
		},
	}
	sendresponse(context, command, response)
end