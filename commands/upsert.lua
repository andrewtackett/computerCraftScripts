local version = { major=1, minor=0, patch=0 }
local common = require("common")
local args = {...}
local program_to_update = args[1]
local program_path = args[2] or program_to_update
print("Updating: " .. program_path .. " - " .. program_to_update)

common.upsertFile(program_path, program_to_update)

-- pastebin get QgA4Vxi2 common.lua
-- wget https://raw.githubusercontent.com/SquidDev-CC/mbs/master/mbs.lua mbs.lua
-- wget https://raw.githubusercontent.com/andrewtackett/computerCraftScripts/main/common.lua common.lua

return {
    version = version,
}