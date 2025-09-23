local args = {...}
local common = require("common")
local turtleCommon = require("turtleCommon")
local isTreeFarm = args[1] == "true" or false

local destinationX, destinationY, destinationZ
local config = common.readConfigFile()
local y_first

if isTreeFarm then
    destinationX = config["treeStartX"]
    destinationY = config["treeStartY"]
    destinationZ = config["treeStartZ"]
    y_first = false
-- tunnel storage start
else
    destinationX = config["storageX"]
    destinationY = config["storageY"]
    destinationZ = config["storageZ"]
    y_first = true
end

turtleCommon.navigateToPoint(destinationX, destinationY, destinationZ, y_first)