package = "nbtd"
version = "dev-0"
description = {
	license = "GPL-3",
	homepage = "https://github.com/leonardus/nbtd",
	maintainer = "leonardus <leonardus@leonardus.me>",
}
dependencies = {
	"lua >= 5.1",
	"lbase64 >= 20120807",
	"sha1 >= 0.6",
	"luafilesystem >= 1.8",
	"lua-cjson >= 2.1",
	"lua-toml >= 2.0",
	"cqueues >= 20200603.51",
	"http 0.4"
}
source = {
	url = "git+https://github.com/leonardus/nbtd.git"
}
build = {
	type = "builtin",
	modules = {
		["nbtd"] = "src/main.lua",
		["nbtd.bencoding"] = "src/bencoding.lua",
		["nbtd.config"] = "src/config.lua",
		["nbtd.readfile"] = "src/readfile.lua",
		["nbtd.torrents"] = "src/torrents.lua",
		["nbtd.uriencoding"] = "src/uriencoding.lua"
	},
	install = {
		bin = {
			nbtd = "bin/nbtd.lua"
		}
	}
}
