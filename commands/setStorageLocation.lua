local common = require("common")
local args = {...}

---@diagnostic disable-next-line: undefined-global
local gps = gps

local currentX, currentY, currentZ = gps.locate()
local toSetX = args[1] or currentX
local toSetY = args[2] or currentY
local toSetZ = args[3] or currentZ
local curConfig = common.readConfigFile()
curConfig["storageX"] = toSetX
curConfig["storageY"] = toSetY
curConfig["storageZ"] = toSetZ

common.writeConfigFile(curConfig)
common.log("Storage set to " .. toSetX .. " " .. toSetY .. " " .. toSetZ)