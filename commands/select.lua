local args = {...}
local slot_to_select = args[1] or 1
---@diagnostic disable-next-line: undefined-global
turtle.select(tonumber(slot_to_select))

local version = 1
return {
    version = version
}
