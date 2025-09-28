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

local wait_time_between_checks = tonumber(config["waitTimeBetweenChecks"]) --180 seconds

local sapling_slot = 1
local fuel_slot = 16
local off_limits_slots = { [sapling_slot] = true, [fuel_slot] = true }

local row_length = 13
local num_rows = 3
local max_tree_height = 10
local next_row_moves = 4
local patrol_row_fuel_cost = max_tree_height * 2 * row_length
local moving_to_next_row_fuel_cost = next_row_moves * num_rows
local clean_up_fuel_cost = row_length * num_rows + moving_to_next_row_fuel_cost
local min_fuel_level = patrol_row_fuel_cost * num_rows + moving_to_next_row_fuel_cost + clean_up_fuel_cost + 100 -- Extra 100 for safety margin

local fuel_item_name = "minecraft:charcoal"
local sapling_item_name = "minecraft:spruce_sapling"
local fuel_item_value = 80

local function harvestTree()
    common.printWithColor("Harvesting tree, fuel: " .. turtle.getFuelLevel(), colors.green)
    turtleCommon.safeDig()
    turtleCommon.goForward()
    local steps_up = 0
    while turtle.detectUp() do
        common.log("Digging tree: " .. steps_up, "debug")
        turtleCommon.safeDigUp()
        turtleCommon.goUp()
        steps_up = steps_up + 1
    end
    for _ = 1, steps_up do
        turtle.digDown()
        turtleCommon.goDown()
    end
    turtleCommon.goBack()
end

local function ensureFuel()
    local function hasEnoughFuel()
        return turtle.getFuelLevel() > min_fuel_level
    end
    if not hasEnoughFuel() then
        local current_fuel = turtle.getFuelLevel()
        local needed_fuel = min_fuel_level - current_fuel
        local needed_items = math.ceil(needed_fuel / fuel_item_value)
        common.log("Refueling from " .. current_fuel .. " to " .. min_fuel_level .. ", need " .. needed_items .. " items")
        if turtle.getItemCount(fuel_slot) < needed_items then
            common.log("Not enough fuel in fuel slot!","warning")
            turtleCommon.restockItem(fuel_item_name, needed_items, fuel_slot, sapling_slot, "front")
            if turtle.getItemCount(fuel_slot) < needed_items then
                common.throwError("Not enough fuel in storage!")
            end
        end
        turtle.select(fuel_slot)
        turtle.refuel(needed_items)
        turtle.select(sapling_slot)
        if not hasEnoughFuel() then
            common.throwError("Refuel failed!")
        end
    end
end

local function ensureSaplings()
    local function storageHasEnoughSaplings()
        return turtle.getItemCount(sapling_slot) <= (row_length * num_rows) + 1
    end
    if storageHasEnoughSaplings() then
        common.log("Restocking Saplings")
        turtleCommon.restockItem(sapling_item_name, row_length, sapling_slot, sapling_slot, "front")
        if storageHasEnoughSaplings() then
            common.log("Not enough saplings in storage! Need at least " .. (row_length + 1) .. " saplings.","error")
            common.waitForFix(storageHasEnoughSaplings, 30)
        end
    end
end

local function navigateToTreeStartFromChest()
    common.log("Navigating to row start from chest")
    turtleCommon.navigateToPoint(treeStartX, treeStartY, treeStartZ, true)
end

local function navigateToChestFromTreeStart()
    common.log("Navigating to chest from row start")
    turtleCommon.navigateToPoint(storageX, storageY, storageZ, false)
end

local function navigateToNextRow(goLeft, goBack)
    common.log("Navigating to next row, fuel: " .. turtle.getFuelLevel() .. ", goLeft: " .. tostring(goLeft) .. ", goBack: " .. tostring(goBack))
    if goLeft then
        turtleCommon.goLeft(1)
        if goBack then
            turtleCommon.goBack(2)
        else
            turtleCommon.goForward(2)
        end
        turtleCommon.goRight(1)
    else
        turtleCommon.goRight(1)
        if goBack then
            turtleCommon.goBack(2)
        else
            turtleCommon.goForward(2)
        end
        turtleCommon.goLeft(1)
    end
end

-- Wait to replant until trees are harvested so leaves actually drop saplings
local function grabDropsAndReplant()
    common.log("Cleaning up drops on row")
    local goLeft
    for i = 1, num_rows do
        goLeft = (i % 2 == 0) -- Opposite of patrolRow
        for j = 1, (row_length - 1) do
            turtle.suck() -- Grab any saplings on the way back
            if j % 3 == 0 or j % 3 == 1 then
                turtle.select(sapling_slot)
                turtle.place()
            end
            if goLeft then
                turtleCommon.goLeft(1)
            else
                turtleCommon.goRight(1)
            end
        end
        turtle.suck()
        turtle.place()
        if i < num_rows then
            navigateToNextRow(goLeft, true)
        end
    end
end

local function patrolRow(rowNum, goLeft)
    common.log("Patrolling row " .. rowNum .. " of length " .. row_length)
    for i = 1, row_length do
        if turtleCommon.detectLog() then
            common.log("Tree detected at " .. i .. ", harvesting")
            harvestTree()
        else
            turtle.dig() -- Clear any saplings so they don't mess up later leaf drops collection
        end
        if i < row_length then
            if goLeft then
                turtleCommon.goLeft(1)
            else
                turtleCommon.goRight(1)
            end
        end
    end
end

local function patrolRows()
    local goLeft
    for i = 1, num_rows do
        goLeft = (i % 2 == 1)
        patrolRow(i, goLeft)
        if i < num_rows then
            navigateToNextRow(goLeft, false)
        end
    end
    grabDropsAndReplant()
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
            patrolRows()
            navigateToChestFromTreeStart()
            turtleCommon.storeGoods(sapling_slot, off_limits_slots)
            ensureSaplings()
            ensureFuel()
            navigateToTreeStartFromChest()
        end

        sleep(wait_time_between_checks)
    end
end

main()

return {
    version = version,
    main = main,
}