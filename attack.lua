---@diagnostic disable-next-line: undefined-global
local turtle = turtle
---@diagnostic disable-next-line: undefined-global
local peripheral = peripheral

print("Starting Attack")
local testInv = peripheral.wrap("back")
while not testInv do
    print("Not oriented correctly, turning left")
    turtle.turnLeft()
    testInv = peripheral.wrap("back")
end
while true do
    for _=1,100 do
        turtle.attack()
    end
    turtle.turnLeft()
    turtle.turnLeft()
    for i=1,16 do
        turtle.select(i) 
        turtle.drop()
    end
    turtle.turnLeft()
    turtle.turnLeft()
end