local common = require("/common")

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

local function sendReplyCCmain(replyId, msg)
    -- Main is ID:0
    rednet.send(0, msg)
    rednet.send(replyId, msg)
end

peripheral.find("modem", rednet.open)
local id, message
repeat
    id, message = rednet.receive()
    common.log("ID #" .. id .. " sent: " .. message)
    if message == "location_check" then
        common.log("Responding to location_check")
        local currentX, currentY, currentZ = gps.locate()
        sendReplyCCmain(id, os.getComputerLabel() .. " is at " .. currentX .. " | " .. currentY .. " | " .. currentZ)
        -- also return running program name/args?
    end
until message == "stop"

local version = 2
return {
    version = version
}
