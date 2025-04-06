-- grandMA3 Plugin: Tater Setlist Manager
-- Author: Tater
-- Plugin Version: 1.1.2
-- Please send any bugs to Tater@LXTater.com
-- Updated 4/6/2025
-- Verified working for MA3 V 2.2.5.0

return function()

  local function getStoredRange()
    local start = tonumber(GetVar(GlobalVars(), "TaterSetlistMacroStart") or "")
    local finish = tonumber(GetVar(GlobalVars(), "TaterSetlistMacroEnd") or "")
    return start, finish
  end

  local function getMacroSetlist()
    local start, finish = getStoredRange()
    local slots, names = {}, {}

    if not start or not finish then return slots, names end

    local seen = {}
    for i = start, finish do
      local macro = DataPool().Macros[i]
      if macro and macro.name and macro.name ~= "" then
        if not seen[macro.name] then
          table.insert(slots, tostring(i))
          table.insert(names, macro.name)
          seen[macro.name] = true
        else
          ErrPrintf("[TaterSetlistMgr][Warning]: Duplicate macro name: '%s' in slot %d. Skipping.", macro.name, i)
        end
      end
    end

    return slots, names
  end

  local function updateSequences(nameList)
    local TaterLastCue = tonumber(GetVar(GlobalVars(), "TaterSetlistCue") or "500")

    if #nameList < 2 then
      ErrPrintf("[TaterSetlistMgr][Error]: Setlist invalid or empty. Set macro range first.")
      return
    end

    for i = 1, #nameList - 1 do
      local current = nameList[i]
      local nextOne = nameList[i + 1]
      local seq = DataPool().Sequences:Find(current)
      if seq then
        Cmd('Select Sequence "' .. seq.name .. '"')
        Cmd('Set Cue ' .. TaterLastCue .. ' Property "Command" "Go+ Macro ' .. nextOne .. '"')
        Printf("[TaterSetlistMgr]: Updated '%s' Cue %d CMD to: Go+ Macro %s", seq.name, TaterLastCue, nextOne)
      else
        ErrPrintf("[TaterSetlistMgr][Error]: Sequence '%s' not found. Skipping.", current)
      end
    end
  end

  local function setMacroRange()
    local oldStart, oldEnd = getStoredRange()
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

    local start = tonumber(TextInput("Enter starting macro slot:", "1")) or 1
    local finish = tonumber(TextInput("Enter ending macro slot:", "15")) or 15

    if finish - start < 1 then
      ErrPrintf("[TaterSetlistMgr][Error]: Macro range must include at least 2 macros.")
      return mainMenu()
    end

    SetVar(GlobalVars(), "TaterSetlistMacroStart", tostring(start))
    SetVar(GlobalVars(), "TaterSetlistMacroEnd", tostring(finish))
    Printf("[TaterSetlistMgr]: Saved macro range: %d–%d", start, finish)

    mainMenu()
  end

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

  function mainMenu()
    local TaterLastCue = tonumber(GetVar(GlobalVars(), "TaterSetlistCue") or "500")
    local slotList, nameList = getMacroSetlist()

    local msg = ""
    if #nameList > 0 then
      msg = "Current Setlist (from saved range):\n"
      for i = 1, #slotList do
        msg = msg .. string.format("  %s: %s\n", slotList[i], nameList[i])
      end
    else
      msg = "No macro range set, or range is empty."
    end

    msg = msg .. "\n\nWhat would you like to do?"

    local box = MessageBox({
      title = "Setlist Manager",
      message = msg,
      commands = {
        { value = 1, name = "Set Macro Range" },
        { value = 2, name = "Update Setlist" },
        { value = 3, name = "SetLastCue (" .. TaterLastCue .. ")" },
        { value = 4, name = "Cancel" }
      }
    })

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

  mainMenu()
end
