-- ComputerCraft Turtle Script to dig a tunnel with optional torch placement
-- and inventory management

-- Expected start with Turtle facing forward along the tunnel path
-- with a chest/inventory to the right of it for unloading items
local version = { major=1, minor=0, patch=0 }
local common = require("common")
local turtleCommon = require("turtleCommon")

-- Ensure global APIs are recognized by linters
---@diagnostic disable-next-line: undefined-global
local turtle = turtle
---@diagnostic disable-next-line: undefined-global
local sleep = sleep
---@diagnostic disable-next-line: undefined-global
local gps = gps

local args = {...}
if #args < 1 then
    print("Usage: tunnel <lengthOfTunnel> [placeTorches]")
    return
end
local config = common.readConfigFile()
local lengthOfTunnel = args[1]
local placeTorches = args[2] == "true" or false

local storageX = tonumber(config["storageX"])
local storageY = tonumber(config["storageY"])
local storageZ = tonumber(config["storageZ"])

local startX, startY, startZ = gps.locate()
print("Debugging, start coords: ", startX, startY, startZ)

local torch_slot = 16
local off_limits_slots = { [16] = true }
local distance_between_torches = 6
local tunnel_height = 8

-- TODO
-- local items_to_compact_tags = "allthecompressed:1x"
-- local function compactItems()
--     log("Compacting items", "info")
-- end

local function ensureInventorySpace()
    local function checkInventory()
        for i=1,16 do
            if turtle.getItemCount(i) == 0 then
                return true
            end
        end
        return false
    end
    if not checkInventory() then
        common.log("No inventory space left!", "warning")
        turtleCommon.dumpInventory(torch_slot, off_limits_slots, true)
        common.waitForFix(checkInventory, 30)
    end
end

-- TODO: make this fetch from chest/dump inventory
local function ensureTorches()
    local function checkTorches()
        turtle.select(torch_slot)
        return turtle.getItemCount(torch_slot) > 0
    end
    if not checkTorches() then
        common.log("Out of torches!", "error")
        common.waitForFix(checkTorches, 30)
    end
end

local function getMaxOffset()
    local currentX, currentY, currentZ = gps.locate()
    local xOffset = storageX - currentX
    local yOffset = storageY - currentY
    local zOffset = storageZ - currentZ
    local offsetTable = { xOffset, yOffset, zOffset }
    table.sort(offsetTable)
    local maxOffset = offsetTable[#offsetTable]
    return maxOffset
end

local function placeTorch()
    if placeTorches then
        ensureTorches()
        local torchOffset = getMaxOffset()
        -- Add one so we don't put a torch where we're starting blocking storage
        if (torchOffset % distance_between_torches) + 1 == 0 then
            turtle.select(torch_slot)
            turtle.turnRight()
            turtle.turnRight()
            turtle.place()
            turtle.turnLeft()
            turtle.turnLeft()
            common.log("Placed torch", "debug")
        end
    end
end

local function digWithFallGuard(direction)
    direction = direction or "forward"
    local digFunc = turtle.dig
    local detectFunc = turtle.inspect
    if direction == "up" then
        digFunc = turtle.digUp
        detectFunc = turtle.inspectUp
    end
    digFunc()
    local detected, _ = detectFunc()
    while detected do
        common.log("Waiting for falling blocks?", "debug")
        digFunc()
        sleep(1)
        detected, _ = detectFunc()
    end
end

local function digLeftAndRight()
    turtle.turnLeft()
    digWithFallGuard()

    turtle.turnRight()
    turtle.turnRight()
    digWithFallGuard()

    turtle.turnLeft()
end

-- When falling blocks fall on the turtle they'll drop and then fall when it
-- goes forward, so we'll turn back on each step and try to pick up any
-- that fell off its back
local function clearAboveFallingItemsFromLastStep()
    turtle.turnRight()
    turtle.turnRight()
    turtle.suck()
    turtle.turnLeft()
    turtle.turnLeft()
end

local function clearLeftAndRightFallingItems()
    digLeftAndRight()
end

local function digStep()
    ensureInventorySpace()
    -- TODO: ensureTorch()?

    digWithFallGuard()
    turtleCommon.goForward()
    clearAboveFallingItemsFromLastStep()
    placeTorch()
    digLeftAndRight()

    for _=1, tunnel_height do
        digWithFallGuard("up")
        turtleCommon.goUp()
        digLeftAndRight()
    end

    for _=1, tunnel_height do
        turtleCommon.goDown()
    end

    -- Make sure to clear out any blocks that fell while digging higher up
    clearLeftAndRightFallingItems()
end

-- Main
local function main()
    common.printProgramStartupWithVersion("Tunnel", version)
    common.log("Digging Tunnel of length: " .. lengthOfTunnel .. ", Place Torches: " .. tostring(placeTorches))
    ensureTorches()
    for i=0,lengthOfTunnel do
        common.log("Digging: " .. i .. ", fuel left: " .. turtle.getFuelLevel(), "info")
        digStep()
    end
    turtleCommon.dumpInventory(torch_slot, off_limits_slots, true)
    common.log("Done digging tunnel")
end

main()

return {
    version = version,
    main = main,
}