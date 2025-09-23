local version = { major=1, minor=0, patch=0 }
local common = require("common")
local args = {...}
local program_to_update = args[1]
local program_path = args[2] or program_to_update
print("Updating: " .. program_path .. " - " .. program_to_update)

common.upsertProgram(program_path, program_to_update)

-- pastebin get QgA4Vxi2 common.lua
-- wget https://raw.githubusercontent.com/SquidDev-CC/mbs/master/mbs.lua mbs.lua

-- download from pastebin to local
-- list latest robot version
-- send as version +1
-- file alias program to latest version on robots?
-- figure out startup files not working

-- what happens if you update running software?
-- - should mining program reboot itself?
-- - should all software have a "listen for updates" loop?
-- - figure out using libraries

return {
    version = version,
}