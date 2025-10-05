-- ComputerCraft Turtle Script to dig a tunnel with optional torch placement
-- and inventory management

-- Expected start with Turtle facing forward along the tunnel path
-- with a chest/inventory to the right of it for unloading items
local common = require("common")
local turtleCommon = require("turtleCommon")

-- Ensure global APIs are recognized by linters
---@diagnostic disable-next-line: undefined-global
local turtle = turtle
---@diagnostic disable-next-line: undefined-global
local sleep = sleep
---@diagnostic disable-next-line: undefined-global
local gps = gps
---@diagnostic disable-next-line: undefined-global
local peripheral = peripheral

local args = {...}
if #args < 1 then
    print("Usage: tunnel <tunnelLength> [tunnelHeight] [setStorageLocation]")
    return
end
local setStorageLocation = not (args[3] == "false")

if setStorageLocation then
    common.log("Resetting storage location")
    local currentX, currentY, currentZ = gps.locate()
    local curConfig = common.readConfigFile()
    curConfig["storageX"] = currentX
    curConfig["storageY"] = currentY
    curConfig["storageZ"] = currentZ

    common.writeConfigFile(curConfig)
    common.log("Storage set to " .. currentX .. " " .. currentY .. " " .. currentZ)
end

local config = common.readConfigFile()
local storageX = tonumber(config["storageX"])
local storageY = tonumber(config["storageY"])
local storageZ = tonumber(config["storageZ"])

local distance_between_torches = 6
local tunnelLength = args[1] or 100
local tunnelHeight = args[2] or tonumber(config["tunnelHeight"])
local tunnelWidth = 3 -- hardcoded by algorithm


local torch_slot = 16
local off_limits_slots = { [16] = true }

local function navigateToStorage()
    common.log("Navigating to storage")
    common.log("Storage coordinates: " .. storageX .. "|" .. storageY .. "|" .. storageZ, "debug")
    turtleCommon.navigateToPoint(storageX, storageY, storageZ, true)
    local numberOfRightTurnsToUndo = 0
    while peripheral.getType("front") ~= "minecraft:chest" and numberOfRightTurnsToUndo < 4 do
        turtle.turnRight()
        numberOfRightTurnsToUndo = numberOfRightTurnsToUndo + 1
    end
    if peripheral.getType("front") ~= "minecraft:chest" then
        common.throwError("No chest found next to turtle for storage at storage location " .. storageX .. "|" .. storageY .. "|" .. storageZ)
    end
    common.log("Arrived at storage")
    return numberOfRightTurnsToUndo
end

local function dumpInventory(default_slot, off_limits_slots, return_to_previous)
    common.log("Dumping Inventory")
    default_slot = default_slot or 1
    turtleCommon.goLeft()
    local currentX, currentY, currentZ = gps.locate()
    local numberOfRightTurnsToUndo = navigateToStorage()
    turtleCommon.storeGoods(default_slot, off_limits_slots)
    for _=1,numberOfRightTurnsToUndo do
        turtle.turnLeft()
    end
    if return_to_previous then
        common.log("Returning to start")
        turtleCommon.navigateToPoint(currentX, currentY, currentZ, true)
        turtleCommon.goRight()
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

local function shouldPlaceTorch()
    local currentX, _, currentZ = gps.locate()
    local xOffset = currentX % distance_between_torches
    local zOffset = currentZ % distance_between_torches
    -- Don't place torch at storage start
    if not (xOffset > 1 or zOffset > 1) then
        common.log("Not placing torch at storage start " .. currentX .. "|" .. currentZ .. ", " .. xOffset .. "|" .. zOffset, "debug")
        return false
    end
    local storageXOffset = (storageX % distance_between_torches)
    local storageZOffset = (storageZ % distance_between_torches)
    local alternatingRows = xOffset < tunnelWidth and zOffset < tunnelWidth
    local placeTorchHere =  (xOffset == storageXOffset) and (zOffset == storageZOffset) and alternatingRows
    common.log("Should place torch? " .. tostring(placeTorchHere) .. ", current: " .. currentX .. "|" .. currentZ .. ", offset: " .. xOffset .. "|" .. zOffset .. ", storage offset: " .. storageXOffset .. "|" .. storageZOffset, "debug")
    return placeTorchHere
end

local function tryPlaceTorch()
    if shouldPlaceTorch() then
        ensureTorches()
        turtle.select(torch_slot)
        turtle.turnRight()
        turtle.turnRight()
        turtle.place()
        turtle.turnLeft()
        turtle.turnLeft()
        common.log("Placed torch", "debug")
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
    tryPlaceTorch()
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

local version = 4
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
