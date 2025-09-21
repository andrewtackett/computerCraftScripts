local args = {...}
local numSteps = tonumber(args[1] or 1)

---@diagnostic disable-next-line: undefined-global
local turtle = turtle

turtle.turnLeft()
for i=1,numSteps do
    turtle.forward()
end
turtle.turnRight()

local version = { major=1, minor=0, patch=0 }
return {
    version = version
}