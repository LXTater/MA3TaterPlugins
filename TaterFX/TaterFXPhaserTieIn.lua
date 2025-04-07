-- GrandMA3 Plugin: TaterFX - Multi-step MessageBox UI

local function main()
  -- STEP 1: Attribute + Form selection
  local step1 = MessageBox({
    title = "TaterFX - Step 1",
    message = "Choose the attribute and waveform form.",
    commands = {
      { name = "Cancel", value = 0 },
      { name = "Next", value = 1 }
    },
    selectors = {
      {
        name = "Attribute",
        selectedValue = 1,
        type = 1, -- radial
        values = { Dimmer = 1, Position = 2, Color = 3 }
      },
      {
        name = "Form",
        selectedValue = 1,
        type = 1,
        values = {
          ["Chase"] = 1,
          ["sin"] = 2,
          ["Cos"] = 3,
          ["Ramp+"] = 4,
          ["Ramp-"] = 5,
          ["FlyOut"] = 6
        }
      }
    }
  })

  if not step1 or step1.result ~= 1 then
    Printf("TaterFX: Cancelled at step 1.")
    return
  end

  local s = step1.selectors
  local taterAttribute = tonumber(s.Attribute) or 1
  local taterForm = tonumber(s.Form) or 1

  local formMap = {
    [1] = "taterChase",
    [2] = "taterSin",
    [3] = "taterCos",
    [4] = "taterRamp+",
    [5] = "taterRamp-",
    [6] = "taterFlyout"
  }
  local taterFormString = formMap[taterForm] or "taterChase"

  -- Call the selected form into the programmer
  Cmd('At Preset 21.' .. taterFormString)

  -- STEP 1.5: Optional - Choose position shape if Position selected
  local taterPositionShape = nil
  if taterAttribute == 2 then
    local shapeStep = MessageBox({
      title = "TaterFX - Position Shape",
      message = "Choose a position shape:",
      commands = {
        { name = "Cancel", value = 0 },
        { name = "Continue", value = 1 }
      },
      selectors = {
        {
          name = "PositionShape",
          selectedValue = 1,
          type = 1,
          values = {
            ["Pan"] = 1,
            ["Tilt"] = 2,
            ["Figure8"] = 3,
            ["Circle"] = 4
          }
        }
      }
    })

    if not shapeStep or shapeStep.result ~= 1 then
      Printf("TaterFX: Cancelled during Position Shape selection.")
      return
    end

    taterPositionShape = tonumber(shapeStep.selectors.PositionShape)
  end

  -- STEP 2: High/Low or Preset Selection
  local step2 = MessageBox({
    title = "TaterFX - Step 2",
    message = "Set the high and low values, or choose from presets instead.",
    commands = {
      { name = "Cancel", value = 0 },
      { name = "Next", value = 1 },
      { name = "Select Presets Instead", value = 2 }
    },
    inputs = {
      { name = "LowValue", value = "0", whiteFilter = "1234567890" },
      { name = "HighValue", value = "100", whiteFilter = "1234567890" }
    }
  })

  if not step2 or step2.result == 0 then
    Printf("TaterFX: Cancelled at step 2.")
    return
  end

  local taterLowValue, taterHighValue
  if step2.result == 2 then
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

    if not low or low.result ~= 1 then
      Printf("TaterFX: Low preset selection cancelled.")
      return
    end

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

    if not high or high.result ~= 1 then
      Printf("TaterFX: High preset selection cancelled.")
      return
    end

    taterLowValue = tonumber(low.inputs.LowPreset) or 0
    taterHighValue = tonumber(high.inputs.HighPreset) or 100
  else
    taterLowValue = tonumber(step2.inputs.LowValue) or 0
    taterHighValue = tonumber(step2.inputs.HighValue) or 100
  end

  -- STEP 3: Spread, Phase, Toggles
  local step3 = MessageBox({
    title = "TaterFX - Step 3",
    message = "Enter spread, phase and options.",
    commands = {
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

  if not step3 or step3.result ~= 1 then
    Printf("TaterFX: Cancelled at step 3.")
    return
  end

  -- Collect values from step3
  local i3 = step3.inputs or {}
  local st3 = step3.states or {}

  local taterGroups  = tonumber(i3.Groups) or 0
  local taterBlocks  = tonumber(i3.Blocks) or 0
  local taterWings   = tonumber(i3.Wings) or 0
  local taterPhaseX  = tonumber(i3.PhaseX) or 0
  local taterPhaseY  = tonumber(i3.PhaseY) or 360
  local taterWidth   = tonumber(i3.Width) or 100
  local taterShuffle = st3.Shuffle or false
  local taterLoop    = st3.Loop or false

  -- Summary
  Printf("\n--- TaterFX Selection Summary ---")
  Printf("Attribute: %d  |  Form: %d (%s)", taterAttribute, taterForm, taterFormString)
  if taterAttribute == 2 then
    Printf("Position Shape: %s", tostring(taterPositionShape))
  end
  Printf("Low/High: %d / %d", taterLowValue, taterHighValue)
  Printf("Spread - Groups: %d, Blocks: %d, Wings: %d", taterGroups, taterBlocks, taterWings)
  Printf("Phase - X: %d, Y: %d", taterPhaseX, taterPhaseY)
  Printf("Width: %d", taterWidth)
  Printf("Shuffle: %s  |  Loop: %s", tostring(taterShuffle), tostring(taterLoop))
end

return main
