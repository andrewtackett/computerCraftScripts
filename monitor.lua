--- Monitor Utility Functions

---@diagnostic disable-next-line: undefined-global
local term = term
local version = { major=1, minor=0, patch=0 }

local function resetText()
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
end

return {
    version = version,
}