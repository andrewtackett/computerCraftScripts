local args = {...}
if #args < 1 then
    print("Usage: dig <lengthOfTunnel> [placeTorches] [torchOffset]")
    print("  lengthOfTunnel: Length of the tunnel to dig (required)")
    print("  placeTorches: true/false whether to place torches (default: false)")
    print("  torchOffset: Offset for torch placement (default: 0)")
    return
end
local lengthOfTunnel = args[1]
local placeTorches = args[2] == "true" or false
local torchOffset = args[3] or 0

local torch_slot = 16
local distance_between_torches = 8
local tunnel_height = 8

local function ensureInventorySpace()
    for i=1,16 do
        if turtle.getItemCount(i) == 0 then
            return
        end
    end
    print("No inventory space left!")
    error()
end

local function ensureTorches()
    if turtle.getItemCount(torch_slot) == 0 then
        print("Out of torches!")
        error()
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
        print("Placed torch at step " .. step_number)
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
        print("Waiting for gravel?")
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
    print("Digging: " .. step_number .. " fuel left: " .. turtle.getFuelLevel())
    ensureInventorySpace()
    placeTorch(step_number)

    digWithFallGuard()
    turtle.forward()
    digLeftAndRight()

    for _=1, tunnel_height - 1 do
        digWithFallGuard("up")
        turtle.up()
        digLeftAndRight()
    end

    for _=1, tunnel_height - 1 do
        turtle.down()
    end
end

-- Main
print("Digging Tunnel of length: " .. lengthOfTunnel .. ", Place Torches: " .. tostring(placeTorches))
ensureTorches()
for i=1,lengthOfTunnel do
    digStep(i)
end
