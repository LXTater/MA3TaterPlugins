-- grandMA3 Plugin: TaterFader
-- Description: Fades Group Master to specified intensity over specified duration. The plugin will popup an error if a group has no executor assigned.
-- If you do not want the error popup, change the variable labled errorPopupEnabled to 0. It will still print to console.
-- Author: LXTater
-- Thank you forums user stevegiovanazzi
-- Utilizing his clock to determine values + this is basically a more feature rich version of his code  https://forum.malighting.com/forum/thread/69307-group-master-command-line-fade/?postID=84711#post84711
-- Version: 1.6.3
-- MA3 Version 2.3.2.0


--[[ How to Use:
    Import the plugin into your plugin data pool. Anywhere will work.
    Edit any settings that you wish.
    Make sure the group you wish to fade has an executor assigned to it.
        Assign Group X at Page y.z, etc
    Either in command line, with a macro, or as a cue command
    Call the function with the following parameters:
    TaterFader(Group Name or Number, Intensity, Duration)
        Example: TaterFader(1, 50, 5)  -- This will fade group 1 to 50% over 5 seconds.

        You can run multiple fades at once with this function. In testing, I have really only tried 5 or 6 groups at once.
        Technically unlimited amounts can run at a time, not sure how resource intensive that might be.

    
    
    
    --Extra Notes
    Still working on adding more features, but the core functionality is there.
    Dimmer Curves work mathmatically, however, having issues with calling multiples. For now, don't mess with dim curves
    For now, dimmer curves are a hidden setting. You can call dimmer curves with an additional parameter when calling the function.
    Example: TaterFader(1, 50, 5, "square")  -- This will fade group 1 to 50% over 5 seconds using a square dimmer curve.

]]

--TaterFader Settings --
-- Please only change these if needed/desired.
-- Default settings listed here:
--[[
DEFAULT: local errorPopupEnabled = 1             
DEFAULT: local errorPopupTimeout = 8000


]]

local errorPopupEnabled = 1 -- 1 = Enable Error Popup 0 = Disable Error Popup.
local errorPopupTimeout = 8000 -- Set timeout for error popup in milliseconds.
local defaultDuration = 3 -- Default duration for fade in seconds if user does not specify.
local defaultIntensity = 100 -- Default intensity for fade if user does not specify. 0-100%



--ADVANCED SETTINGS--
-- These settings are more advanced, and have not been tested on all version of MA3 software. I reccomend leaving these as default, unless you have time to mess around.

--fadeSmoothness : Higher number = smoother fade, but more CPU usage. Lower number = choppier fade, but less CPU usage.
local fadeSmoothness = 120
--local defaultDimCurve = "linear" -- Set default dimmer curve (linear, square, invsquare,scurve)


--DEFAULT: local fadeSmoothness = 120


-- END OF SETTINGS --




-- LXTater Helpers --

local function msg(s)        Printf("[TaterFader] %s", s) end --Easily create console messages that are organized
  local function err(s)        ErrPrintf("[TaterFader] %s", s) end --Easily create error messages that are organized
  local function trim(s)       return (tostring(s or ""):gsub("^%s+"," "):gsub("%s+$"," ")) end --Returns inpuit stirng with leading and trailing whitespace with just a single space.
  local function toInt(s)      s = trim(s); local n = tonumber(s); return n and math.floor(n) or nil end --Safely converts input to an integer or return nill

  local function safeCmdIndirect(s)  --This is just a simple function to catch errors from Cmd calls.
    local ok, why = pcall(CmdIndirect, s)
    if not ok then err("Cmd failed: " .. tostring(s) .. " -> " .. tostring(why)) end
    return ok
  end

  local function groupSeemsToExist(num)  --Checks if group exists
    local ok, dp = pcall(DataPool)
    if not ok or not dp or not dp.Groups then return true end
    return dp.Groups[num] ~= nil
  end

-- End of LXTater Helpers --

-- Plugin Specific Helpers --
-- End of Plugin Specific Helpers --

local ErrorGroupObj = {} -- Create variable for error groups.


function faderMasterExists(taterFaderGroup)      --This is kind of a brute force method to check if a fader master exists for the group, if it does exists we can find out the number and name. There's 100% a better way to do this lol
    local groupHandle = DataPool().Groups[taterFaderGroup]
    if not groupHandle then
        Printf("Group %s does not exist", tostring(taterFaderGroup)) --Redudent error check, but just in case
        return false, nil
    end
    local refs = groupHandle:GetReferences()  --Gets all references to the group.
    if refs then
        for _, ref in ipairs(refs) do
            if ref:GetClass() == "Exec" then --If "Exec =" is found, we have an executor assigned to the group.
                local page = ref:Parent()
                if page then
                        local execPageNo = page.no  --Set variables for exec page and exec number
                        local execExecNo = ref.no
                        local value = groupHandle:GetFader({token="FaderMaster"}) --Get initial fader value
                        local masterValue = value and string.format("%.0f%%", value) or "null" --If value exists, format it, else set to null
                    return true, value -- Return true and initial fader value
                end
            end
        end
    end
    -- If no exec found, add to error table
    local groupNum = groupHandle.no or tostring(taterFaderGroup)
    local groupName = groupHandle.name or tostring(taterFaderGroup)
    local entry = string.format("%s (%s)", groupName, groupNum)
    local found = false --found defaults to false, if exec is found we set this to true. If no exec, will 100% remain false.
    for _, v in ipairs(ErrorGroupObj) do
        if v == entry then found = true break end -- 
    end
    if not found then table.insert(ErrorGroupObj, entry) end --inserts to table if not found, or another error preventing the plugin from reading the Exec from the refrences.
    return false, nil
end

--[[ Broken Corutine??
function CoruTaterFader(taterFadeGroup, taterIntensity, taterDuration, taterCurveType) --Corutine to enable the plugin to run multiple group fades, across multiple groups at once.
    local co = coroutine.create(function()
        TaterFader(taterFadeGroup, taterIntensity, taterDuration, taterCurveType)
    end)
    coroutine.resume(co)
    return co
end
    local function applyCurve(progress, taterCurveType)  --Simple dimmer curves. Default is linear.
        if taterCurveType == nil then taterCurveType = defaultDimCurve end   
        if taterCurveType == "square" then
                return progress * progress
            elseif taterCurveType == "invsquare" then
                return 1 - (1 - progress) * (1 - progress)
            elseif taterCurveType == "scurve" then
                -- Simple S-curve using smoothstep
                return progress * progress * (3 - 2 * progress)
            else -- linear or unknown
                return progress
            end
        end
        --]]
function TaterFader(taterFadeGroup, taterIntensity, taterDuration, taterCurveType)
    if taterDuration == nil then taterDuration = defaultDuration end
    if taterIntensity == nil then taterIntensity = defaultIntensity end
    if taterCurveType == nil then taterCurveType = defaultDimCurve end
    if not taterCurveType then taterCurveType = "linear" end -- Default to linear

    local success, errMsg = pcall(function()
        local updates_per_second = fadeSmoothness
        local interval = 1 / updates_per_second

        if type(taterIntensity) ~= "number" or type(taterDuration) ~= "number" then
            err("taterIntensity and taterDuration must be numbers")
            return
        end

        local groupObj
        do
            local ok, dp = pcall(DataPool)
            if not ok or not dp or not dp.Groups then
                err("Unable to access group data.")
                return
            end

            if type(taterFadeGroup) == "number" then
                groupObj = dp.Groups[taterFadeGroup]
            elseif type(taterFadeGroup) == "string" then
                for i, g in ipairs(dp.Groups:Children() or {}) do
                    if g.name and g.name:lower() == taterFadeGroup:lower() then
                        groupObj = g
                        break
                    end
                end
            end

            if not groupObj then
                err("Group not found: " .. tostring(taterFadeGroup))
                return
            end
        end

        local hasExec, initial_value = faderMasterExists(groupObj.no or tostring(taterFadeGroup))
        if not hasExec then
            msg("Warning: No Exec assigned for group: " .. (groupObj.name or tostring(taterFadeGroup)))
        end

        if not hasExec or initial_value == nil then
            if #ErrorGroupObj > 0 then
                local ErrorFaderGroups = table.concat(ErrorGroupObj, ", ")
                MessageBox({
                    title = 'TaterFader Error!',
                    icon = 'warning_triangle_big',
                    message = string.format(
                        "No Valid Executor Error\nPlease assign the group to an executor, and try again.\nError Group(s):\n %s",
                        ErrorFaderGroups
                    ),
                    messageTextColor = 'Global.AlertText',
                    autoCloseOnInput = false,
                    timeout = errorPopupTimeout,
                    timeoutResultCancel = true,
                    commands = {{
                        value = 1,
                        name = 'Exit'
                    }},
                })
                ErrorGroupObj = {}
            end
            return
        end

        -- Fade loop with curve
        local fade_start = os.clock()
        local fade_end = fade_start + taterDuration

        while true do
            local now = os.clock()
            if now >= fade_end then break end

            local progress = (now - fade_start) / taterDuration
            if progress > 1 then progress = 1 end
            local curved = applyCurve(progress, taterCurveType)
            local value = initial_value + (taterIntensity - initial_value) * curved

            groupObj:SetFader({value = value, token = "FaderMaster"})
            coroutine.yield(interval)
        end

        groupObj:SetFader({value = taterIntensity, token = "FaderMaster"})
        msg("Completed fade for Group: " .. (groupObj.name or tostring(taterFadeGroup)))
    end)
    if not success then
        err("Fade coroutine crashed: " .. tostring(errMsg))
    end
end