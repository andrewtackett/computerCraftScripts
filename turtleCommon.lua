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