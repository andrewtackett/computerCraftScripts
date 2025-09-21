-- Common utility functions
local version = { major=1, minor=0, patch=0 }


-- TODO: add restocking fuel and torches
-- TODO: add compressing deepslate and other common blocks into their x1/x2/x9 forms
--        - have to have crafty turtle?
-- TODO: see if we can collect xp
-- Update tunnel (any) program wirelessly
-- Make dumpGoods program
-- Make normal commands files/updating easier


-- Ensure global APIs are recognized by linters
---@diagnostic disable-next-line: undefined-global
local turtle = turtle
---@diagnostic disable-next-line: undefined-global
local sleep = sleep
---@diagnostic disable-next-line: undefined-global
local term = term
---@diagnostic disable-next-line: undefined-global
local colors = colors
---@diagnostic disable-next-line: undefined-global
local fs = fs
---@diagnostic disable-next-line: undefined-global
local shell = shell
---@diagnostic disable-next-line: undefined-global
local http = http

-- Color codes reference:

-- colors.white	    1	    0x1	    0		#F0F0F0	240, 240, 240	
-- colors.orange	2	    0x2	    1		#F2B233	242, 178, 51	
-- colors.magenta	4	    0x4	    2		#E57FD8	229, 127, 216	
-- colors.lightBlue	8	    0x8	    3		#99B2F2	153, 178, 242	
-- colors.yellow	16	    0x10	4		#DEDE6C	222, 222, 108	
-- colors.lime	    32	    0x20	5		#7FCC19	127, 204, 25	
-- colors.pink	    64	    0x40	6		#F2B2CC	242, 178, 204	
-- colors.gray	    128	    0x80	7		#4C4C4C	76, 76, 76	
-- colors.lightGray	256	    0x100	8		#999999	153, 153, 153	
-- colors.cyan	    512	    0x200	9		#4C99B2	76, 153, 178	
-- colors.purple	1024	0x400	a		#B266E5	178, 102, 229	
-- colors.blue	    2048	0x800	b		#3366CC	51, 102, 204	
-- colors.brown	    4096	0x1000	c		#7F664C	127, 102, 76	
-- colors.green	    8192	0x2000	d		#57A64E	87, 166, 78	
-- colors.red	    16384	0x4000	e		#CC4C4C	204, 76, 76	
-- colors.black     32768	0x8000	f		#191919	25, 25, 25

local info_color    = colors.lightBlue
local warning_color = colors.orange
local error_color   = colors.red
local success_color = colors.green
local verbose_color = colors.purple
local debug_color   = colors.gray
local default_color = colors.green

-- t = {[1]=true, [2]=true}
-- t = { name = "minecraft:oak_log", state = { axis = "x" }, tags = { ["minecraft:logs"] = true }}
-- t = { [1] = true, [2] = true }

local function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end

local function readConfigFile(file_name)
    file_name = file_name or "config.cfg"
    local config = {}
    local file = fs.open(file_name, "r")
    local line = file.readLine()
    while line do
        local pair = split(line,":")
        config[pair[1]] = pair[2]
        line = file.readLine()
    end
    file.close()
    return config
end

local function log(msg, level, loggingMode)
    local config = readConfigFile()
    level = level or "info"
    loggingMode = loggingMode or config["loggingMode"] or "normal"
    local color = info_color
    if level == "warning" then
        color = warning_color
    elseif level == "error" then
        color = error_color
    elseif level == "success" then
        color = success_color
    elseif level == "verbose" then
        color = verbose_color
    elseif level == "debug" then
        color = debug_color
    end
    -- Implicitly filter messages based on logging mode and color
    if loggingMode == "normal" and (level == "debug" or level == "verbose") then
        return
    elseif loggingMode == "verbose" and level == "debug" then
        return
    end
    term.setTextColor(color)
    print(msg)
    term.setTextColor(default_color)
end

-- TODO
local function logWithOutputRecord(loggingMode, outputLog, msg, level)
    log(msg, level, loggingMode)
    -- TODO: write stuff to append to outputLog
end

local function throwError(msg)
    term.setTextColor(error_color)
    print(msg)
    term.setTextColor(default_color)
    error()
end

local function printWithColor(msg, color)
    term.setTextColor(color)
    print(msg)
    term.setTextColor(colors.white)
end

local function waitForFix(check_function, wait_time)
    wait_time = wait_time or 5
    while not check_function() do
        sleep(wait_time)
    end
end

local commonPastebin = "QgA4Vxi2"
local tunnelPastebin = "QwFw5crR"
local treeFarmPastebin = "wTY6LrZY"
local function downloadPastebinFile(pastebin_name, destination)
    local pastebin_id = commonPastebin
    destination = destination or (pastebin_name .. ".lua")
    if pastebin_name == "tunnel" then
        pastebin_id = tunnelPastebin
    elseif pastebin_name == "treeFarm" then
        pastebin_id = treeFarmPastebin
    end
    log("Downloading pastebin file " .. pastebin_name .. " to " .. destination)
    shell.run("pastebin", "get", pastebin_id, destination)
end

-- https://raw.githubusercontent.com/andrewtackett/computerCraftScripts/main/common.lua
local function downloadFileFromGithub(repo, file_path, destination)
    destination = destination or file_path
    local url = "https://raw.githubusercontent.com/" .. repo .. "/main/" .. file_path
    log("Downloading " .. file_path .. " from " .. url)
    local response = http.get(url)
    if response then
        local file = fs.open(destination, "w")
        file.write(response.readAll())
        file.close()
        response.close()
        log("Downloaded " .. file_path .. " to " .. destination)
    else
        throwError("Failed to download " .. file_path)
    end
end

local function upsertProgram(filename_or_path, destination)
    destination = destination or filename_or_path
    local temp_file = "tmp_" .. destination
    downloadFileFromGithub("andrewtackett/computerCraftScripts", filename_or_path, temp_file)
    fs.delete(destination)
    fs.move(temp_file, destination)
    log("Installed " .. destination)
end

local function updateAll(get_commands)
    get_commands = get_commands or false
    local programs = { 
        [1] = "treeFarm.lua",
        [2] = "tunnel.lua",
        [3] = "turtleCommon.lua",
        [4] = "common.lua"
    }
    for i=1,4 do
        log("Update all: " .. programs[i])
        upsertProgram(programs[i])
        sleep(1)
    end
    if get_commands then
        local commands = {
            [1] =  "back.lua",
            [2] =  "down.lua",
            [3] =  "forward.lua",
            [4] =  "left.lua",
            [5] =  "printfuel.lua",
            [6] =  "refuel.lua",
            [7] =  "right.lua",
            [8] =  "select.lua",
            [9] =  "tleft.lua",
            [10] = "tright.lua",
            [11] = "up.lua",
            [12] = "update.lua",
            [13] = "updateAll.lua",
            [14] = "coordinates.lua"
        }
        for i=1,11 do
            log("Update all commands: " .. commands[i])
            upsertProgram("commands/" .. commands[i], commands[i])
            sleep(1)
        end
    end
end

local function printProgramStartupWithVersion(program_name, program_version)
    ---@diagnostic disable-next-line: undefined-field
    local currentComputerName = os.getComputerLabel()
    log("Starting " .. program_name .. " v" .. program_version["major"] .. "." .. program_version["minor"] .. "." .. program_version["patch"] .. " on " .. currentComputerName)
end

local function findLastOpenInventorySlot(inventory_size, items)
    for i = inventory_size, 2, -1 do
        if items[i] == nil then
            return i
        end
    end
    throwError("No space to rearrange fuel/items in chest!")
end

return {
    version = version,
    split = split,
    readConfigFile = readConfigFile,
    log = log,
    logWithOutputRecord = logWithOutputRecord,
    throwError = throwError,
    printWithColor = printWithColor,
    waitForFix = waitForFix,
    downloadPastebinFile = downloadPastebinFile,
    downloadFileFromGithub = downloadFileFromGithub,
    upsertProgram = upsertProgram,
    updateAll = updateAll,
    printProgramStartupWithVersion = printProgramStartupWithVersion,
    findLastOpenInventorySlot = findLastOpenInventorySlot,
}