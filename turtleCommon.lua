
---@diagnostic disable-next-line: undefined-global
local turtle = turtle
local version = { major=1, minor=0, patch=0 }
local common = require("common")

---@diagnostic disable-next-line: undefined-global
local peripheral = peripheral
---@diagnostic disable-next-line: undefined-global
local sleep = sleep
---@diagnostic disable-next-line: undefined-global
local gps = gps

local function goLeft(distance)
    distance = distance or 1
    turtle.turnLeft()
    for i = 1, distance do
        if not turtle.forward() then
            common.throwError("Failed to go left. Stopping...")
        end
    end
    turtle.turnRight()
end

local function goRight(distance)
    distance = distance or 1
    turtle.turnRight()
    for i = 1, distance do
        if not turtle.forward() then
            common.throwError("Failed to go right. Stopping...")
        end
    end
    turtle.turnLeft()
end

local function goUp(distance)
    distance = distance or 1
    for i = 1, distance do
        if not turtle.up() then
            common.throwError("Failed to go up. Stopping...")
        end
    end
end

local function goDown(distance)
    distance = distance or 1
    for i = 1, distance do
        if not turtle.down() then
            common.throwError("Failed to go down. Stopping...")
        end
    end
end

local function goBack(distance)
    distance = distance or 1
    for i = 1, distance do
        if not turtle.back() then
            common.throwError("Failed to go back. Stopping...")
        end
    end
end

local function goForward(distance)
    distance = distance or 1
    for i = 1, distance do
        if not turtle.forward() then
            common.throwError("Failed to go forward. Stopping...")
        end
    end
end

local function safeDig()
    if not turtle.dig() then
        common.throwError("Failed to dig. Stopping...")
    end
end

local function safeDigUp()
    if not turtle.digUp() then
        common.throwError("Failed to dig up. Stopping...")
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

local function storeGoods(default_slot, off_limits_slots)
    common.log("Storing goods", "info")
    local function canDropItems()
        return turtle.drop()
    end
    for i = 1, 16 do
        turtle.select(i)
        if not off_limits_slots[i] then
            if(turtle.getItemCount() > 0) then
                if not turtle.drop() then
                    common.log("The storage is full. Stopping...", "error")
                    common.waitForFix(canDropItems, 30)
                end
            end
        end
    end
    turtle.select(default_slot)
end

local function restockItem(desired_item_name, needed_items)
    common.log("Restocking " .. desired_item_name, "info")
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
                local last_open_slot = common.findLastOpenInventorySlot(inventory_size, items)
                chest.pushItems("front", 1, item_count, last_open_slot) -- Move non-fuel items to the back
                items = chest.list() -- Refresh the item list
                break
            end
            
            sleep(0.5)
            common.log("->" .. item_name .. " " .. item_count, "debug")

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

local function ensureFuel(min_fuel_level, fuel_item_name, fuel_slot, default_slot)
    if turtle.getFuelLevel() < min_fuel_level then
        local current_fuel = turtle.getFuelLevel()
        local needed_fuel = min_fuel_level - current_fuel
        local needed_items = math.ceil(needed_fuel / 15)
        print("Refueling from " .. current_fuel .. " to " .. min_fuel_level .. ", need " .. needed_items .. " items")
        if turtle.getItemCount(fuel_slot) < needed_items then
            print("Not enough fuel in fuel slot!")
            restockItem(fuel_item_name, needed_items)
            if turtle.getItemCount(fuel_slot) < needed_items then
                common.throwError("Not enough fuel in storage!")
            end
        end
        turtle.select(fuel_slot)
        turtle.refuel(needed_items)
        turtle.select(default_slot)
        if turtle.getFuelLevel() < min_fuel_level then
            common.throwError("Refuel failed!")
        end
    end
end

local function navigateToPoint(target_x, target_y, target_z)
    local x,y,z = gps.locate()
    local current_pos = {x = x, y = y, z = z}
    local target_pos = {x = target_x, y = target_y, z = target_z}

    while current_pos.x ~= target_pos.x or current_pos.y ~= target_pos.y or current_pos.z ~= target_pos.z do
        if current_pos.x < target_pos.x then
            goRight()
            current_pos.x = current_pos.x + 1
        elseif current_pos.x > target_pos.x then
            goLeft()
            current_pos.x = current_pos.x - 1
        end

        if current_pos.y < target_pos.y then
            goUp()
            current_pos.y = current_pos.y + 1
        elseif current_pos.y > target_pos.y then
            goDown()
            current_pos.y = current_pos.y - 1
        end

        if current_pos.z < target_pos.z then
            goForward()
            current_pos.z = current_pos.z + 1
        elseif current_pos.z > target_pos.z then
            goBack()
            current_pos.z = current_pos.z - 1
        end
    end
end

return {
    version = version,
    goLeft = goLeft,
    goRight = goRight,
    goUp = goUp,
    goDown = goDown,
    goForward = goForward,
    goBack = goBack,
    safeDig = safeDig,
    safeDigUp = safeDigUp,
    detectLog = detectLog,
    detectSapling = detectSapling,
    storeGoods = storeGoods,
    restockItem = restockItem,
    ensureFuel = ensureFuel,
    navigateToPoint = navigateToPoint,
}