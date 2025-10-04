local common = require("common")
local args = {...}
local numberOfResponsesToWaitFor = tonumber(args[1]) or 1

---@diagnostic disable-next-line: undefined-global
local peripheral = peripheral
---@diagnostic disable-next-line: undefined-global
local rednet = rednet

peripheral.find("modem", rednet.open)
local id, message
local numberOfResponses = 0
-- local timeout = 30 -- seconds
-- local startTime = os.clock()
rednet.broadcast("location_check")
repeat
    id, message = rednet.receive()
    common.log("ID #" .. id .. " sent: " .. message)
    numberOfResponses = numberOfResponses + 1
until numberOfResponses == numberOfResponsesToWaitFor
--or os.clock() - startTime > timeout

local version = 1
return {
    version = version
}
