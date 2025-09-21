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
    print("Usage: tunnel <tunnelLength> [placeTorches] [tunnelHeight]")
    return
end
local config = common.readConfigFile()
local tunnelLength = args[1]
local placeTorches = args[2] == "true" or false

local storageX = tonumber(config["storageX"])
local storageY = tonumber(config["storageY"])
local storageZ = tonumber(config["storageZ"])

local torch_slot = 16
local off_limits_slots = { [16] = true }
local distance_between_torches = 6
local tunnelHeight = args[3] or tonumber(config["tunnelHeight"])

local function navigateToStorage()
    common.log("Navigating to storage")
    local storageX = tonumber(config["storageX"])
    local storageY = tonumber(config["storageY"])
    local storageZ = tonumber(config["storageZ"])
    common.log("Storage coordinates: " .. storageX .. "|" .. storageY .. "|" .. storageZ, "debug")
    turtleCommon.navigateToPoint(storageX, storageY, storageZ, true)
    common.log("Arrived at storage")
end

local function dumpInventory(default_slot, off_limits_slots, return_to_previous)
    common.log("Dumping Inventory")
    default_slot = default_slot or 1
    local currentX, currentY, currentZ = gps.locate()
    turtleCommon.goLeft()
    navigateToStorage()
    turtle.turnRight()
    turtleCommon.storeGoods(default_slot, off_limits_slots)
    turtle.turnLeft()
    common.log("Returning to start")
    turtleCommon.goLeft()
    if return_to_previous then
        turtleCommon.navigateToPoint(currentX, currentY, currentZ, true)
    end
end

-- TODO: make this fetch from chest/dump inventory
local function ensureFuel()
    local curFuel = turtle.getFuelLevel()
     -- 2.6 = 2 for both sides, 0.6 guess for trips to storage
    local neededFuel = math.ceil(tunnelLength * tunnelHeight * 2.6)
    local hasEnoughFuel = curFuel > neededFuel
    if not hasEnoughFuel then
        common.throwError("Not enough fuel")
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
        dumpInventory(torch_slot, off_limits_slots, true)
        common.waitForFix(checkInventory, 30)
    end
end

local function getMaxOffset()
    local currentX, currentY, currentZ = gps.locate()
    local xOffset = math.abs(storageX - currentX)
    local yOffset = math.abs(storageY - currentY)
    local zOffset = math.abs(storageZ - currentZ)
    common.log("getMaxOffset: " .. xOffset .. "|" .. yOffset .. "|" .. zOffset, "debug")
    local offsetTable = { xOffset, yOffset, zOffset }
    table.sort(offsetTable)
    common.log("getMaxOffset, offsetTable: " .. tostring(offsetTable[#offsetTable]), "debug")
    local maxOffset = offsetTable[#offsetTable]
    return maxOffset
end

local function placeTorch()
    if placeTorches then
        ensureTorches()
        local torchOffset = getMaxOffset()
        common.log("torchoffset: " .. torchOffset, "debug")
        common.log("calc1: ".. tostring(torchOffset % distance_between_torches), "debug")
        common.log("calc2: " .. tostring((torchOffset % distance_between_torches) - 1 == 0), "debug")
        -- Add one so we don't put a torch where we're starting blocking storage
        if (torchOffset % distance_between_torches) - 1 == 0 then
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
    -- TODO: ensureTorch()? / ensureFuel()?

    digWithFallGuard()
    turtleCommon.goForward()
    clearAboveFallingItemsFromLastStep()
    placeTorch()
    digLeftAndRight()

    for _=1, (tunnelHeight - 1) do
        digWithFallGuard("up")
        turtleCommon.goUp()
        digLeftAndRight()
    end

    for _=1, (tunnelHeight - 1) do
        turtleCommon.goDown()
    end

    -- Make sure to clear out any blocks that fell while digging higher up
    clearLeftAndRightFallingItems()
end

-- Main
local function main()
    common.printProgramStartupWithVersion("Tunnel", version)
    common.log("Digging Tunnel of length/height: " .. tunnelLength .. "/" .. tunnelHeight)
    ensureTorches()
    ensureFuel()
    for i=1,tunnelLength do
        common.log("Digging: " .. i .. ", fuel left: " .. turtle.getFuelLevel(), "info")
        digStep()
    end
    dumpInventory(torch_slot, off_limits_slots, false)
    common.log("Done digging tunnel")
end

main()

return {
    version = version,
    main = main,
}