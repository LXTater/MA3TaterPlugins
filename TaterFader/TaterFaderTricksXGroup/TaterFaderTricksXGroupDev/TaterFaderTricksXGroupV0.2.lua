    -- grandMA3 Plugin: TaterFaderTricksXGroups
    -- Author: LXTater
    -- Version: 0.0.2
    -- Github: https://github.com/LXTater/TaterFaderTricks
    -- www.LXTater.com


    --[[ Version History:
    ---------------  
        ---------------
        |Version 0.0.2|
        ---------------
    ---------------
        Changelog:
            -Version 0.0.1
                *Initial baseline plugin for debug/testing
                *MessageBox setup wizard: executor (page.exec format), high/low values, step size
                *Coroutine loop that monitors fader value at ~10Hz
                *Change detection with direction (up/down)
                *Maps fader 0-100 to lowValue-highValue, rounded to step size
                *Updates MATricks XGroup via Cmd on value change
                *Toggle start/stop via GlobalVar "taterFaderTricksRunning"
                *ClearAll + store blank cue on selected executor at startup
                *MATricks preset selection — edits XGroup directly via Lua datapool
            -Version 0.0.2
                *Settings persisted to GlobalVars (taterFaderXGroupExec, MATricks, HighValue, LowValue, StepSize)
                *taterFaderXGroupRun GlobalVar controls wizard: 0 = show wizard, 1 = skip to monitoring
                *Wizard defaults pre-populated from saved GlobalVars
                *Running plugin again after first setup skips straight to fader monitoring
                *Separate reset plugin can set taterFaderXGroupRun to 0 to re-open wizard
            -Version 0.0.3
                *Hot-reload: main loop checks taterFaderXGroupSettingsChanged GlobalVar each tick
                *Separate TaterFaderXGroupSettings plugin opens wizard, saves to GlobalVars, sets changed flag
                *Main plugin reloads config without stopping when settings change
                *No plugin-calling-plugin — settings plugin is fully standalone
    ---------------
    Known Bugs:
            *NONE... Yet!
    ---------------        
        TODO:
            *Test fader reading on real hardware
            *Verify direct Lua property write on MAtricks (fallback to Cmd if sandbox blocks it)
            *Add GUI settings page (overlay) if needed
            *Add support for multiple fader-to-MATricks mappings
            *Helpers component integration
    --]]


    -- ============================================================================
    -- GLOBALVAR KEYS & DEFAULTS
    -- ============================================================================

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

    --- Read a GlobalVar with a fallback default
    local function getGV(key, default)
        local val = GetVar(GlobalVars(), key)
        if val == nil or val == "" then
            return default
        end
        return tostring(val)
    end

    --- Save all config values to GlobalVars
    local function saveConfigToGlobalVars(config)
        SetVar(GlobalVars(), GV_EXEC,     config.pageNum .. "." .. config.executorNum)
        SetVar(GlobalVars(), GV_MATRICKS, tostring(config.matricksPreset))
        SetVar(GlobalVars(), GV_HIGH,     tostring(config.highValue))
        SetVar(GlobalVars(), GV_LOW,      tostring(config.lowValue))
        SetVar(GlobalVars(), GV_STEP,     tostring(config.stepSize))
        SetVar(GlobalVars(), GV_RUN,      "1")
        Printf("TaterFaderTricks: Settings saved to GlobalVars")
    end

    --- Parse a page.executor string into config table
    local function parseExecString(execInput)
        local dotPos = string.find(execInput, "%.")
        if not dotPos then return nil, nil end
        local parsedPage = tonumber(string.sub(execInput, 1, dotPos - 1))
        local parsedExec = tonumber(string.sub(execInput, dotPos + 1))
        return parsedPage, parsedExec
    end

    --- Build config from GlobalVars (for skipping wizard)
    local function loadConfigFromGlobalVars()
        local execStr = getGV(GV_EXEC, DEFAULT_EXEC)
        local parsedPage, parsedExec = parseExecString(execStr)

        if not parsedPage or not parsedExec then
            Printf("TaterFaderTricks: ERROR — Could not parse saved executor '%s'", execStr)
            return nil
        end

        local config = {
            pageNum         = parsedPage,
            executorNum     = parsedExec,
            matricksPreset  = tonumber(getGV(GV_MATRICKS, DEFAULT_MATRICKS)) or 1,
            highValue       = tonumber(getGV(GV_HIGH, DEFAULT_HIGH)) or 20,
            lowValue        = tonumber(getGV(GV_LOW, DEFAULT_LOW)) or 1,
            stepSize        = tonumber(getGV(GV_STEP, DEFAULT_STEP)) or 1,
        }

        if config.lowValue >= config.highValue then
            Printf("TaterFaderTricks: ERROR — Saved Low (%d) >= High (%d)", config.lowValue, config.highValue)
            return nil
        end
        if config.stepSize < 1 then config.stepSize = 1 end

        return config
    end


    -- ============================================================================
    -- CONFIG / SETUP
    -- ============================================================================

    local tick = 1 / 10  -- Check fader ~10 times per second

    -- ============================================================================
    -- HELPER FUNCTIONS
    -- ============================================================================

    --- Map a fader value (0-100) into the lowValue..highValue range
    -- @param faderVal  number  Raw fader value 0-100
    -- @param lowVal    number  Output when fader is at 0
    -- @param highVal   number  Output when fader is at 100
    -- @return number   Mapped value (not yet rounded)
    local function mapFaderToRange(faderVal, lowVal, highVal)
        -- Clamp fader to 0-100
        faderVal = math.max(0, math.min(100, faderVal))
        return lowVal + (faderVal / 100) * (highVal - lowVal)
    end

    --- Round a value to the nearest step, respecting direction
    -- @param value     number  The mapped value
    -- @param step      number  Step size
    -- @param goingUp   bool    true = round up (ceil), false = round down (floor)
    -- @return number   Rounded value
    local function roundToStep(value, step, goingUp)
        if step <= 0 then return value end
        if goingUp then
            return math.ceil(value / step) * step
        else
            return math.floor(value / step) * step
        end
    end

    --- Read the fader value of a specific executor number on a given page
    -- @param pageIndex number  Page index
    -- @param execNum   number  Executor number (e.g. 101, 201)
    -- @return number   Fader value 0-100, or 0 if not found
    local function readFaderValue(pageIndex, execNum)
        local page = DataPool().Pages[pageIndex]
        if not page then
            Printf("TaterFaderTricks: Page %d not found", pageIndex)
            return 0
        end

        local executors = page:Children()
        for _, exec in pairs(executors) do
            if exec.No == execNum then
                local faderOptions = {}
                faderOptions.value = faderEnd
                faderOptions.token = "FaderMaster"
                faderOptions.faderDisabled = false
                return exec:GetFader(faderOptions)
            end
        end

        Printf("TaterFaderTricks: Executor %d not found on page %d", execNum, pageIndex)
        return 0
    end

    --- Read the MAtricks preset object from the datapool
    -- @param presetNum number  MAtricks preset number (1-based pool index)
    -- @return table|nil  MAtricks object, or nil if not found
    local function getMAtricksPreset(presetNum)
        local pool = DataPool().MAtricks
        if not pool then
            Printf("TaterFaderTricks: MAtricks pool not found in DataPool")
            return nil
        end
        local preset = pool[presetNum]
        if not preset then
            Printf("TaterFaderTricks: MAtricks preset %d not found", presetNum)
            return nil
        end
        return preset
    end

    --- Set the XGroup value on a MAtricks preset via direct Lua datapool write
    -- @param preset    table   MAtricks preset object from getMAtricksPreset()
    -- @param value     number  XGroup value to set
    -- @return boolean  true if write succeeded
    local function setMAtricksXGroup(preset, value)
        -- Attempt direct Lua property write on the datapool object
        -- This avoids Cmd() overhead in the coroutine loop
        local ok, err = pcall(function()
            preset.XGroup = value
        end)

        if not ok then
            -- If the sandbox blocks direct writes, log the error once
            Printf("TaterFaderTricks: Direct Lua write failed: %s", tostring(err))
            Printf("TaterFaderTricks: Falling back to Cmd()")
            return false
        end
        return true
    end


    -- ============================================================================
    -- SETUP WIZARD (MessageBox)
    -- ============================================================================

    local function showSetupWizard()
        local result = MessageBox({
            title = "TaterFaderTricks — XGroup Setup",
            icon = "object_smart",
            titleTextColor = "Global.Focus",
            message = "Configure fader-to-MATricks XGroup mapping.\n\n"
                    .. "The fader position (0-100) will be mapped to your\n"
                    .. "Low-High value range, rounded to the step size,\n"
                    .. "and applied as the MATricks XGroup value.",
            message_align_h = Enums.AlignmentH.Left,

            commands = {
                { value = 1, name = "Start" },
                { value = 0, name = "Cancel" },
            },

            inputs = {
                { name = "Executor",       value = "102.202",  whiteFilter = "1234567890.", vkPlugin = "NumericInput", maxTextLength = 10 },
                { name = "MATricksPreset", value = "1",         whiteFilter = "1234567890",  vkPlugin = "NumericInput", maxTextLength = 5 },
                { name = "HighValue",      value = "20",        whiteFilter = "1234567890",  vkPlugin = "NumericInput", maxTextLength = 5 },
                { name = "LowValue",       value = "1",         whiteFilter = "1234567890",  vkPlugin = "NumericInput", maxTextLength = 5 },
                { name = "StepSize",       value = "1",         whiteFilter = "1234567890",  vkPlugin = "NumericInput", maxTextLength = 5 },
            },
        })

        if not result or result.result ~= 1 then
            Printf("TaterFaderTricks: Setup cancelled.")
            return nil
        end

        -- Parse page.executor format (e.g. "102.202" -> page 102, exec 202)
        local execInput = result.inputs.Executor or DEFAULT_EXEC
        local parsedPage, parsedExec = parseExecString(execInput)

        local config = {
            pageNum         = parsedPage,
            executorNum     = parsedExec,
            matricksPreset  = tonumber(result.inputs.MATricksPreset) or 1,
            highValue       = tonumber(result.inputs.HighValue)  or 20,
            lowValue        = tonumber(result.inputs.LowValue)   or 1,
            stepSize        = tonumber(result.inputs.StepSize)   or 1,
        }

        -- Sanity checks
        if config.lowValue >= config.highValue then
            Printf("TaterFaderTricks: ERROR — Low value (%d) must be less than High value (%d)", config.lowValue, config.highValue)
            return nil
        end
        if config.stepSize < 1 then
            config.stepSize = 1
        end

        return config
    end


    -- ============================================================================
    -- MAIN LOOP
    -- ============================================================================

    local function main()
        Printf("===== TaterFaderTricks XGroup v0.0.2 =====")

        -- Toggle start/stop pattern
        local runningVar = "taterFaderTricksRunning"
        if GetVar(GlobalVars(), runningVar) == true then
            Printf("TaterFaderTricks: Stopping...")
            SetVar(GlobalVars(), runningVar, false)
            return
        end

        -- Check if wizard should run or skip to saved settings
        local config = nil
        local runState = getGV(GV_RUN, "0")

        if runState == "1" then
            -- Settings already saved — skip wizard, load from GlobalVars
            Printf("TaterFaderTricks: Saved settings found, skipping wizard")
            config = loadConfigFromGlobalVars()
            if not config then
                Printf("TaterFaderTricks: ERROR — Saved settings invalid, forcing wizard")
                SetVar(GlobalVars(), GV_RUN, "0")
                config = showSetupWizard()
                if config then saveConfigToGlobalVars(config) end
            end
        else
            -- First run or reset — show wizard
            config = showSetupWizard()
            if config then saveConfigToGlobalVars(config) end
        end

        if not config then return end

        Printf("TaterFaderTricks: Config loaded:")
        Printf("  Page:            %d", config.pageNum)
        Printf("  Executor:        %d", config.executorNum)
        Printf("  MATricks Preset: %d", config.matricksPreset)
        Printf("  High Value:      %d", config.highValue)
        Printf("  Low Value:       %d", config.lowValue)
        Printf("  Step Size:       %d", config.stepSize)

        -- ClearAll from programmer, then store a blank cue on the executor
        Printf("TaterFaderTricks: Clearing programmer and storing blank cue...")
        Cmd('ClearAll')
        Cmd('Store Page ' .. config.pageNum .. '.' .. config.executorNum .. ' "TaterFaderSequ" Cue 1 /o')
        Cmd('Label Sequence "TaterFaderSequ" Cue 1 "XGroups"')
        Cmd('ClearAll')
        Printf("TaterFaderTricks: Blank cue stored on Page %d Executor %d", config.pageNum, config.executorNum)

        -- Validate MATricks preset exists in the datapool
        local matricksObj = getMAtricksPreset(config.matricksPreset)
        if not matricksObj then
            Printf("TaterFaderTricks: MATricks preset %d not found — creating it via Cmd", config.matricksPreset)
            Cmd('Store MAtricks ' .. config.matricksPreset .. ' /o')
            matricksObj = getMAtricksPreset(config.matricksPreset)
            if not matricksObj then
                Printf("TaterFaderTricks: ERROR — Could not create MATricks preset %d", config.matricksPreset)
                return
            end
        end

        -- Test if direct Lua write works on this preset
        local currentXGroup = tonumber(matricksObj.XGroup) or 0
        Printf("TaterFaderTricks: MATricks %d current XGroup = %d", config.matricksPreset, currentXGroup)
        local useLuaWrite = setMAtricksXGroup(matricksObj, currentXGroup)
        if useLuaWrite then
            Printf("TaterFaderTricks: Direct Lua datapool write confirmed working")
        else
            Printf("TaterFaderTricks: Will use Cmd() fallback for MATricks writes")
        end

        -- Mark as running
        SetVar(GlobalVars(), runningVar, true)

        -- State tracking
        local lastFaderValue = nil
        local lastMappedValue = nil
        local lastDirection = nil  -- "up", "down", or nil

        -- Use the page from config
        local pageIndex = config.pageNum
        Printf("TaterFaderTricks: Monitoring executor %d on page %d", config.executorNum, pageIndex)

        -- === MAIN COROUTINE LOOP ===
        while GetVar(GlobalVars(), runningVar) == true do

            -- Hot-reload: check if settings plugin changed GlobalVars
            if getGV(GV_CHANGED, "0") == "1" then
                SetVar(GlobalVars(), GV_CHANGED, "0")
                Printf("TaterFaderTricks: Settings changed detected, hot-reloading...")

                local newConfig = loadConfigFromGlobalVars()
                if newConfig then
                    config = newConfig
                    pageIndex = config.pageNum

                    -- Re-validate MATricks preset
                    local newMatricksObj = getMAtricksPreset(config.matricksPreset)
                    if not newMatricksObj then
                        Printf("TaterFaderTricks: MATricks preset %d not found, creating...", config.matricksPreset)
                        Cmd('Store MAtricks ' .. config.matricksPreset .. ' /o')
                        newMatricksObj = getMAtricksPreset(config.matricksPreset)
                    end
                    if newMatricksObj then
                        matricksObj = newMatricksObj
                        useLuaWrite = setMAtricksXGroup(matricksObj, tonumber(matricksObj.XGroup) or 0)
                    end

                    -- Reset tracking so next fader read triggers an update
                    lastFaderValue = nil
                    lastMappedValue = nil
                    lastDirection = nil

                    Printf("TaterFaderTricks: Hot-reload complete — Page %d, Exec %d, MATricks %d, Range %d-%d step %d",
                        config.pageNum, config.executorNum, config.matricksPreset,
                        config.lowValue, config.highValue, config.stepSize)
                else
                    Printf("TaterFaderTricks: Hot-reload failed — invalid settings, continuing with old config")
                end
            end

            -- Read current fader
            local faderVal = readFaderValue(pageIndex, config.executorNum)

            -- Check if value has changed
            if faderVal ~= lastFaderValue then
                -- Determine direction
                local direction = "up"
                if lastFaderValue ~= nil and faderVal < lastFaderValue then
                    direction = "down"
                end
                lastDirection = direction

                -- Map fader 0-100 → lowValue..highValue
                local rawMapped = mapFaderToRange(faderVal, config.lowValue, config.highValue)

                -- Round to step size based on direction
                local goingUp = (direction == "up")
                local stepped = roundToStep(rawMapped, config.stepSize, goingUp)

                -- Clamp to low/high bounds
                stepped = math.max(config.lowValue, math.min(config.highValue, stepped))

                -- Only send update if the final mapped value actually changed
                if stepped ~= lastMappedValue then
                    Printf("TaterFaderTricks: Fader=%d -> XGroup=%d (dir=%s)", faderVal, stepped, direction)

                    -- Update MATricks preset XGroup via Lua datapool or Cmd fallback
                    if useLuaWrite then
                        matricksObj.XGroup = stepped
                    else
                        Cmd('Set MAtricks ' .. config.matricksPreset .. ' Property "XGroup" ' .. stepped)
                    end

                    lastMappedValue = stepped
                end

                lastFaderValue = faderVal
            end

            -- Yield back to MA3 engine
            coroutine.yield(tick)
        end

        Printf("TaterFaderTricks: Stopped.")
    end


    return main