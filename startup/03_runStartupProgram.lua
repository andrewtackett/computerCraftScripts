---@diagnostic disable-next-line: undefined-field
local computerId = os.getComputerID()
local programDirectory = {
    [6] = "attack",
    [7] = "attack",
    [8] = "attack",
    [9] = "attack",
    [17] = "attack",
    [29] = "attack",
    [0] = "monitor left display",
    [1] = "treeFarm"
}
local programToRun = programDirectory[computerId]
if programToRun then
---@diagnostic disable-next-line: undefined-global
    shell.run(programToRun)
end

local version = 2
return {
    version = version
}
