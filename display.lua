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
    term.setTextColor(common.default_color)
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
end

local function main()
    peripheral.find("modem", rednet.open)
    local id, data
    repeat
        id, data = rednet.receive()
        local meta, message = table.unpack(common.split(data, "|"))
        common.log(id .. ":" .. data, "debug")
        common.log("ID #" .. id .. " sent: " .. message)
        if meta == "clearMonitor" then
            common.log("Message Log:")
            resetText()
            rednet.send(id, "clearedMonitor")
        elseif meta == "success" then
            common.log(message, "success")
        elseif meta == "warning" then
            common.log(message, "warning")
        elseif meta == "error" then
            term.setTextColor(common.error_color)
            print(message)
            term.setTextColor(common.default_color)
        end
    until meta == "stop"
end

main()

local version = 2
return {
    version = version
}
