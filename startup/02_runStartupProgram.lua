local computerId = os.getComputerId()
local programDirectory = {
    [1] = "attack",
    [2] = "attack",
    [3] = "treeFarm"
}
local programToRun = programDirectory[computerId]
if programToRun then
    shell.run(programToRun)
end