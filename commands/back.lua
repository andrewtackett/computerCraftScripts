local args = {...}
local numSteps = tonumber(args[1] or 1)
local turtleCommon = require("turtleCommon")

turtleCommon.goBack(numSteps)

local version = { major=1, minor=0, patch=0 }
return {
    version = version
}