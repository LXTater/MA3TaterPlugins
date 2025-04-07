-- grandMA3 Plugin: TaterFX Generator (Cleaned Version)
-- Author: ChatGPT + Tater
-- Version: Refactor 1.0

local function main()

  -- === Utility Functions ===
  local function promptAttribute()
    return MessageBox({
      title = "TaterFX - Step 1",
      message = "Choose the attribute.",
      commands = {
        { name = "Back", value = -1 },
        { name = "Cancel", value = 0 },
        { name = "Pick From Pool", value = 99 },
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
  end

  local function promptForm(attribute)
    local selectors = {
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

    if attribute == 2 then
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

    return MessageBox({
      title = "TaterFX - Step 2",
      message = "Select the form" .. (attribute == 2 and " and shape" or "") .. ".",
      commands = {
        { name = "Back", value = -1 },
        { name = "Cancel", value = 0 },
        { name = "Next", value = 1 }
      },
      selectors = selectors
    })
  end

  local function promptValues()
    local step3 = MessageBox({
      title = "TaterFX - Step 3",
      message = "Set high/low values or use presets.",
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

    if not step3 then return nil end
    if step3.result == 0 then return nil end

    if step3.result == 2 then
      local low = MessageBox({
        title = "Low Preset",
        message = "Enter preset ID for Low Value",
        inputs = {
          { name = "LowPreset", value = "1", whiteFilter = "1234567890" }
        },
        commands = {
          { name = "Cancel", value = 0 },
          { name = "OK", value = 1 }
        }
      })
      local high = MessageBox({
        title = "High Preset",
        message = "Enter preset ID for High Value",
        inputs = {
          { name = "HighPreset", value = "2", whiteFilter = "1234567890" }
        },
        commands = {
          { name = "Cancel", value = 0 },
          { name = "OK", value = 1 }
        }
      })
      return tonumber(low.inputs.LowPreset), tonumber(high.inputs.HighPreset)
    else
      return tonumber(step3.inputs.LowValue), tonumber(step3.inputs.HighValue)
    end
  end

  local function promptPhaserPool()
    local res = MessageBox({
      title = "Phaser Pool",
      message = "Enter Phaser Pool number.",
      inputs = {
        { name = "PhaserPool", value = "1", whiteFilter = "1234567890" }
      },
      commands = {
        { name = "Cancel", value = 0 },
        { name = "Continue", value = 1 }
      }
    })

    if not res or res.result ~= 1 then return nil end
    return tonumber(res.inputs.PhaserPool)
  end

  local function promptSpreadPhase()
    local res = MessageBox({
      title = "TaterFX - Step 4",
      message = "Enter spread/phase options.",
      commands = {
        { name = "Back", value = -1 },
        { name = "Cancel", value = 0 },
        { name = "OK", value = 1 }
      },
      inputs = {
        { name = "Groups", value = "0" },
        { name = "Blocks", value = "0" },
        { name = "Wings", value = "0" },
        { name = "PhaseX", value = "0" },
        { name = "PhaseY", value = "360" },
        { name = "Width", value = "100" }
      },
      states = {
        { name = "Shuffle" },
        { name = "Loop" }
      }
    })

    if not res then return nil end
    return res
  end

  local function applyPhaser(attrList, high, low, shape)
    Cmd("Clear Programmer")
    for _, attr in ipairs(attrList) do
      Cmd(string.format('Step 1 Attribute "%s" At %d', attr, high))
      Cmd(string.format('Step 2 Attribute "%s" At %d', attr, low))
    end
    if shape == "circle" then
      Cmd('Set Step 1 Attribute "Pan" Phase 0')
      Cmd('Set Step 1 Attribute "Tilt" Phase 90')
    elseif shape == "diamond" then
      Cmd('Set Step 1 Attribute "Pan" Phase 45')
      Cmd('Set Step 1 Attribute "Tilt" Phase 135')
    elseif shape == "wave" then
      Cmd('Set Step 1 Attribute "Pan" Phase 0')
      Cmd('Set Step 1 Attribute "Tilt" Phase 20')
    elseif shape == "cross" then
      Cmd('Set Step 1 Attribute "Pan" Phase 0')
      Cmd('Set Step 1 Attribute "Tilt" Phase 180')
    end
  end

  -- === Workflow Starts ===
  local attrDialog = promptAttribute()
  if not attrDialog or attrDialog.result ~= 1 then return end
  local attribute = tonumber(attrDialog.selectors.Attribute)

  local formDialog = promptForm(attribute)
  if not formDialog or formDialog.result ~= 1 then return end
  local form = tonumber(formDialog.selectors.Form)
  local posShape = tonumber(formDialog.selectors.PositionShape)

  local low, high = promptValues()
  if not low or not high then return end

  local poolNum = promptPhaserPool()
  if not poolNum then return end

  local attrList = {}
  if attribute == 1 then attrList = { "Dimmer" } end
  if attribute == 2 then attrList = { "Pan", "Tilt" } end
  if attribute == 3 then attrList = { "ColorRGB_R" } end

  local shapes = { [3] = "circle", [4] = "diamond", [5] = "wave", [6] = "cross" }
  local shape = attribute == 2 and shapes[posShape] or nil

  applyPhaser(attrList, high, low, shape)

  local spreadInfo = promptSpreadPhase()
  if not spreadInfo or spreadInfo.result ~= 1 then return end

  Cmd("Store Preset Phasers " .. tostring(poolNum))
  Printf("TaterFX: Phaser stored at Preset Phasers %d", poolNum)
end

return main
