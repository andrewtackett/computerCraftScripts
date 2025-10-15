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

local function logWithColor(msg, color)
    term.setTextColor(color)
    print(msg)
    term.setTextColor(common.default_color)
end

local function main()
    peripheral.find("modem", rednet.open)
    local id, data
    repeat
        id, data = rednet.receive()
        local meta, message = table.unpack(common.split(data, "|"))
        common.log(id .. ":" .. data, "debug")
        local formattedMessage = "#" .. id .. " - " .. message
        if meta == "clearMonitor" then
            resetText()
            common.log("Message Log:")
            rednet.send(id, "clearedMonitor")
        elseif meta == "success" then
            logWithColor(formattedMessage, common.success_color)
        elseif meta == "warning" then
            logWithColor(formattedMessage, common.warning_color)
        elseif meta == "error" then
            logWithColor(formattedMessage, common.error_color)
        else
            common.log(formattedMessage)
        end
    until meta == "stop"
end

main()

local version = 3
return {
    version = version
}
