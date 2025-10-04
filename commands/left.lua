local args = {...}
local numSteps = tonumber(args[1] or 1)

---@diagnostic disable-next-line: undefined-global
local turtle = turtle

turtle.turnLeft()
for _=1,numSteps do
    turtle.forward()
end
turtle.turnRight()

local version = 1
return {
    version = version
}
