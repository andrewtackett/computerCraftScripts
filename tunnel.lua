-- ComputerCraft Turtle Script to dig a tunnel with optional torch placement
-- and inventory management

-- Expected start with Turtle facing forward along the tunnel path
-- with a chest/inventory to the right of it for unloading items

-- TODO: add restocking fuel and torches
-- TODO: add compressing deepslate and other common blocks into their x1/x2/x9 forms
-- TODO: see if we can collect xp

local args = {...}
if #args < 1 then
    print("Usage: tunnel <lengthOfTunnel> [placeTorches] [torchOffset] [tunnelStartOffset] [loggingMode]")
    -- print("  lengthOfTunnel: Length of the tunnel to dig (required)")
    -- print("  placeTorches: true/false whether to place torches (default: false)")
    -- print("  torchOffset: Offset for torch placement (default: 0)")
    -- print("  loggingMode: 'normal', 'verbose', or 'debug' (default: 'normal')")
    return
end
local lengthOfTunnel = args[1]
local placeTorches = args[2] == "true" or false
local torchOffset = args[3] or 0
local tunnelStartOffset = args[4] or 0
local loggingMode = args[5] or "normal" -- "normal", "verbose", "debug"

local torch_slot = 16
local distance_between_torches = 6
local tunnel_height = 8
local items_to_compact_tags = "allthecompressed:1x"
-- t = {[1]=true, [2]=true}

-- Ensure global APIs are recognized by linters
---@diagnostic disable-next-line: undefined-global
local turtle = turtle
---@diagnostic disable-next-line: undefined-global
local sleep = sleep
---@diagnostic disable-next-line: undefined-global
local term = term
---@diagnostic disable-next-line: undefined-global
local colors = colors

local info_color    = colors.lightBlue
local warning_color = colors.orange
local error_color   = colors.red
local success_color = colors.green
local verbose_color = colors.purple
local debug_color   = colors.gray
local default_color = colors.green
-- Color codes reference:

-- colors.white	    1	    0x1	    0		#F0F0F0	240, 240, 240	
-- colors.orange	2	    0x2	    1		#F2B233	242, 178, 51	
-- colors.magenta	4	    0x4	    2		#E57FD8	229, 127, 216	
-- colors.lightBlue	8	    0x8	    3		#99B2F2	153, 178, 242	
-- colors.yellow	16	    0x10	4		#DEDE6C	222, 222, 108	
-- colors.lime	    32	    0x20	5		#7FCC19	127, 204, 25	
-- colors.pink	    64	    0x40	6		#F2B2CC	242, 178, 204	
-- colors.gray	    128	    0x80	7		#4C4C4C	76, 76, 76	
-- colors.lightGray	256	    0x100	8		#999999	153, 153, 153	
-- colors.cyan	    512	    0x200	9		#4C99B2	76, 153, 178	
-- colors.purple	1024	0x400	a		#B266E5	178, 102, 229	
-- colors.blue	    2048	0x800	b		#3366CC	51, 102, 204	
-- colors.brown	    4096	0x1000	c		#7F664C	127, 102, 76	
-- colors.green	    8192	0x2000	d		#57A64E	87, 166, 78	
-- colors.red	    16384	0x4000	e		#CC4C4C	204, 76, 76	
-- colors.black     32768	0x8000	f		#191919	25, 25, 25

local function throwError(msg)
    term.setTextColor(error_color)
    print(msg)
    term.setTextColor(default_color)
    error()
end

local function log(msg, level)
    level = level or "info"
    local color = info_color
    if level == "warning" then
        color = warning_color
    elseif level == "error" then
        color = error_color
    elseif level == "success" then
        color = success_color
    elseif level == "verbose" then
        color = verbose_color
    elseif level == "debug" then
        color = debug_color
    end
    -- Implicitly filter messages based on logging mode and color
    if loggingMode == "normal" and (level == "debug" or level == "verbose") then
        return
    elseif loggingMode == "verbose" and level == "debug" then
        return
    end
    term.setTextColor(color)
    print(msg)
    term.setTextColor(default_color)
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

local function waitForFix(checkFunction)
    while not checkFunction() do
        sleep(30)
    end
end

local function navigateFromTunnelStoppingPointToTunnelStart(steps_taken_forward, steps_taken_up)
    log("Navigating to tunnel start", "info")
    goDown(steps_taken_up)
    goLeft()
    goBack(steps_taken_forward + tunnelStartOffset)
    goRight()
end

local function navigateFromTunnelStartToTunnelStoppingPoint(steps_taken_forward, steps_taken_up)
    log("Navigating from tunnel start to stopping point", "info")
    goLeft()
    goForward(steps_taken_forward + tunnelStartOffset)
    goRight()
    goUp(steps_taken_up)
end

-- local function compactItems()
--     log("Compacting items", "info")
-- end

-- t = { name = "minecraft:oak_log", state = { axis = "x" }, tags = { ["minecraft:logs"] = true }}

local function storeGoods()
    log("Storing goods", "info")
    local function canDropItems()
        return turtle.drop()
    end
    for i = 1, 16 do
        turtle.select(i)
        if i ~= torch_slot then
            if(turtle.getItemCount() > 0) then
                if not turtle.drop() then
                    log("The storage is full. Stopping...", "error")
                    waitForFix(canDropItems)
                end
            end
        end
    end
    turtle.select(torch_slot)
    log("Finished storing goods", "success")
end

local function dumpInventory(step_number)
    navigateFromTunnelStoppingPointToTunnelStart(step_number, 0)
    turtle.turnRight()
    storeGoods()
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
        waitForFix(checkInventory)
    end
end

local function ensureTorches()
    local function checkTorches()
        turtle.select(torch_slot)
        return turtle.getItemCount(torch_slot) > 0
    end
    if not checkTorches() then
        log("Out of torches!", "error")
        waitForFix(checkTorches)
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

local function digStep(step_number)
    log("Digging: " .. step_number .. " fuel left: " .. turtle.getFuelLevel(), "info")
    ensureInventorySpace(step_number)
    -- ensureTorch()?
    placeTorch(step_number)

    digWithFallGuard()
    goForward()
    digLeftAndRight()

    for _=1, tunnel_height - 1 do
        digWithFallGuard("up")
        goUp()
        digLeftAndRight()
    end

    for _=1, tunnel_height - 1 do
        goDown()
    end

    -- Make sure to clear out any blocks that fell while digging higher up
    digLeftAndRight()
end

-- Main
log("Tunnel v2.0 starting...", "info")
log("Digging Tunnel of length: " .. lengthOfTunnel .. ", Place Torches: " .. tostring(placeTorches) .. ", Torch Offset: " .. torchOffset .. ", Tunnel Start Offset: " .. tunnelStartOffset .. ", Logging Mode: " .. loggingMode, "info")
log("--------------------------------------------------")
ensureTorches()
for i=1,lengthOfTunnel do
    digStep(i)
end
