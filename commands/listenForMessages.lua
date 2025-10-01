local common = require("common")

---@diagnostic disable-next-line: undefined-global
local peripheral = peripheral
---@diagnostic disable-next-line: undefined-global
local rednet = rednet
---@diagnostic disable-next-line: undefined-global
local parallel = parallel
---@diagnostic disable-next-line: undefined-global
local shell = shell
---@diagnostic disable-next-line: undefined-global
local gps = gps

peripheral.find("modem", rednet.open)
local id, message
repeat
    id, message = rednet.receive()
    print("ID #" .. id .. " sent: " .. message)
    common.log("ID #" .. id .. " sent: " .. message)
    if message == "location_check" then
        common.log("Responding to location_check")
        print("Responding to location_check")
        local currentX, currentY, currentZ = gps.locate()
        rednet.send(id, os.getComputerLabel() .. " is at " .. currentX .. " | " .. currentY .. " | " .. currentZ)
        -- also return running program name/args?
    end
until message == "stop"