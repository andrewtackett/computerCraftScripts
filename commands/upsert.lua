local common = require("common")
local args = {...}
local programToUpdate = args[1]
local programPath = args[2] or programToUpdate
print("Updating: " .. programPath .. " - " .. programToUpdate)

common.upsertFile(programPath, programToUpdate)

-- pastebin get QgA4Vxi2 common.lua
-- wget https://raw.githubusercontent.com/SquidDev-CC/mbs/master/mbs.lua mbs.lua
-- wget https://raw.githubusercontent.com/andrewtackett/computerCraftScripts/main/common.lua common.lua

local version = 1
return {
    version = version,
}
