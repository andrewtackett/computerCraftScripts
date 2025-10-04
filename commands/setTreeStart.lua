local common = require("common")
local args = {...}

---@diagnostic disable-next-line: undefined-global
local gps = gps

local currentX, currentY, currentZ = gps.locate()
local toSetX = args[1] or currentX
local toSetY = args[2] or currentY
local toSetZ = args[3] or currentZ
local curConfig = common.readConfigFile()
curConfig["treeStartX"] = toSetX
curConfig["treeStartY"] = toSetY
curConfig["treeStartZ"] = toSetZ

common.writeConfigFile(curConfig)
common.log("Tree start set to " .. toSetX .. " " .. toSetY .. " " .. toSetZ)

local version = 1
return {
    version = version
}
