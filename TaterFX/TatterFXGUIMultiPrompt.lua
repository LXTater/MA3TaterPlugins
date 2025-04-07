-- GrandMA3 Plugin: TaterFX - Multi-step MessageBox UI

local function main()
  -- Step 1: Attribute + Form using radial + custom icons
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

  -- Step 2: High/Low Values OR Preset Select
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
  elseif step2.result == 2 then
    -- Simulate preset selection with message boxes as true pool interaction isn't exposed
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
    Printf("TaterFX: Preset-based values: Low=%s High=%s", tostring(taterLowValue), tostring(taterHighValue))
    -- end of preset selection block
  end

  -- Step 3: Spread, Phase, Toggles
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

  -- Collect all values
  -- Skip reassigning if presets were used
  local i1 = step2.inputs or {}
  local i2 = step3.inputs
  local s = step1.selectors
  local st = step3.states

  if not taterLowValue then taterLowValue = tonumber(i1.LowValue) or 0 end
  if not taterHighValue then taterHighValue = tonumber(i1.HighValue) or 100 end
  taterGroups = tonumber(i2.Groups) or 0
  taterBlocks = tonumber(i2.Blocks) or 0
  taterWings = tonumber(i2.Wings) or 0
  taterPhaseX = tonumber(i2.PhaseX) or 0
  taterPhaseY = tonumber(i2.PhaseY) or 360
  taterWidth = tonumber(i2.Width) or 100

  taterAttribute = tonumber(s.Attribute) or 1
  taterForm = tonumber(s.Form) or 1

  taterShuffle = st.Shuffle or false
  taterLoop = st.Loop or false

  Printf("TaterFX MessageBox Input:")
  Printf("Low/High: %d / %d", taterLowValue, taterHighValue)
  Printf("Groups: %d, Blocks: %d, Wings: %d", taterGroups, taterBlocks, taterWings)
  Printf("PhaseX/Y: %d / %d", taterPhaseX, taterPhaseY)
  Printf("Width: %d", taterWidth)
  Printf("Attribute: %d, Form: %d", taterAttribute, taterForm)
  Printf("Shuffle: %s, Loop: %s", tostring(taterShuffle), tostring(taterLoop))
end

return main
