
---@diagnostic disable-next-line: undefined-global
local turtle = turtle
local version = { major=1, minor=0, patch=0 }
local common = require("common")
local config = common.readConfigFile()

---@diagnostic disable-next-line: undefined-global
local peripheral = peripheral
---@diagnostic disable-next-line: undefined-global
local sleep = sleep
---@diagnostic disable-next-line: undefined-global
local gps = gps

local function goLeft(distance)
    distance = distance or 1
    turtle.turnLeft()
    for _ = 1, distance do
        if not turtle.forward() then
            common.throwError("Failed to go left. Stopping...")
        end
    end
    turtle.turnRight()
end

local function goRight(distance)
    distance = distance or 1
    turtle.turnRight()
    for _ = 1, distance do
        if not turtle.forward() then
            common.throwError("Failed to go right. Stopping...")
        end
    end
    turtle.turnLeft()
end

local function goUp(distance)
    distance = distance or 1
    for _ = 1, distance do
        if not turtle.up() then
            common.throwError("Failed to go up. Stopping...")
        end
    end
end

local function goDown(distance)
    distance = distance or 1
    for _ = 1, distance do
        if not turtle.down() then
            common.throwError("Failed to go down. Stopping...")
        end
    end
end

local function goBack(distance)
    distance = distance or 1
    for _ = 1, distance do
        if not turtle.back() then
            common.throwError("Failed to go back. Stopping...")
        end
    end
end

local function goForward(distance)
    distance = distance or 1
    for _ = 1, distance do
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

local function findLastOpenInventorySlot(inventory_size, items)
    for i = inventory_size, 2, -1 do
        common.log("findLastOpenInventorySlot: " .. inventory_size .. ", " .. i, "verbose")
        if items[i] ~= nil then
            common.log(", " .. items[i].name, "verbose")
        end
        if items[i] == nil then
            return i
        end
    end
    common.throwError("No space to rearrange fuel/items in chest!")
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

local function restockItem(desired_item_name, needed_items, slot_to_suck_into, default_slot, inventory_direction)
    common.log("Restocking " .. desired_item_name, "info")
    local needed_items_left = needed_items
    local chest = peripheral.wrap(inventory_direction)
    local items = chest.list()
    local inventory_size = chest.size()
    common.log("Items in chest:", "debug")

    for i = 1, inventory_size do
        if items[i] ~= nil then
            local item_name = items[i].name
            local item_count = items[i].count
            common.log("restock test: " .. i .. ", name: " .. item_name .. ", count: " .. item_count)

            if i == 1 and item_name ~= desired_item_name then
                common.log("Rearranging chest to move different item from slot 1 to the back")
                local last_open_slot = findLastOpenInventorySlot(inventory_size, items)
                common.log(i .. " - last_open_slot: " .. last_open_slot, "debug")
                chest.pushItems("front", 1, item_count, last_open_slot) -- Move non-fuel items to the back
                items = chest.list() -- Refresh the item list
                break
            end

            common.log("->" .. item_name .. " " .. item_count, "debug")

            if item_name == desired_item_name then
                common.log("Found desired item: " .. i .. item_name .. item_count, "debug")
                if item_count >= needed_items_left then
                    chest.pullItems("front", i, needed_items_left, 1)
                    needed_items_left = 0
                    break
                else
                    chest.pullItems("front", i, item_count, 1)
                    needed_items_left = needed_items_left - item_count
                end
            end
        end
    end
    turtle.select(slot_to_suck_into)
    turtle.suck(turtle.getItemSpace())
    turtle.select(default_slot)
end

-- TODO: convert
local function ensureFuel(min_fuel_level, fuel_item_name, fuel_slot, default_slot)
    if turtle.getFuelLevel() < min_fuel_level then
        local current_fuel = turtle.getFuelLevel()
        local needed_fuel = min_fuel_level - current_fuel
        local needed_items = math.ceil(needed_fuel / 15)
        common.log("Refueling from " .. current_fuel .. " to " .. min_fuel_level .. ", need " .. needed_items .. " items")
        if turtle.getItemCount(fuel_slot) < needed_items then
            common.log("Not enough fuel in fuel slot!","warning")
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

local function determineWhichDirectionCurrentlyFacing()
    local x, _, z = gps.locate()
    local direction = ""
    if turtle.forward() then
        local x2, _, z2 = gps.locate()
        local xOffset = x2 - x
        local zOffset = z2 - z
        if xOffset ~= 0 then
            if xOffset < 0 then
                direction = "xNeg"
            else
                direction = "xPos"
            end
        elseif zOffset ~= 0 then
            if zOffset < 0 then
                direction = "zNeg"
            else
                direction = "zPos"
            end
        end
        goBack(1)
    elseif turtle.back() then
        local x2, _, z2 = gps.locate()
        local xOffset = x2 - x
        local zOffset = z2 - z
        if xOffset ~= 0 then
            if xOffset > 0 then
                direction = "xNeg"
            else
                direction = "xPos"
            end
        elseif zOffset ~= 0 then
            if zOffset > 0 then
                direction = "zNeg"
            else
                direction = "zPos"
            end
        end
        goForward(1)
    else
        common.throwError("Can't move forward or backward to determine direction")
    end
    
    return direction
end

local function getNavigationFunctionsFromDirection(currentDirection)
    local goXPos, goXNeg, goZPos, goZNeg
    if currentDirection == "xPos" then
        goXPos = goForward
        goXNeg = goBack
        goZPos = goRight
        goZNeg = goLeft
    elseif currentDirection == "xNeg" then
        goXPos = goBack
        goXNeg = goForward
        goZPos = goLeft
        goZNeg = goRight
    elseif currentDirection == "zPos" then
        goXPos = goLeft
        goXNeg = goRight
        goZPos = goForward
        goZNeg = goBack
    elseif currentDirection == "zNeg" then
        goXPos = goRight
        goXNeg = goLeft
        goZPos = goBack
        goZNeg = goForward
    end
    return goXPos, goXNeg, goZPos, goZNeg
end

local function navigateToPoint(target_x, target_y, target_z, y_first)
    local current_x, current_y, current_z = gps.locate()
    local currentDirection = determineWhichDirectionCurrentlyFacing()
    common.log("currentDirection " .. currentDirection, "debug")
    local goXPos, goXNeg, goZPos, goZNeg = getNavigationFunctionsFromDirection(currentDirection)

    while current_x ~= target_x or current_y ~= target_y or current_z ~= target_z do
        local xOffset, yOffset, zOffset = math.abs(target_x - current_x), math.abs(target_y - current_y), math.abs(target_z - current_z)
        common.log("offsets " .. xOffset .. "|" .. yOffset .. "|" .. zOffset, "debug")

        if y_first then
            common.log("Doing Y dir", "debug")
            if current_y < target_y then
                goUp(yOffset)
            elseif current_y > target_y then
                goDown(yOffset)
            end
        end

        if currentDirection == "xPos" or currentDirection == "xNeg" then
            common.log("Doing x dir", "debug")
            if current_x < target_x then
                goXPos(xOffset)
            elseif current_x > target_x then
                goXNeg(xOffset)
            end

            common.log("Doing z dir", "debug")
            if current_z < target_z then
                goZPos(zOffset)
            elseif current_z > target_z then
                goZNeg(zOffset)
            end
        elseif currentDirection == "zPos" or currentDirection == "zNeg" then
            common.log("Doing z dir", "debug")
            if current_z < target_z then
                goZPos(zOffset)
            elseif current_z > target_z then
                goZNeg(zOffset)
            end

            common.log("Doing x dir", "debug")
            if current_x < target_x then
                goXPos(xOffset)
            elseif current_x > target_x then
                goXNeg(xOffset)
            end
        end


        if not y_first then
            common.log("Doing Y dir", "debug")
            if current_y < target_y then
                goUp(yOffset)
            elseif current_y > target_y then
                goDown(yOffset)
            end
        end
        current_x, current_y, current_z = gps.locate()
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
    findLastOpenInventorySlot = findLastOpenInventorySlot,
    storeGoods = storeGoods,
    restockItem = restockItem,
    ensureFuel = ensureFuel,
    determineWhichDirectionCurrentlyFacing = determineWhichDirectionCurrentlyFacing,
    getNavigationFunctionsFromDirection = getNavigationFunctionsFromDirection,
    navigateToPoint = navigateToPoint,
}