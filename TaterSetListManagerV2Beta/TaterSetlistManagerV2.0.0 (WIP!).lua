-- grandMA3 Plugin: Tater Setlist Manager
-- Author: Tater
-- Plugin Version: 1.3.2
-- Updated: 4/6/2025
-- DOES NOT WORKKKK!
return function()

  local function numericInput(prompt, default)
    local input = TextInput(prompt, tostring(default or ""))
    if input then
      local digitsOnly = input:gsub("[^0-9]", "")
      return tonumber(digitsOnly)
    end
    return nil
  end

  -- ✅ Properly parse setlist data using safe manual pattern
  local function getAllSetlists()
    local raw = GetVar(GlobalVars(), "TaterSetlistData")
    local setlists = {}
    if not raw then return setlists end

    Printf("[TaterSetlistMgr][Debug]: Raw Saved Data = %s", raw)

    for entry in raw:gmatch("([^|]+|%d+|%d+|%d+)") do
      local name, start, finish, cue = entry:match("^(.-)|(%d+)|(%d+)|(%d+)$")
      if name then
        setlists[name] = {
          start = tonumber(start),
          finish = tonumber(finish),
          cue = tonumber(cue)
        }
      end
    end

    return setlists
  end

  local function saveAllSetlists(data)
    local parts = {}
    for name, values in pairs(data) do
      local encoded = string.format("%s|%d|%d|%d", name, values.start, values.finish, values.cue)
      table.insert(parts, encoded)
    end
    SetVar(GlobalVars(), "TaterSetlistData", table.concat(parts, "||"))
  end

  local function saveSetlist(name, startSlot, endSlot, cueNumber)
    local data = getAllSetlists()
    data[name] = { start = startSlot, finish = endSlot, cue = cueNumber }
    saveAllSetlists(data)
    SetVar(GlobalVars(), "TaterSetlist_Current", name)
    Printf("[TaterSetlistMgr]: Setlist '%s' saved!", name)
  end

  local function loadSetlist(name)
    local data = getAllSetlists()
    local set = data[name]
    if set then
      SetVar(GlobalVars(), "TaterSetlistMacroStart", tostring(set.start))
      SetVar(GlobalVars(), "TaterSetlistMacroEnd", tostring(set.finish))
      SetVar(GlobalVars(), "TaterSetlistCue", tostring(set.cue))
      SetVar(GlobalVars(), "TaterSetlist_Current", name)
      Printf("[TaterSetlistMgr]: Loaded setlist '%s'", name)
    else
      ErrPrintf("[TaterSetlistMgr][Error]: Setlist '%s' not found.", name)
    end
  end

  local function listSetlists()
    local data = getAllSetlists()
    local names = {}
    for name, _ in pairs(data) do
      table.insert(names, name)
    end
    table.sort(names)
    return names
  end

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
        message = string.format("Current range is: %d–%d\nThis will overwrite it.\nContinue?", oldStart, oldEnd),
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

    local start = numericInput("Enter starting macro slot:", 1) or 1
    local finish = numericInput("Enter ending macro slot:", 15) or 15
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
    local newCue = numericInput("Enter Cue Number to Use (Digits Only):", currentCue)
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
    local currentProfile = GetVar(GlobalVars(), "TaterSetlist_Current") or "None"

    local msg = "Active Setlist: " .. currentProfile .. "\n"
    if #nameList > 0 then
      msg = msg .. "Current Setlist (from saved range):\n"
      for i = 1, #slotList do
        msg = msg .. string.format("  %s: %s\n", slotList[i], nameList[i])
      end
    else
      msg = msg .. "No macro range set, or range is empty."
    end
    msg = msg .. "\n\nWhat would you like to do?"

    local box = MessageBox({
      title = "Setlist Manager",
      message = msg,
      commands = {
        { value = 1, name = "Set Macro Range" },
        { value = 2, name = "Update Setlist" },
        { value = 3, name = "SetLastCue (" .. TaterLastCue .. ")" },
        { value = 4, name = "Save Current Setlist" },
        { value = 5, name = "Load Setlist" },
        { value = 6, name = "Cancel" }
      }
    })

    if box.result == 1 then
      setMacroRange()
    elseif box.result == 2 then
      local _, updatedNameList = getMacroSetlist()
      updateSequences(updatedNameList)
    elseif box.result == 3 then
      setCueNumber()
    elseif box.result == 4 then
      local name = TextInput("Enter name for current setlist:")
      if name and name ~= "" then
        local start, finish = getStoredRange()
        local cue = tonumber(GetVar(GlobalVars(), "TaterSetlistCue") or "500")
        saveSetlist(name, start, finish, cue)
      else
        ErrPrintf("[TaterSetlistMgr][Error]: Invalid setlist name.")
      end
      mainMenu()
    elseif box.result == 5 then
      local allNames = listSetlists()
      if #allNames == 0 then
        ErrPrintf("[TaterSetlistMgr]: No saved setlists.")
        return mainMenu()
      end
      local options = {}
      for i, name in ipairs(allNames) do
        table.insert(options, { value = i, name = name })
      end
      local pick = MessageBox({
        title = "Load Setlist",
        message = "Choose a saved setlist to load:",
        commands = options
      })
      local picked = allNames[pick.result]
      if picked then
        loadSetlist(picked)
      end
      mainMenu()
    else
      Printf("[TaterSetlistMgr][Other]: Cancelled.")
    end
  end

  mainMenu()
end
