-- grandMA3 Plugin: Tater Setlist Manager
-- Author: Tater
-- Plugin Version: 2.0
-- Please send any bugs to Tater@LXTater.com
-- Updated 5/22/2025
-- this will most likely break your showfile... PLease don't use this unnless you know what ur doing lol!!!!
-- v2 is on the way that is going to automatically generate sequences and recipes for you depending on your settings
-- this will allow you to turn an entire fader page editable with the my version of the LOS System.
-- Comments are terrible rn sorry
-- This is an early version of version 2.0

return function()

    local TaterDebug = true
  
    local function TaterLOSBuilderPhase2()
      -- User input
      local startGroup = tonumber(TextInput("Start Group Number", "1"))
      local endGroup = tonumber(TextInput("End Group Number", "8"))
      if not startGroup or not endGroup or endGroup < startGroup then
        ErrPrintf("[TaterLOS] Invalid group range.")
        return
      end
  
      local totalLOS = tonumber(TextInput("Number of LOS types?", "2"))
      if not totalLOS or totalLOS < 1 then
        ErrPrintf("[TaterLOS] Invalid LOS count.")
        return
      end
  
      local losStartMacros = {}
      for los = 1, totalLOS do
        local slot = tonumber(TextInput(string.format("Macro start slot for LOS%d", los), tostring(6500 + los * 10)))
        if not slot then
          ErrPrintf("[TaterLOS] Invalid macro slot for LOS%d", los)
          return
        end
        table.insert(losStartMacros, slot)
      end
  
      local parts = tonumber(TextInput("How many parts per LOS?", "8"))
      if not parts or parts < 1 then
        ErrPrintf("[TaterLOS] Invalid part count.")
        return
      end
  
      local presetInput = TextInput("Enter All Preset (e.g. 4.8)", "")
      local pool, index = string.match(presetInput, "^(%d+)%.(%d+)$")
      if not pool or not index then
        ErrPrintf("[TaterLOS] Invalid preset format. Use 'Pool.Index' e.g. 4.8")
        return
      end
      local preset = string.format("%s.%s", pool, index)
  
      local seqBase = TextInput("Base Sequence Number (Leave blank for auto)", "")
      local useAutoSeq = (seqBase == "")
      local nextSeq = 1
  
      -- Helper to get next free sequence
      local function getNextSequenceNumber()
        local used = {}
        for _, s in ipairs(DataPool().Sequences:Children()) do
          used[tonumber(s.no)] = true
        end
        while used[nextSeq] do
          nextSeq = nextSeq + 1
        end
        return nextSeq
      end
  
      for los = 1, totalLOS do
        local baseMacro = losStartMacros[los]
  
        for group = startGroup, endGroup do
          local macroSlot = baseMacro + (group - startGroup)
          local macroName = string.format("LOS%d Group %d/%d", los, group, parts)
  
          -- Build Sequence + Recipes per part
          for i = 1, parts do
            local seqName = string.format("LOS%d %d/%d", los, i, parts)
            local seqNumber = useAutoSeq and getNextSequenceNumber() or tonumber(seqBase)
  
            if not useAutoSeq and DataPool().Sequences:Find(seqName) then
              ErrPrintf("[TaterLOS] Sequence '%s' already exists. Aborting.", seqName)
              return
            end
  
            Cmd(string.format('Store Sequence "%s" /nc', seqName))
            Cmd(string.format('Label Sequence "%s" "%s"', seqName, seqName))
  
            local groupName = string.format("Group %d LOS %d", group, i)
  
            -- Insert Recipe line
            Cmd(string.format('Insert Sequence "%s" Cue 1 Part 0 Recipe 1', seqName))
            Cmd(string.format('Set Sequence "%s" Cue 1 Part 0 Recipe 1 Property "Group" "%s"', seqName, groupName))
            Cmd(string.format('Set Sequence "%s" Cue 1 Part 0 Recipe 1 Property "Feature" "All"', seqName))
            Cmd(string.format('Set Sequence "%s" Cue 1 Part 0 Recipe 1 Property "Preset" "%s"', seqName, preset))
            Cmd(string.format('Set Sequence "%s" Cue 1 Part 0 Recipe 1 Property "Name" "LOS%d Group %d"', seqName, los, group))
  
            if not useAutoSeq then seqBase = seqBase + 1 end
          end
  
          -- Macro Generation (same as before)
          Cmd(string.format('Delete Macro %d /nc', macroSlot))
          Cmd(string.format('Store Macro %d /nc', macroSlot))
          Cmd(string.format('Label Macro %d "LOS%d Group %d/%d"', macroSlot, los, group, parts))
  
          local line = 1
          Cmd(string.format(
            'Insert Macro %d.%d Property "Command" 'Assign Appearance "LOS Groups Active" At Macro "LOS%d Group %d/%d"' Property "Name" "Appearance Active"',
            macroSlot, line, los, group, parts
          ))
          line = line + 1
  
          for i = 1, parts do
            local groupName = string.format("Group %d LOS %d", group, i)
            local seqName = string.format("LOS%d %d/%d", los, i, parts)
            local cmd = string.format(
              'Assign #[Group "%s"] At Sequence "%s" Cue 1 Part 0."LOS%d Group %d"',
              groupName, seqName, los, group
            )
            local label = string.format("LOS%d %d/%d", los, i, parts)
            Cmd(string.format(
              'Insert Macro %d.%d Property "Command" '%s' Property "Name" "%s"',
              macroSlot, line, cmd, label
            ))
            line = line + 1
          end
  
          local lastLOSLine = line - 1
  
          Cmd(string.format(
            'Insert Macro %d.%d Property "Command" 'Assign Appearance "LOS Groups" At Macro "LOS%d Group %d/%d"' Property "Name" "Appearance Inactive"',
            macroSlot, line, los, group, parts
          ))
          line = line + 1
  
          Cmd(string.format(
            'Insert Macro %d.%d Property "Command" 'Set Sequence "LOS%d*" Cue 1 Thru 10 Part 0."LOS%d Group %d" Property "Selection" ""' Property "Name" "Disable"',
            macroSlot, line, los, los, group
          ))
  
          Cmd(string.format('Set Macro %d.%d Property "wait" "Go"', macroSlot, lastLOSLine))
  
          if TaterDebug then
            Printf("[TaterLOS] Built Macro %d: '%s'", macroSlot, macroName)
          end
        end
      end
  
      Printf("[TaterLOS] Complete: %d LOS x %d Groups = %d Macros.", totalLOS, endGroup - startGroup + 1, totalLOS * (endGroup - startGroup + 1))
    end
  
    TaterLOSBuilderPhase2()
  end
  