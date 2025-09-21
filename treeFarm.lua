---@diagnostic disable: lowercase-global, undefined-global
--- ComputerCraft Turtle script to farm trees.

local version = { major=1, minor=0, patch=0 }

local min_fuel_level = 250
local wait_time_between_checks = 180 -- seconds
local sapling_slot = 1
local fuel_slot = 16

local chest_distance_down_from_start = 4
local chest_distance_backward_from_start = 3
local chest_distance_right_from_start = 1

local row_length = 5

-- Ensure global APIs are recognized by linters
local turtle = turtle
local sleep = sleep
---@diagnostic disable-next-line: undefined-global
local textutils = textutils
local peripheral = peripheral

local fuel_item_name = "minecraft:spruce_log"
local sapling_item_name = "minecraft:spruce_sapling"

local function throwError(msg)
    term.setTextColor(colors.red)
    print(msg)
    term.setTextColor(colors.white)
    error()
end

local function printWithColor(msg, color)
    term.setTextColor(color)
    print(msg)
    term.setTextColor(colors.white)
end

local function goLeft(distance)
    distance = distance or 1
    turtle.turnLeft()
    for i = 1, distance do
        if not turtle.forward() then
            throwError("Failed to go left. Stopping...")
        end
    end
    turtle.turnRight()
end

local function goRight(distance)
    distance = distance or 1
    turtle.turnRight()
    for i = 1, distance do
        if not turtle.forward() then
            throwError("Failed to go right. Stopping...")
        end
    end
    turtle.turnLeft()
end

local function goUp(distance)
    distance = distance or 1
    for i = 1, distance do
        if not turtle.up() then
            throwError("Failed to go up. Stopping...")
        end
    end
end

local function goDown(distance)
    distance = distance or 1
    for i = 1, distance do
        if not turtle.down() then
            throwError("Failed to go down. Stopping...")
        end
    end
end

local function goBack(distance)
    distance = distance or 1
    for i = 1, distance do
        if not turtle.back() then
            throwError("Failed to go back. Stopping...")
        end
    end
end

local function goForward(distance)
    distance = distance or 1
    for i = 1, distance do
        if not turtle.forward() then
            throwError("Failed to go forward. Stopping...")
        end
    end
end

local function safeDig()
    if not turtle.dig() then
        throwError("Failed to dig. Stopping...")
    end
end

-- TODO: replace with digWithFallGuard("up")
local function safeDigUp()
    if not turtle.digUp() then
        throwError("Failed to dig up. Stopping...")
    end
end

local function detectLog()
    local detected, data = turtle.inspect()
    local isLog = detected and string.sub(data.name, -3, -1) == "log"
    return isLog
end

local function detectSapling()
    local detected, data = turtle.inspect()
    local isSapling = detected and string.sub(data.name, -7, -1) == "sapling"
    return isSapling
end

local function harvestTree()
    printWithColor("Harvesting tree", colors.green)
    safeDig()
    goForward()
    local steps_up = 0
    while turtle.detectUp() do
        print("Digging tree: " .. steps_up)
        safeDigUp()
        goUp()
        steps_up = steps_up + 1
    end
    for i = 1, steps_up do
        goDown()
    end
    goBack()
    turtle.select(sapling_slot)
    turtle.place()
end

local function storeGoods()
    print("Storing goods")
    for i = 1, 16 do
        turtle.select(i)
        if i ~= sapling_slot and i ~= fuel_slot then
            if(turtle.getItemCount() > 0) then
                if not turtle.drop() then
                    throwError("The storage is full. Stopping...")
                end
            end
        end
    end
    turtle.select(sapling_slot)
end

local function findLastOpenInventorySlot(inventory_size, items)
    for i = inventory_size, 2, -1 do
        if items[i] == nil then
            return i
        end
    end
    throwError("No space to rearrange fuel/items in chest!")
end

local function restockItem(desired_item_name, needed_items)
    printWithColor("Restocking " .. desired_item_name, colors.yellow)
    local needed_items_left = needed_items + 1 -- Get one extra to keep first slot occupied by fuel item
    local chest = peripheral.wrap("front")
    local items = chest.list()
    local inventory_size = chest.size()
    print("Items in chest:")

    for i = 1, inventory_size do
        if items[i] ~= nil then
            local item_name = items[i].name
            local item_count = items[i].count

            if i == 1 and item_name ~= desired_item_name then
                print("Rearranging chest to move different item from slot 1 to the back")
                local last_open_slot = findLastOpenInventorySlot(inventory_size, items)
                chest.pushItems("front", 1, item_count, last_open_slot) -- Move non-fuel items to the back
                items = chest.list() -- Refresh the item list
                break
            end
            
            sleep(0.5)
            printWithColor("->" .. item_name .. " " .. item_count, colors.gray)

            if item_name == desired_item_name then
                print("Found desired item: ", i, item_name, item_count)
                if item_count >= needed_items_left then
                    chest.pullItems("front",i,needed_items_left)
                    needed_items_left = 0
                    break
                else
                    chest.pullItems("front",i,item_count)
                    needed_items_left = needed_items_left - item_count
                end
            end
        end
    end
    local slot_to_suck_into = fuel_slot
    if desired_item_name == sapling_item_name then
        slot_to_suck_into = sapling_slot
    end
    turtle.select(slot_to_suck_into)
    turtle.suck(turtle.getItemSpace())
    turtle.select(sapling_slot)
end

local function ensureFuel()
    if turtle.getFuelLevel() < min_fuel_level then
        local current_fuel = turtle.getFuelLevel()
        local needed_fuel = min_fuel_level - current_fuel
        local needed_items = math.ceil(needed_fuel / 15)
        print("Refueling from " .. current_fuel .. " to " .. min_fuel_level .. ", need " .. needed_items .. " items")
        if turtle.getItemCount(fuel_slot) < needed_items then
            print("Not enough fuel in fuel slot!")
            restockItem(fuel_item_name, needed_items)
            if turtle.getItemCount(fuel_slot) < needed_items then
                throwError("Not enough fuel in storage!")
            end
        end
        turtle.select(fuel_slot)
        turtle.refuel(needed_items)
        turtle.select(sapling_slot)
        if turtle.getFuelLevel() < min_fuel_level then
            throwError("Refuel failed!")
        end
    end
end

local function ensureSaplings()
    if turtle.getItemCount(sapling_slot) <= row_length then
        print("Restocking Saplings")
        restockItem(sapling_item_name, row_length)
        if turtle.getItemCount(sapling_slot) <= row_length then
            throwError("Not enough saplings in storage! Need at least " .. (row_length + 1) .. " saplings.")
        end
    end
end

local function navigateToRowStartFromChest()
    print("Navigating to row start from chest")
    goUp(chest_distance_down_from_start)
    goForward(chest_distance_backward_from_start)
    goLeft(chest_distance_right_from_start)
end

local function navigateToChestFromRowStart()
    print("Navigating to chest from row start")
    goRight(chest_distance_right_from_start)
    goBack(chest_distance_backward_from_start)
    goDown(chest_distance_down_from_start)
end

local function navigateToRowStartFromEnd()
    print("Navigating to row start from end of row, distance " .. row_length)
    for i = 1, row_length do
        goRight(1)
        turtle.suck() -- Grab any saplings on the way back
    end
end

local function patrolRow()
    print("Patrolling row of length " .. row_length)
    for i = 1, row_length do
        if not detectSapling() and not detectLog() then
            print("No sapling at " .. i .. ", planting new tree")
            turtle.select(sapling_slot)
            turtle.place()
        elseif detectLog() then
            print("Tree detected at " .. i .. ", harvesting")
            harvestTree()
        end
        goLeft(1)
    end

    navigateToRowStartFromEnd()
end

local function printLoopStatus()
    local time = os.time()
    local formattedTime = textutils.formatTime(time, false)
    print("Loop " .. formattedTime .. ", Fuel: " .. turtle.getFuelLevel() .. ", Saplings: " .. turtle.getItemCount(sapling_slot))
end

print("Starting tree farm")
navigateToChestFromRowStart()
turtle.select(sapling_slot)
ensureSaplings()
ensureFuel()
navigateToRowStartFromChest()

while true do
    printLoopStatus()
    if not detectLog() then
        if not detectSapling() then
            print("No sapling at start, planting new tree")
            turtle.select(sapling_slot)
            turtle.place()
        end
        print("Tree not detected at start, waiting for it to grow for efficiency")
    else
        patrolRow()
        navigateToChestFromRowStart()
        storeGoods()
        ensureSaplings()
        ensureFuel()
        navigateToRowStartFromChest()
    end

    sleep(wait_time_between_checks)
end

return {
    version = version,
}