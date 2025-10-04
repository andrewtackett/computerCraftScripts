local common = require("common")

local args = {...}
local programName = args[1]

---@diagnostic disable-next-line: undefined-global
local peripheral = peripheral
---@diagnostic disable-next-line: undefined-global
local rednet = rednet
---@diagnostic disable-next-line: undefined-global
local parallel = parallel
---@diagnostic disable-next-line: undefined-global
local shell = shell


local keepGoing = true
local function runIt()
    common.log("Running " .. programName)
    while keepGoing do
        shell.run(args)
    end
end

local function listenForMessage()
    peripheral.find("modem", rednet.open)
    local id, message
    repeat
        id, message = rednet.receive()
        common.log("ID #" .. id .. " sent: " .. message)
    until message == "stop"
    keepGoing = false
end

parallel.waitForAll(runIt, listenForMessage)

local version = 1
return {
    version = version
}
