-- grandMA3 Plugin: Tater Setlist Manager
-- Author: Tater
-- Plugin Version: 1.1.2
-- Please send any bugs to Tater@LXTater.com
-- Updated 4/6/2025
-- Verified working for MA3 V 2.2.5.0

return function()

  -------------------------------------------------------------------
  -- Retrieves the stored global macro range (start and end slots)
  -------------------------------------------------------------------
  local function getStoredRange()
    local start = tonumber(GetVar(GlobalVars(), "TaterSetlistMacroStart") or "")
    local finish = tonumber(GetVar(GlobalVars(), "TaterSetlistMacroEnd") or "")
    return start, finish
  end

  ------------------------------------------------------------------------------------
  -- Builds a list of macro slot numbers and their names from the stored slot range
  -- Ignores duplicate macro names
  ------------------------------------------------------------------------------------
  local function getMacroSetlist()
    local start, finish = getStoredRange()
    local slots, names = {}, {}

    if not start or not finish then return slots, names end

    local seen = {} -- Used to track duplicate names
    for i = start, finish do
      local macro = DataPool().Macros[i]
      if macro and macro.name and macro.name ~= "" then
        if not seen[macro.name] then
          table.insert(slots, tostring(i))        -- Save slot number
          table.insert(names, macro.name)         -- Save macro name
          seen[macro.name] = true                 -- Mark as seen
        else
          -- Warn about duplicate macro names
          ErrPrintf("[TaterSetlistMgr][Warning]: Duplicate macro name: '%s' in slot %d. Skipping.", macro.name, i)
        end
      end
    end

    return slots, names
  end

  ----------------------------------------------------------------------------------------
  -- Updates the "Command" field of a cue in each sequence to call the next macro in list
  ----------------------------------------------------------------------------------------
  local function updateSequences(nameList)
    local TaterLastCue = tonumber(GetVar(GlobalVars(), "TaterSetlistCue") or "500")

    -- If the list is too short, abort
    if #nameList < 2 then
      ErrPrintf("[TaterSetlistMgr][Error]: Setlist invalid or empty. Set macro range first.")
      return
    end

    -- Go through each macro name and apply command to associated sequence
    for i = 1, #nameList - 1 do
      local current = nameList[i]
      local nextOne = nameList[i + 1]
      local seq = DataPool().Sequences:Find(current) -- Find sequence by macro name
      if seq then
        Cmd('Select Sequence "' .. seq.name .. '"')
        Cmd('Set Cue ' .. TaterLastCue .. ' Property "Command" "Go+ Macro ' .. nextOne .. '"')
        Printf("[TaterSetlistMgr]: Updated '%s' Cue %d CMD to: Go+ Macro %s", seq.name, TaterLastCue, nextOne)
      else
        -- Sequence not found
        ErrPrintf("[TaterSetlistMgr][Error]: Sequence '%s' not found. Skipping.", current)
      end
    end
  end

  ----------------------------------------------------------------------------------------
  -- Prompts the user to define a new macro slot range and saves it to global variables
  ----------------------------------------------------------------------------------------
  local function setMacroRange()
    local oldStart, oldEnd = getStoredRange()
    
    -- If range already exists, ask for confirmation to overwrite
    if oldStart and oldEnd then
      local confirm = MessageBox({
        title = "Overwrite Setlist?",
        message = string.format("Current range is: %d– thru %d\nThis will overwrite it.\nContinue?", oldStart, oldEnd),
        commands = {
          { value = 1, name = "Yes" },
          { value = 2, name = "Cancel" }
        }
      })
      if confirm.result ~= 1 then
        Printf("[TaterSetlistMgr]: Range change cancelled.")
        return mainMenu()
      end
    end

    -- Get user input for range
    local start = tonumber(TextInput("Enter starting macro slot:", "1")) or 1
    local finish = tonumber(TextInput("Enter ending macro slot:", "15")) or 15

    -- Validate range
    if finish - start < 1 then
      ErrPrintf("[TaterSetlistMgr][Error]: Macro range must include at least 2 macros.")
      return mainMenu()
    end

    -- Save range
    SetVar(GlobalVars(), "TaterSetlistMacroStart", tostring(start))
    SetVar(GlobalVars(), "TaterSetlistMacroEnd", tostring(finish))
    Printf("[TaterSetlistMgr]: Saved macro range: %d–%d", start, finish)

    mainMenu()
  end

  ----------------------------------------------------------------------------------------
  -- Prompts the user to set the cue number to assign the Go+ Macro command
  ----------------------------------------------------------------------------------------
  local function setCueNumber()
    local currentCue = tonumber(GetVar(GlobalVars(), "TaterSetlistCue") or "500")
    local newCue = tonumber(TextInput("Enter Cue Number to Use (default 500):", tostring(currentCue)))

    if not newCue then
      Printf("[TaterSetlistMgr]: Cue number not changed.")
      return mainMenu()
    end

    SetVar(GlobalVars(), "TaterSetlistCue", tostring(newCue))
    Printf("[TaterSetlistMgr]: Cue number set to %d", newCue)

    mainMenu()
  end

  ----------------------------------------------------------------------------------------
  -- Main menu displayed to the user for plugin interaction
  ----------------------------------------------------------------------------------------
  function mainMenu()
    local TaterLastCue = tonumber(GetVar(GlobalVars(), "TaterSetlistCue") or "500")
    local slotList, nameList = getMacroSetlist()

    local msg = ""
    if #nameList > 0 then
      -- Show current macro range and setlist
      msg = "Current Setlist (from saved range):\n"
      for i = 1, #slotList do
        msg = msg .. string.format("  %s: %s\n", slotList[i], nameList[i])
      end
    else
      -- No data or range not set
      msg = "No macro range set, or range is empty."
    end

    -- Display menu
    local box = MessageBox({
      title = "Tater Setlist Manager",
      message = msg,
      commands = {
        { value = 1, name = "Set Macro Range" },
        { value = 2, name = "Update Setlist" },
        { value = 3, name = "SetLastCue (" .. TaterLastCue .. ")" },
        { value = 4, name = "Cancel" }
      }
    })

    -- Menu selection handling
    if box.result == 1 then
      setMacroRange()
    elseif box.result == 2 then
      local _, updatedNameList = getMacroSetlist()
      updateSequences(updatedNameList)
    elseif box.result == 3 then
      setCueNumber()
    else
      Printf("[TaterSetlistMgr][Other]: Cancelled.")
    end
  end

  -- Run the main menu when plugin is launched
  mainMenu()
end
