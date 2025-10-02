local version = { major=1, minor=0, patch=0 }
local common = require("common")
local args = {...}
local get_commands = args[1] == "true"

common.upsertAll(get_commands)

return {
    version = version,
}