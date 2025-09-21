--- ComputerCraft Turtle script to farm trees.

-- Ensure global APIs are recognized by linters
---@diagnostic disable-next-line: undefined-global
local turtle = turtle
---@diagnostic disable-next-line: undefined-global
local sleep = sleep
---@diagnostic disable-next-line: undefined-global
local textutils = textutils
---@diagnostic disable-next-line: undefined-global
local colors = colors

local version = { major=1, minor=0, patch=0 }
local common = require("common")
local turtleCommon = require("turtleCommon")
local config = common.readConfigFile()

local storageX = tonumber(config["storageX"])
local storageY = tonumber(config["storageY"])
local storageZ = tonumber(config["storageZ"])

local treeStartX = tonumber(config["treeStartX"])
local treeStartY = tonumber(config["treeStartY"])
local treeStartZ = tonumber(config["treeStartZ"])

local min_fuel_level = 250
local wait_time_between_checks = tonumber(config["waitTimeBetweenChecks"]) --180 seconds

local sapling_slot = 1
local fuel_slot = 16
local off_limits_slots = { [sapling_slot] = true, [fuel_slot] = true }

local row_length = 5

local fuel_item_name = "minecraft:spruce_log"
local sapling_item_name = "minecraft:spruce_sapling"

local function harvestTree()
    common.printWithColor("Harvesting tree", colors.green)
    turtleCommon.safeDig()
    turtleCommon.goForward()
    local steps_up = 0
    while turtle.detectUp() do
        common.log("Digging tree: " .. steps_up)
        turtleCommon.safeDigUp()
        turtleCommon.goUp()
        steps_up = steps_up + 1
    end
    for _ = 1, steps_up do
        turtleCommon.goDown()
    end
    turtleCommon.goBack()
    turtle.select(sapling_slot)
    turtle.place()
end

local function ensureFuel()
    local function storageHasEnoughFuel()
        return turtle.getFuelLevel() < min_fuel_level
    end
    if storageHasEnoughFuel() then
        local current_fuel = turtle.getFuelLevel()
        local needed_fuel = min_fuel_level - current_fuel
        local needed_items = math.ceil(needed_fuel / 15)
        common.log("Refueling from " .. current_fuel .. " to " .. min_fuel_level .. ", need " .. needed_items .. " items")
        if turtle.getItemCount(fuel_slot) < needed_items then
            common.log("Not enough fuel in fuel slot!","warning")
            turtleCommon.restockItem(fuel_item_name, needed_items, fuel_slot, sapling_slot)
            if turtle.getItemCount(fuel_slot) < needed_items then
                common.throwError("Not enough fuel in storage!")
            end
        end
        turtle.select(fuel_slot)
        turtle.refuel(needed_items)
        turtle.select(sapling_slot)
        if storageHasEnoughFuel() then
            common.log("Refuel failed!","error")
            common.waitForFix(storageHasEnoughFuel, 30)
        end
    end
end

local function ensureSaplings()
    local function storageHasEnoughSaplings()
        return turtle.getItemCount(sapling_slot) <= row_length
    end
    if storageHasEnoughSaplings() then
        common.log("Restocking Saplings")
        turtleCommon.restockItem(sapling_item_name, row_length, sapling_slot, sapling_slot)
        if storageHasEnoughSaplings() then
            common.log("Not enough saplings in storage! Need at least " .. (row_length + 1) .. " saplings.","error")
            common.waitForFix(storageHasEnoughSaplings, 30)
        end
    end
end

local function navigateToRowStartFromChest()
    common.log("Navigating to row start from chest")
    turtleCommon.navigateToPoint(treeStartX, treeStartY, treeStartZ, false)
end

local function navigateToChestFromRowStart()
    common.log("Navigating to chest from row start")
    turtleCommon.navigateToPoint(storageX, storageY, storageZ, false)
end

local function navigateToRowStartFromEnd()
    common.log("Navigating to row start from end of row, distance " .. row_length)
    for i = 1, row_length do
        turtleCommon.goRight(1)
        turtle.suck() -- Grab any saplings on the way back
    end
    -- Get row end
    turtleCommon.goRight(1)
    turtle.suck()
end

local function patrolRow()
    common.log("Patrolling row of length " .. row_length)
    for i = 1, row_length do
        if not turtleCommon.detectSapling() and not turtleCommon.detectLog() then
            common.log("No sapling at " .. i .. ", planting new tree")
            turtle.select(sapling_slot)
            turtle.place()
        elseif turtleCommon.detectLog() then
            common.log("Tree detected at " .. i .. ", harvesting")
            harvestTree()
        end
        turtleCommon.goLeft(1)
    end

    navigateToRowStartFromEnd()
end

local function printLoopStatus()
    local time = os.time()
    local formattedTime = textutils.formatTime(time, false)
    common.log("Loop " .. formattedTime .. ", Fuel: " .. turtle.getFuelLevel() .. ", Saplings: " .. turtle.getItemCount(sapling_slot))
end

local function main()
    common.printProgramStartupWithVersion("Tree Farm", version)
    turtle.select(sapling_slot)

    while true do
        printLoopStatus()
        if not turtleCommon.detectLog() then
            if not turtleCommon.detectSapling() then
                common.log("No sapling at start, planting new tree")
                turtle.select(sapling_slot)
                turtle.place()
            end
            common.log("Tree not detected at start, waiting for it to grow for efficiency")
        else
            patrolRow()
            navigateToChestFromRowStart()
            turtleCommon.storeGoods(sapling_slot, off_limits_slots)
            ensureSaplings()
            ensureFuel()
            navigateToRowStartFromChest()
        end

        sleep(wait_time_between_checks)
    end
end

main()

return {
    version = version,
    main = main,
}