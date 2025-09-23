---@diagnostic disable-next-line: undefined-field
local computerId = os.getComputerId()
local programDirectory = {
    [6] = "attack",
    [7] = "attack",
    [1] = "treeFarm"
}
local programToRun = programDirectory[computerId]
if programToRun then
---@diagnostic disable-next-line: undefined-global
    shell.run(programToRun)
end