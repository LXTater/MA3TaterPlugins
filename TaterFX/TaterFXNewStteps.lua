-- GrandMA3 Plugin: TaterFX - Multi-step MessageBox UI

local function main()
  ::start_over::
  -- STEP 1: Select only the Attribute
  local step1 = MessageBox({
    title = "TaterFX - Step 1",
    message = "Choose the attribute.",
commands = {
  { name = "Back", value = -1 },
  { name = "Cancel", value = 0 ,
  { name = "Pick From Pool", value = 99 }
},
      { name = "Next", value = 1 }
    },
    selectors = {
      {
        name = "Attribute",
        selectedValue = 1,
        type = 1,
        values = { Dimmer = 1, Position = 2, Color = 3 }
      }
    }
  })

  if not step1 or step1.result == 0 then
    Printf("TaterFX: Cancelled at step 1.")
    return
  end

  local taterAttribute = tonumber(step1.selectors.Attribute) or 1
  local taterForm = 1
  local taterFormString = ""
  local taterPositionShape = nil

  -- STEP 2: Show attribute-specific options
  ::step2::
  local formOptions = {
    ["Chase"] = 1,
    ["sin"] = 2,
    ["Cos"] = 3,
    ["Ramp+"] = 4,
    ["Ramp-"] = 5,
    ["FlyOut"] = 6
  }

  local formMap = {
    [1] = "taterChase",
    [2] = "taterSin",
    [3] = "taterCos",
    [4] = "taterRamp+",
    [5] = "taterRamp-",
    [6] = "taterFlyout"
  }

  local formPhaserShapes = {
    [1] = {}, -- Chase: no extra attributes
    [2] = { Accel = -100, Decel = -100, AccelSplineType = "Proportional", DecelSplineType = "Proportional", Trans = 100, Width = 45 },
    [3] = { Accel = -100, Decel = -100, AccelSplineType = "Proportional", DecelSplineType = "Proportional", Trans = 100, Width = 45 },
    [4] = { Accel = 100, Decel = 0, AccelSplineType = "Linear", DecelSplineType = "Hold", Trans = 100, Width = 50 },
    [5] = { Accel = 0, Decel = 100, AccelSplineType = "Hold", DecelSplineType = "Linear", Trans = 100, Width = 50 },
    [6] = { Accel = -100, Decel = -100, AccelSplineType = "Proportional", DecelSplineType = "Proportional", Trans = 100, Width = 100 }
  }

  local selectors = {
    {
      name = "Form",
      selectedValue = 1,
      type = 1,
      values = formOptions
    }
  }

  if taterAttribute == 2 then
    table.insert(selectors, {
      name = "PositionShape",
      selectedValue = 1,
      type = 1,
      values = {
        ["Pan"] = 1,
        ["Tilt"] = 2,
        ["Circle"] = 3,
        ["Diamond"] = 4,
        ["Wave"] = 5,
        ["Cross"] = 6
      }
    })
  end

  -- Show previously selected Phaser (if any)
  local prevPhaser = GlobalVars("TaterPickedPhaser") or ""
  if prevPhaser ~= "" then
    Printf("TaterFX: Previously selected Phaser: " .. tostring(prevPhaser))
  end

  local step2 = MessageBox({
    title = "TaterFX - Step 2",
    message = "Select the form" .. (taterAttribute == 2 and " and shape" or "") .. ".",
    commands = {
      { name = "Back", value = -1 },
      { name = "Cancel", value = 0 },
      { name = "Next", value = 1 }
    },
    selectors = selectors
  })

  if not step2 then return end
  if step2.result == -1 then goto start_over end
  if step2.result == 99 then
    Printf("TaterFX: Please tap a Phaser pool item now...")
    CmdIndirect('SetUserVar "TaterPickedPhaser" "$(CurrentSelection)"')
    return main()
  end
  if step2.result == 0 then return end

  taterForm = tonumber(step2.selectors.Form) or 1
  taterFormString = formMap[taterForm] or "taterChase"
  local taterFormPhaserAttributes = formPhaserShapes[taterForm] or {}

  if taterAttribute == 2 then
    taterPositionShape = tonumber(step2.selectors.PositionShape)
  end

  -- Prompt user to select Phaser pool number
  local phaserStep = MessageBox({
    title = "Phaser Pool Selection",
    message = "Enter Phaser Pool number to store the generated Phaser.",
    inputs = {
      { name = "PhaserPool", value = "1", whiteFilter = "1234567890" }
    },
    commands = {
      { name = "Cancel", value = 0 },
      { name = "Continue", value = 1 }
    }
  })

  if not phaserStep or phaserStep.result ~= 1 then
    Printf("TaterFX: Cancelled at Phaser Pool selection.")
    return
  end

    local poolNum = tonumber(phaserStep.inputs.PhaserPool)
    local poolPath = "Preset Phasers." .. tostring(poolNum)
    local poolObj = ObjectList(poolPath)[1] -- ObjectList returns a table of handles

if poolObj and poolObj.name ~= "" then
  local confirm = MessageBox({
    title = "Confirm Overwrite",
    message = string.format("Phaser Pool %d already has an effect named '%s'. Overwrite?", poolNum, poolObj.name),
    commands = {
      { name = "Cancel", value = 0 },
      { name = "Overwrite", value = 1 }
    }
  })

  if not confirm or confirm.result ~= 1 then
    Printf("TaterFX: Overwrite cancelled.")
    return
  end
end

  -- Create fresh phaser in programmer
  Cmd("Clear Programmer")
  Cmd("Store Phasers " .. poolNum)

  local high = taterHighValue or 100
  local low = taterLowValue or 0

  local function applyPhaserSteps(attrList)
    for _, attr in ipairs(attrList) do
      Cmd(string.format('Step 1 Attribute "%s" At %d', attr, high))
      Cmd(string.format('Step 2 Attribute "%s" At %d', attr, low))
      for k, v in pairs(taterFormPhaserAttributes) do
        Cmd(string.format('Set Step 1 Attribute "%s" %s %s', attr, k, tostring(v)))
        Cmd(string.format('Set Step 2 Attribute "%s" %s %s', attr, k, tostring(v)))
      end
    end
  end

  local attrList = {}
  if taterAttribute == 1 then attrList = {"Dimmer"} end
  if taterAttribute == 2 then attrList = {"Pan", "Tilt"} end
  if taterAttribute == 3 then attrList = {"ColorRGB_R"} end

  applyPhaserSteps(attrList)

  if taterAttribute == 2 then
    if taterPositionShape == 3 then -- Circle
      Cmd('Set Step 1 Attribute "Pan" Phase 0')
      Cmd('Set Step 1 Attribute "Tilt" Phase 90')
    elseif taterPositionShape == 4 then -- Diamond
      Cmd('Set Step 1 Attribute "Pan" Phase 45')
      Cmd('Set Step 1 Attribute "Tilt" Phase 135')
    elseif taterPositionShape == 5 then -- Wave
      Cmd('Set Step 1 Attribute "Pan" Phase 0')
      Cmd('Set Step 1 Attribute "Tilt" Phase 20')
    elseif taterPositionShape == 6 then -- Cross
      Cmd('Set Step 1 Attribute "Pan" Phase 0')
      Cmd('Set Step 1 Attribute "Tilt" Phase 180')
    end
  end

  -- === APPLY PHASER ATTRIBUTES TO PROGRAMMER STEP ===
  local function applyPhaserAttributes(attributeNames, attributesTable)
    for _, attr in ipairs(attributeNames) do
      Cmd(string.format('Step 1 Attribute "%s" At 100', attr))
      for k, v in pairs(attributesTable) do
        Cmd(string.format('Set Step 1 Attribute "%s" %s %s', attr, k, tostring(v)))
      end
    end
  end

  if taterAttribute == 1 then
    applyPhaserAttributes({"Dimmer"}, taterFormPhaserAttributes)
  elseif taterAttribute == 2 then
    applyPhaserAttributes({"Pan", "Tilt"}, taterFormPhaserAttributes)

    -- Extra position shaping logic
    if taterPositionShape == 3 then -- Circle
      Cmd('Set Step 1 Attribute "Pan" Phase 0')
      Cmd('Set Step 1 Attribute "Tilt" Phase 90')
    elseif taterPositionShape == 4 then -- Diamond
      Cmd('Set Step 1 Attribute "Pan" Phase 45')
      Cmd('Set Step 1 Attribute "Tilt" Phase 135')
    elseif taterPositionShape == 5 then -- Wave
      Cmd('Set Step 1 Attribute "Pan" Phase 0')
      Cmd('Set Step 1 Attribute "Tilt" Phase 20')
    elseif taterPositionShape == 6 then -- Cross
      Cmd('Set Step 1 Attribute "Pan" Phase 0')
      Cmd('Set Step 1 Attribute "Tilt" Phase 180')
    end
  elseif taterAttribute == 3 then
    applyPhaserAttributes({"ColorRGB_R"}, taterFormPhaserAttributes) -- Simplified example
  end

  ::step3::
  local step3 = MessageBox({
    title = "TaterFX - Step 3",
    message = "Set the high and low values, or choose from presets instead.",
    commands = {
      { name = "Back", value = -1 },
      { name = "Cancel", value = 0 },
      { name = "Next", value = 1 },
      { name = "Select Presets Instead", value = 2 }
    },
    inputs = {
      { name = "LowValue", value = "0", whiteFilter = "1234567890" },
      { name = "HighValue", value = "100", whiteFilter = "1234567890" }
    }
  })

  if not step3 then return end
  if step3.result == -1 then goto step2 end
  if step3.result == 0 then return end

  local taterLowValue, taterHighValue
  if step3.result == 2 then
    local low = MessageBox({
      title = "Select Low Preset",
      message = "Enter preset ID for Low Value",
      inputs = {
        { name = "LowPreset", value = "1", whiteFilter = "1234567890" }
      },
      commands = {
        { name = "Cancel", value = 0 },
        { name = "OK", value = 1 }
      }
    })

    if not low or low.result ~= 1 then return end

    local high = MessageBox({
      title = "Select High Preset",
      message = "Enter preset ID for High Value",
      inputs = {
        { name = "HighPreset", value = "2", whiteFilter = "1234567890" }
      },
      commands = {
        { name = "Cancel", value = 0 },
        { name = "OK", value = 1 }
      }
    })

    if not high or high.result ~= 1 then return end

    taterLowValue = tonumber(low.inputs.LowPreset) or 0
    taterHighValue = tonumber(high.inputs.HighPreset) or 100
  else
    taterLowValue = tonumber(step3.inputs.LowValue) or 0
    taterHighValue = tonumber(step3.inputs.HighValue) or 100
  end

  ::step4::
  local step4 = MessageBox({
    title = "TaterFX - Step 4",
    message = "Enter spread, phase and options.",
    commands = {
      { name = "Back", value = -1 },
      { name = "Cancel", value = 0 },
      { name = "OK", value = 1 }
    },
    inputs = {
      { name = "Groups", value = "0", whiteFilter = "1234567890" },
      { name = "Blocks", value = "0", whiteFilter = "1234567890" },
      { name = "Wings", value = "0", whiteFilter = "1234567890" },
      { name = "PhaseX", value = "0", whiteFilter = "1234567890" },
      { name = "PhaseY", value = "360", whiteFilter = "1234567890" },
      { name = "Width", value = "100", whiteFilter = "1234567890" }
    },
    states = {
      { name = "Shuffle" },
      { name = "Loop" }
    }
  })

  if not step4 then return end
  if step4.result == -1 then goto step3 end
  if step4.result == 0 then return end

  local i4 = step4.inputs or {}
  local st4 = step4.states or {}

  local taterGroups  = tonumber(i4.Groups) or 0
  local taterBlocks  = tonumber(i4.Blocks) or 0
  local taterWings   = tonumber(i4.Wings) or 0
  local taterPhaseX  = tonumber(i4.PhaseX) or 0
  local taterPhaseY  = tonumber(i4.PhaseY) or 360
  local taterWidth   = tonumber(i4.Width) or 100
  local taterShuffle = st4.Shuffle or false
  local taterLoop    = st4.Loop or false
end

return main
