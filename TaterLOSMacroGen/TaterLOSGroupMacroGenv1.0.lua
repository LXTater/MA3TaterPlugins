-- grandMA3 Plugin: Tater Setlist Manager
-- Author: Tater
-- Plugin Version: 1.0
-- Please send any bugs to Tater@LXTater.com
-- Updated 4/6/2025
-- Verified working for MA3 V 2.2.5.2
-- this will most likely break your showfile... PLease don't use this unnless you know what ur doing lol!!!!
-- v2 is on the way that is going to automatically generate sequences and recipes for you depending on your settings
-- this will allow you to turn an entire fader page editable with the my version of the LOS System.
-- Comments are terrible rn sorry

return function()

    local TaterDebug = true
  
    local function TaterBatchLOSAssign()
      local startGroup = tonumber(TextInput("Start Group Number", "1"))
      local endGroup = tonumber(TextInput("End Group Number", "8"))
  
      if not startGroup or not endGroup or endGroup < startGroup then
        ErrPrintf("[TaterLOSGen] Invalid group range.")
        return
      end
  
      local totalLOS = tonumber(TextInput("How many LOS per group?", "2"))
      if not totalLOS or totalLOS < 1 then
        ErrPrintf("[TaterLOSGen] Invalid LOS count.")
        return
      end
  
      local losStartMacros = {}
      for los = 1, totalLOS do
        local slot = tonumber(TextInput(string.format("Macro start slot for LOS%d", los), tostring(6500 + los * 10)))
        if not slot then
          ErrPrintf("[TaterLOSGen] Invalid macro slot for LOS%d", los)
          return
        end
        table.insert(losStartMacros, slot)
      end
  
      local parts = tonumber(TextInput("How many parts per LOS?", "8"))
      if not parts or parts < 1 then
        ErrPrintf("[TaterLOSGen] Invalid part count.")
        return
      end
  
      -- Main loop: per LOS
      for los = 1, totalLOS do
        local baseMacro = losStartMacros[los]
  
        for group = startGroup, endGroup do
          local macroSlot = baseMacro + (group - startGroup)
          local macroName = string.format("LOS%d Group %d/%d", los, group,parts)
  
          -- Clear and setup macro
          Cmd(string.format('Delete Macro %d /nc', macroSlot))
          Cmd(string.format('Store Macro %d /nc', macroSlot))
          Cmd(string.format('Label Macro %d "%s"', macroSlot, macroName))
  
          local line = 1
  
          -- Line 1: Appearance Active
          local line1Cmd = string.format('Assign Appearance "LOS Groups Active" At Macro "LOS%d Group %d/%d"', los, group, parts )
          Cmd(string.format('Insert Macro %d.%d Property "Command" \'%s\' Property "Name" "Appearance Active"', macroSlot, line, line1Cmd))
          line = line + 1
          -- LOS Part Lines
          for i = 1, parts do
            local groupName = string.format("Group %d LOS %d", group, i)
            local sequenceName = string.format("LOS%d %d/%d", los, i, parts)
            local cmd = string.format(
              'Assign #[Group "%s"] At Sequence "%s" Cue 1 Part 0."LOS%d Group %d"',
              groupName, sequenceName, los, group
            )
            local name = string.format("LOS%d %d/%d", los, i, parts)
  
            Cmd(string.format(
              'Insert Macro %d.%d Property "Command" \'%s\' Property "Name" "%s"',
              macroSlot, line, cmd, name
            ))
            line = line + 1
          end
  
          local lastLOSLine = line - 1
  
          -- Appearance Inactive
          local inactiveCmd = string.format(
            'Assign Appearance "LOS Groups" At Macro "LOS%d Group %d/%d"', los, group, parts
)
          Cmd(string.format(
            'Insert Macro %d.%d Property "Command" \'%s\' Property "Name" "Appearance Inactive"',
            macroSlot, line, inactiveCmd
          ))
          line = line + 1
  
          -- Disable
          local disableCmd = string.format(
            'Set Sequence "LOS%d*" Cue 1 Thru 10 Part 0."LOS%d Group %d" Property "Selection" ""',
            los, los, group
          )
          Cmd(string.format(
            'Insert Macro %d.%d Property "Command" \'%s\' Property "Name" "Disable"',
            macroSlot, line, disableCmd
          ))
  
          -- Set Wait = Go on final LOS part line
          Cmd(string.format(
            'Set Macro %d.%d Property "wait" "Go"',
            macroSlot, lastLOSLine
          ))
  
          if TaterDebug then
            Printf("[TaterLOSGen][Debug] Built Macro %d: '%s'", macroSlot, macroName)
          end
        end
      end
  
      Printf("[TaterLOSGen] Complete. Generated %d LOS x %d Groups = %d Macros.", totalLOS, endGroup - startGroup + 1, totalLOS * (endGroup - startGroup + 1))
    end
  
    TaterBatchLOSAssign()
  end
  