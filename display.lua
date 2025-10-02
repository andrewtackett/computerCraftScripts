--- Monitor Utility Functions

local common = require("common")

---@diagnostic disable-next-line: undefined-global
local term = term
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
---@diagnostic disable-next-line: undefined-global
local colors = colors

local function resetText()
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
end

local function main()
    peripheral.find("modem", rednet.open)
    local id, data
    repeat
        id, data = rednet.receive()
        local command, message = table.unpack(common.split(data, "|"))
        common.log(id .. ":" .. data, "debug")
        common.log("ID #" .. id .. " sent: " .. message)
        if command == "clearMonitor" then
            common.log("Message Log:")
            resetText()
            rednet.send(id, "clearedMonitor")
        end
    until command == "stop"
end

main()