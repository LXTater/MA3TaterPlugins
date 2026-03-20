-- grandMA3 Plugin: TaterFaderXGroupSettings
-- Author: LXTater
-- Version: 0.0.2
-- Opens the setup wizard and saves settings to GlobalVars.
-- The main TaterFaderXGroup plugin detects the change and hot-reloads.

-- GlobalVar keys (must match main plugin)
local GV_RUN       = "taterFaderXGroupRun"
local GV_EXEC      = "taterFaderXGroupExec"
local GV_MATRICKS  = "taterFaderXGroupMATricks"
local GV_HIGH      = "taterFaderXGroupHighValue"
local GV_LOW       = "taterFaderXGroupLowValue"
local GV_STEP      = "taterFaderXGroupStepSize"
local GV_CHANGED   = "taterFaderXGroupSettingsChanged"

local DEFAULT_EXEC      = "102.202"
local DEFAULT_MATRICKS  = "1"
local DEFAULT_HIGH      = "20"
local DEFAULT_LOW       = "1"
local DEFAULT_STEP      = "1"

local function getGV(key, default)
    local val = GetVar(GlobalVars(), key)
    if val == nil or val == "" then return default end
    return tostring(val)
end

return function()
    -- Read current saved values as defaults
    local savedExec     = getGV(GV_EXEC, DEFAULT_EXEC)
    local savedMAtricks = getGV(GV_MATRICKS, DEFAULT_MATRICKS)
    local savedHigh     = getGV(GV_HIGH, DEFAULT_HIGH)
    local savedLow      = getGV(GV_LOW, DEFAULT_LOW)
    local savedStep     = getGV(GV_STEP, DEFAULT_STEP)

    local result = MessageBox({
        title = "TaterFaderTricks — XGroup Settings",
        icon = "object_smart",
        titleTextColor = "Global.Focus",
        message = "Change settings while the plugin is running.\n\n"
                .. "The main plugin will hot-reload automatically.\n"
                .. "Executor format: page.executor (e.g. 102.202)",
        message_align_h = Enums.AlignmentH.Left,

        commands = {
            { value = 1, name = "Save" },
            { value = 0, name = "Cancel" },
        },

        inputs = {
            { name = "Executor",       value = savedExec,     whiteFilter = "1234567890.", vkPlugin = "NumericInput", maxTextLength = 10 },
            { name = "MATricksPreset", value = savedMAtricks, whiteFilter = "1234567890",  vkPlugin = "NumericInput", maxTextLength = 5 },
            { name = "HighValue",      value = savedHigh,     whiteFilter = "1234567890",  vkPlugin = "NumericInput", maxTextLength = 5 },
            { name = "LowValue",       value = savedLow,      whiteFilter = "1234567890",  vkPlugin = "NumericInput", maxTextLength = 5 },
            { name = "StepSize",       value = savedStep,     whiteFilter = "1234567890",  vkPlugin = "NumericInput", maxTextLength = 5 },
        },
    })

    if not result or result.result ~= 1 then
        Printf("TaterFaderTricks Settings: Cancelled.")
        return
    end

    -- Parse executor
    local execInput = result.inputs.Executor or DEFAULT_EXEC
    local dotPos = string.find(execInput, "%.")
    if not dotPos then
        Printf("TaterFaderTricks Settings: ERROR — Use page.executor format (e.g. 102.202)")
        return
    end

    local parsedPage = tonumber(string.sub(execInput, 1, dotPos - 1))
    local parsedExec = tonumber(string.sub(execInput, dotPos + 1))
    if not parsedPage or not parsedExec then
        Printf("TaterFaderTricks Settings: ERROR — Could not parse '%s'", execInput)
        return
    end

    local lowVal  = tonumber(result.inputs.LowValue)  or 1
    local highVal = tonumber(result.inputs.HighValue)  or 20
    if lowVal >= highVal then
        Printf("TaterFaderTricks Settings: ERROR — Low (%d) must be less than High (%d)", lowVal, highVal)
        return
    end

    -- Save all settings to GlobalVars
    SetVar(GlobalVars(), GV_EXEC,     execInput)
    SetVar(GlobalVars(), GV_MATRICKS, result.inputs.MATricksPreset or DEFAULT_MATRICKS)
    SetVar(GlobalVars(), GV_HIGH,     result.inputs.HighValue or DEFAULT_HIGH)
    SetVar(GlobalVars(), GV_LOW,      result.inputs.LowValue or DEFAULT_LOW)
    SetVar(GlobalVars(), GV_STEP,     result.inputs.StepSize or DEFAULT_STEP)
    SetVar(GlobalVars(), GV_RUN,      "1")

    -- Signal the main plugin to hot-reload
    SetVar(GlobalVars(), GV_CHANGED, "1")

    Printf("TaterFaderTricks Settings: Saved! Main plugin will reload on next tick.")
end