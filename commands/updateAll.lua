local version = { major=1, minor=0, patch=0 }
local common = require("common")
local args = {...}
local get_commands = args[1] == "true" or false

common.updateAll(get_commands)

-- pastebin get QgA4Vxi2 common.lua

return {
    version = version,
}