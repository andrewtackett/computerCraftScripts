---@diagnostic disable-next-line: undefined-global
local gps = gps
---@diagnostic disable-next-line: undefined-global
local shell = shell

shell.run("alias", "c", "/.mbs/bin/clear.lua")

local x,y,z = gps.locate()
if not x then
    x, y, z = "?", "?", "?"
end

---@diagnostic disable-next-line: undefined-field
print("Starting turtle #" .. os.getComputerID() .. "|" .. os.getComputerLabel() .. ", at " .. x .. "|" .. y .. "|" .. z)

local version = 2
return {
    version = version
}
