-- grandMA3 Plugin: Tater Setlist Manager (Auto-Cue Version)
-- Author: Tater
-- Plugin Version: 1.5.3
-- Manual input disabled, warning dialog added, Go+ Macro match enforced

return function()

  local DEBUG_MODE = true

  local function debugLog(fmt, ...)
    if DEBUG_MODE then
      Printf("[TaterSetlistMgr][Debug]: " .. fmt, ...)
    end
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
    if #nameList < 2 then
      ErrPrintf("[TaterSetlistMgr][Error]: Setlist invalid or empty. Set macro range first.")
      return
    end

    for i = 1, #nameList - 1 do
      local current = nameList[i]
      local nextOne = nameList[i + 1]
      local cues = ObjectList('Sequence "' .. current .. '" Cue *')
      local matched = false

      for _, cue in ipairs(cues or {}) do
        local cmd = cue[1] and cue[1].command or ""
        if cmd ~= "" then
          for _, macroName in ipairs(nameList) do
            if cmd:lower():match("go%+%s*macro%s+" .. macroName:lower()) then
              Cmd('Set Sequence "' .. current .. '" Cue ' .. tostring(cue.no):gsub("000$", "") .. ' Property "Command" "Go+ Macro ' .. nextOne .. '"')
              Printf("[TaterSetlistMgr]: Updated %s cue %s → Go+ Macro %s", current, tostring(cue.no):gsub("000$", ""), nextOne)
              matched = true
              break
            end
          end
        end
      end

      if not matched then
        debugLog("Sequence '%s' missing valid 'Go+ Macro [NextSongName]' command", current)

        --[[ Manual assignment logic disabled
        local result = MessageBox({...})
        ]]

        -- ⚠️ Show warning only
        MessageBox({
          title = "⚠️ Missing Cue Command",
          message = string.format("Sequence: %s (%d)\nNo valid cue with a 'Go+ Macro [NextSong]' command found.\nPlease add a cue and run the plugin again.\nSequences not listed above succesfully updated.", current, i),
          commands = {
            { value = 1, name = "OK" }
          }
        })
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

  function mainMenu()
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
    local box = MessageBox({
      title = "Tater Setlist Manager",
      message = msg,
      commands = {
        { value = 1, name = "Set Macro Range" },
        { value = 2, name = "Update Setlist" },
        { value = 3, name = "Cancel" }
      }
    })
    if box.result == 1 then
      setMacroRange()
    elseif box.result == 2 then
      local _, updatedNameList = getMacroSetlist()
      if updatedNameList and #updatedNameList > 1 then
        updateSequences(updatedNameList)
      else
        ErrPrintf("[TaterSetlistMgr][Error]: No valid macro names found.")
      end
    else
      Printf("[TaterSetlistMgr]: Cancelled.")
    end
  end

  mainMenu()
end
