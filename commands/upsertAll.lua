local common = require("common")
local args = {...}
local getCommands = args[1] == "true"
local getStartupFiles = args[2] == "true"

common.upsertAll(getCommands, getStartupFiles)

local version = 1
return {
    version = version,
}
