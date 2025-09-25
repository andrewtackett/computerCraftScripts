local args = {...}
---@diagnostic disable-next-line: undefined-global
local turtle = turtle

local fuel_slot = args[1] or 1
turtle.select(tonumber(fuel_slot))
turtle.refuel()
print("Fuel: " .. turtle.getFuelLevel())

local version = { major=1, minor=0, patch=0 }
return {
    version = version
}