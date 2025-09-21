-- ComputerCraft Turtle Script to dig a tunnel with optional torch placement
-- and inventory management

-- Expected start with Turtle facing forward along the tunnel path
-- with a chest/inventory to the right of it for unloading items
local version = { major=1, minor=0, patch=0 }
local common = require("common")
local turtleCommon = require("turtleCommon")

local args = {...}
if #args < 1 then
    print("Usage: tunnel <lengthOfTunnel> [placeTorches] [torchOffset] [tunnelStartOffset] [loggingMode]")
    return
end
local lengthOfTunnel = args[1]
local placeTorches = args[2] == "true" or false
local torchOffset = args[3] or 0
local tunnelStartOffset = args[4] or 0

local config = common.readConfigFile("config.cfg")
local storageX = config["storageX"]
local storageY = config["storageY"]
local storageZ = config["storageZ"]

local torch_slot = 16
local distance_between_torches = 6
local tunnel_height = 8
local items_to_compact_tags = "allthecompressed:1x"

-- Ensure global APIs are recognized by linters
---@diagnostic disable-next-line: undefined-global
local turtle = turtle
---@diagnostic disable-next-line: undefined-global
local sleep = sleep

local loggingMode = config["loggingMode"] or args[5] or "normal"
local function log(msg, level)
    common.log(loggingMode, msg, level)
end

local function navigateFromTunnelStoppingPointToTunnelStart(steps_taken_forward, steps_taken_up)
    log("Navigating to tunnel start", "info")
    turtleCommon.goDown(steps_taken_up)
    turtleCommon.goLeft()
    turtleCommon.goBack(steps_taken_forward + tunnelStartOffset)
    turtleCommon.goRight()
end

local function navigateFromTunnelStartToTunnelStoppingPoint(steps_taken_forward, steps_taken_up)
    log("Navigating from tunnel start to stopping point", "info")
    turtleCommon.goLeft()
    turtleCommon.goForward(steps_taken_forward + tunnelStartOffset)
    turtleCommon.goRight()
    turtleCommon.goUp(steps_taken_up)
end

-- local function compactItems()
--     log("Compacting items", "info")
-- end

local function dumpInventory(step_number)
    navigateFromTunnelStoppingPointToTunnelStart(step_number, 0)
    turtle.turnRight()
    turtleCommon.storeGoods()
    turtle.turnLeft()
    navigateFromTunnelStartToTunnelStoppingPoint(step_number, 0)
end

local function ensureInventorySpace(step_number)
    local function checkInventory()
        for i=1,16 do
            if turtle.getItemCount(i) == 0 then
                return true
            end
        end
        return false
    end
    if not checkInventory() then
        log("No inventory space left!", "warning")
        dumpInventory(step_number)
        common.waitForFix(checkInventory, 30)
    end
end

local function ensureTorches()
    local function checkTorches()
        turtle.select(torch_slot)
        return turtle.getItemCount(torch_slot) > 0
    end
    if not checkTorches() then
        log("Out of torches!", "error")
        common.waitForFix(checkTorches, 30)
    end
end

local function placeTorch(step_number)
    ensureTorches()
    if placeTorches and ((step_number + torchOffset) % distance_between_torches == 0) then
        turtle.select(torch_slot)
        turtle.turnRight()
        turtle.turnRight()
        turtle.place()
        turtle.turnLeft()
        turtle.turnLeft()
        log("Placed torch at step " .. step_number, "debug")
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
        log("Waiting for falling blocks?", "debug")
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

local function digStep(step_number)
    log("Digging: " .. step_number .. " fuel left: " .. turtle.getFuelLevel(), "info")
    ensureInventorySpace(step_number)
    -- ensureTorch()?

    digWithFallGuard()
    turtleCommon.goForward()
    clearAboveFallingItemsFromLastStep()
    placeTorch(step_number)
    digLeftAndRight()

    for _=0, tunnel_height do
        digWithFallGuard("up")
        turtleCommon.goUp()
        digLeftAndRight()
    end

    for _=0, tunnel_height do
        turtleCommon.goDown()
    end

    -- Make sure to clear out any blocks that fell while digging higher up
    clearLeftAndRightFallingItems()
end

-- Main
log("Tunnel v" .. version["major"] .. "." .. version["minor"] .. "." .. version["patch"] .. " starting...", "info")
log("Digging Tunnel of length: " .. lengthOfTunnel .. ", Place Torches: " .. tostring(placeTorches) .. ", Torch Offset: " .. torchOffset .. ", Tunnel Start Offset: " .. tunnelStartOffset .. ", Logging Mode: " .. loggingMode, "info")
log("--------------------------------------------------")
ensureTorches()
for i=0,(lengthOfTunnel - 1) do
    digStep(i)
    dumpInventory(i)
end

return {
    version = version,
}