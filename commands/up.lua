local args = {...}
local numSteps = tonumber(args[1] or 1)
local turtleCommon = require("turtleCommon")

turtleCommon.goUp(numSteps)

local version = 1
return {
    version = version
}
