local version = { major=1, minor=0, patch=0 }
local common = require("common")
local args = {...}
local get_commands = args[1] or false

common.updateAll(get_commands)

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