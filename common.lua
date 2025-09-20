-- Common utility functions
local version = { major=1, minor=0, patch=0 }

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

local commonPastebin = "QgA4Vxi2"
local tunnelPastebin = "QwFw5crR"
local treeFarmPastebin = "wTY6LrZY"

local function upsertPastebinScript(pastebin_id, file_name)
    local temp_file = "tmp_" .. file_name
    local fileModule = require(file_name)
    local newFileModule = require(temp_file)
    if newFileModule.version.major >= fileModule.version.major or
       newFileModule.version.minor >= fileModule.version.minor or
       newFileModule.version.patch >= fileModule.version.patch then
        print("Updating " .. file_name .. " from pastebin...")
        fs.delete(file_name)
        fs.move(temp_file, file_name)
        print("Updated " .. file_name)
        print("Old version: " .. fileModule.version.major .. "." .. fileModule.version.minor .. "." .. fileModule.version.patch)
        print("New version: " .. newFileModule.version.major .. "." .. newFileModule.version.minor .. "." .. newFileModule.version.patch)
    else
        fs.delete(temp_file)
        print(file_name .. " is up to date.")
    end
    shell.run("pastebin", "get", pastebin_id, file_name)
end

local function getCurrentFileName()
    local fileWithPath = debug.getinfo(1, "S").source
    local programName = fileWithPath:match("[^/]*.lua$")
    return programName:sub(0, #programName - 4)
end

local function printProgramStartupWithVersion()
    local currentFileName = getCurrentFileName()
---@diagnostic disable-next-line: undefined-field
    local currentComputerName = os.getComputerLabel()
    print("Starting " .. currentFileName .. 
        " v" .. version["major"] .. "." .. version["minor"] .. "." .. version["patch"]
        .. " on " .. currentComputerName
    )
end

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


-- TODO: add restocking fuel and torches
-- TODO: add compressing deepslate and other common blocks into their x1/x2/x9 forms
--        - have to have crafty turtle?
-- TODO: see if we can collect xp
-- Update tunnel (any) program wirelessly
-- Make dumpGoods program


local function log(loggingMode, msg, level)
    level = level or "info"
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

-- Example in local file to wrap:
-- local loggingMode = config["loggingMode"] or "normal"
-- local common = require("common")
-- local function log(msg, level)
--     common.log(loggingMode, msg, level)
-- end

local function logWithOutputRecord(loggingMode, outputLog, msg, level)
    log(loggingMode, msg, level)
    -- TODO: write stuff to append to outputLog
end

local function throwError(msg)
    term.setTextColor(colors.red)
    print(msg)
    term.setTextColor(colors.white)
    error()
end

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

local function printWithColor(msg, color)
    term.setTextColor(color)
    print(msg)
    term.setTextColor(colors.white)
end

local function waitForFix(checkFunction)
    while not checkFunction() do
        sleep(5)
    end
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
    upsertPastebinScript = upsertPastebinScript,
    getCurrentFileName = getCurrentFileName,
    printProgramStartupWithVersion = printProgramStartupWithVersion,
    log = log,
    logWithOutputRecord = logWithOutputRecord,
    throwError = throwError,
    split = split,
    readConfigFile = readConfigFile,
    printWithColor = printWithColor,
    waitForFix = waitForFix,
    findLastOpenInventorySlot = findLastOpenInventorySlot,
    commonPastebin = commonPastebin,
    tunnelPastebin = tunnelPastebin,
    treeFarmPastebin = treeFarmPastebin,
}