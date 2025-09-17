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

local function waitForFix(checkFunction)
    while not checkFunction() do
        sleep(5)
    end
end

local function findLastOpenInventorySlot(inventory_size, items)
    for i = inventory_size, 2, -1 do
        if items[i] == nil then
            return i
        end
    end
    throwError("No space to rearrange fuel/items in chest!")
end

