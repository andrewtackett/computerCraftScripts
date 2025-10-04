local args = {...}
local common = require("common")
local turtleCommon = require("turtleCommon")
local isTreeFarm = args[1] == "true"

local destinationX, destinationY, destinationZ
local config = common.readConfigFile()
local y_first

if isTreeFarm then
    destinationX = tonumber(config["treeStartX"])
    destinationY = tonumber(config["treeStartY"])
    destinationZ = tonumber(config["treeStartZ"])
    y_first = false
-- tunnel storage start
else
    destinationX = tonumber(config["storageX"])
    destinationY = tonumber(config["storageY"])
    destinationZ = tonumber(config["storageZ"])
    y_first = true
end

turtleCommon.navigateToPoint(destinationX, destinationY, destinationZ, y_first)

local version = 1
return {
    version = version
}
