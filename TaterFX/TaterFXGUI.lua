-- GrandMA3 Plugin: TaterFX - MA2 Effect Style UI
-- This opens a MessageBox-based UI to configure Phaser settings using classic MA2-like inputs.

local function main()
  -- Default values for Phaser settings
  taterGroups = 0
  taterBlocks = 0
  taterWings = 0
  taterPhaseX = 0
  taterPhaseY = 360
  taterHighValue = 100
  taterLowValue = 0
  taterSpeedMaster = 0
  taterRate = 0
  taterForm = 0
  taterWidth = 0

  local returnTable = MessageBox({
    title = 'TaterFX - Old Heads Unite!',
    titleTextColor = 1.7,
    backColor = 1.11,
    icon = 'object_smart',

    message = 'Welcome to TaterFX, the MA2 Effects Engine to Phaser Plugin.',
    messageTextColor = 1.8,
    message_align_h = Enums.AlignmentH.Left,

    autoCloseOnInput = false,

    commands = {
      { value = 1, name = 'Cancel! :-(' },
      { value = 2, name = 'Store Effect! :-)' }
    },

    selectors = {
      {
        name = 'Attribute',
        selectedValue = 'None',
        type = 0,
        values = { ['Dimmer'] = 1, ['Position'] = 2, ['Color'] = 3 }
      },
      {
        name = 'Form',
        selectedValue = 'None',
        type = 0,
        values = {
          ['Chase'] = 1,
          ['sin'] = 2,
          ['Cos'] = 3,
          ['RampPlus'] = 4,
          ['RampMinus'] = 5,
          ['FlyOut'] = 6
        },
        icons = {
          [1] = 'form_chase',
          [2] = 'form_sin',
          [3] = 'form_cos',
          [4] = 'form_rampplus',
          [5] = 'form_rampminus',
          [6] = 'form_flyout'
        }
      }
    },

    inputs = {
      { name = 'LowValue', value = '0', whiteFilter = '1234567890', vkPlugin = 'PresetInput' },
      { name = 'HighValue', value = '0', whiteFilter = '1234567890', vkPlugin = 'PresetInput' },
      { name = 'Groups', value = '0', whiteFilter = '1234567890', vkPlugin = 'NumericInput' },
      { name = 'Blocks', value = '0', whiteFilter = '1234567890', vkPlugin = 'NumericInput' },
      { name = 'Wings', value = '0', whiteFilter = '1234567890', vkPlugin = 'NumericInput' },
      { name = 'PhaseX', value = '0', whiteFilter = '1234567890', vkPlugin = 'NumericInput' },
      { name = 'PhaseY', value = '360', whiteFilter = '1234567890', vkPlugin = 'NumericInput' },
      { name = 'Width', value = '100', whiteFilter = '1234567890', vkPlugin = 'NumericInput' }
    }
  })

  -- You can now use returnTable.result, returnTable.inputs, returnTable.selectors, etc.
  -- Example debug print:
  if returnTable then
    Printf("Button Pressed: " .. tostring(returnTable.result))
    for k, v in pairs(returnTable.inputs or {}) do
      Printf("Input [" .. k .. "]: " .. v)
    end
    for k, v in pairs(returnTable.selectors or {}) do
      Printf("Selector [" .. k .. "]: " .. v)
    end
  end
end

return main
