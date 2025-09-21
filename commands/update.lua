print("Software Updater v1.0")
local args = {...}
if #args < 3 then
    print("Usage: update <program_name> <pastebin_id> <turtle|computer id>")
    return
end
local version = { major=0, minor=0, patch=0 }

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