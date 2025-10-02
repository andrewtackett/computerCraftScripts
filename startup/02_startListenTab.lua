---@diagnostic disable-next-line: undefined-global
local multishell = multishell
---@diagnostic disable-next-line: undefined-field
local computerId = os.getComputerID()

local common = require("/common")

if computerId ~= 0 then
    print("Starting listenForMessages.lua")
    multishell.launch(_ENV, "listenForMessages.lua")
end