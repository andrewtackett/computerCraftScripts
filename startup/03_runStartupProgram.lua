---@diagnostic disable-next-line: undefined-field
local computerId = os.getComputerID()
local programDirectory = {
    [6] = "attack",
    [7] = "attack",
    [8] = "attack",
    [0] = "monitor left display",
    [1] = "treeFarm"
}
local programToRun = programDirectory[computerId]
if programToRun then
---@diagnostic disable-next-line: undefined-global
    shell.run(programToRun)
end