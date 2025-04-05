--[[ 
  grandMA3 Phaser Effects Engine Creator v1.0
  Inspired by Yury Belousov's Dimmer Phaser Engine Creator and our TaterFX UI flow.
--]]

local PHASER_EFFECTS_ENGINE_CREATOR = select(3, ...)

-- Shortcuts to common commands
local C = Cmd
local TI = TextInput
local E = Echo

--------------------------------------------------
-- Helper: Create a unique naming prefix for the phaser engine
--------------------------------------------------
function PHASER_EFFECTS_ENGINE_CREATOR.create_name_prefix()
  local prefix_index = 1
  local prefix = 'PPE'..tostring(prefix_index)..'_'
  -- (You might scan your macro pool or appearance names here to avoid duplicates)
  return prefix
end

--------------------------------------------------
-- Helper: Declare timing values for the phaser (phase positions, width, etc.)
--------------------------------------------------
function PHASER_EFFECTS_ENGINE_CREATOR.declare_timing_values()
  local timing = {}
  timing.phase_start = 0      -- starting phase value for step 1
  timing.phase_end = 360      -- ending phase value for step 2
  timing.width = 100          -- width value for both steps
  timing.delay = 0.5          -- (optional) delay between steps
  return timing
end

--------------------------------------------------
-- Helper: Declare filenames for the phaser forms
-- (These images represent the different waveform or movement effects)
--------------------------------------------------
function PHASER_EFFECTS_ENGINE_CREATOR.declare_filenames()
  local filenames = {
    chase      = 'chase.png',
    sin        = 'sin.png',
    Cos        = 'Cos.png',
    ["Ramp+"]  = 'RampPlus.png',
    ["Ramp-"]  = 'RampMinus.png',
    FlyOut     = 'Flyout.png'
  }
  return filenames
end

--------------------------------------------------
-- Helper: Create appearances for each phaser form.
-- This function uses the declared filenames to assign an image and name.
--------------------------------------------------
function PHASER_EFFECTS_ENGINE_CREATOR.create_appearances(naming_prefix, filenames)
  local appearances = ShowData().Appearances
  local index = #appearances + 1
  for form, filename in pairs(filenames) do
     appearances[index]:Set('mediafilename', 'SYMBOL/symbols/' .. filename)
     appearances[index]:Set('name', naming_prefix .. form)
     index = index + 1
  end
end

--------------------------------------------------
-- Helper: Import predefined phaser presets (if you have an external XML)
--------------------------------------------------
function PHASER_EFFECTS_ENGINE_CREATOR.import_predefined_phasers()
  -- For example, import an XML preset file for phaser effects
  C('import preset 21.1 /File "predefined_phaser.xml" /nu')
end

--------------------------------------------------
-- Helper: Build phaser steps in the programmer with proper MA3 syntax.
-- Here we create a 2-step phaser with low and high values,
-- and then set the phase and width properties on each step.
--------------------------------------------------
function PHASER_EFFECTS_ENGINE_CREATOR.create_phaser_steps(attribute, lowValStr, highValStr, phase_start, phase_end, width, form)
  C("ClearAll")
  
  -- Create Step 1 and assign the low value
  C(string.format('Step 1; Attribute "%s" At %s', attribute, lowValStr))
  -- Create Step 2 and assign the high value
  C(string.format('Step 2; Attribute "%s" At %s', attribute, highValStr))
  
  -- Set phaser properties using MA3's proper syntax:
  C(string.format("Set Step 1 Phase %d", phase_start))
  C(string.format("Set Step 2 Phase %d", phase_end))
  C(string.format("Set Step 1 Width %d", width))
  C(string.format("Set Step 2 Width %d", width))
  
  -- Optionally, assign the selected form.
  -- Depending on your MA3 version, this might be a custom command or require a macro.
  C(string.format("Set Step 1 Form %d", form))
  C(string.format("Set Step 2 Form %d", form))
end

--------------------------------------------------
-- Helper: Create a simple sequence to store or recall the phaser.
--------------------------------------------------
function PHASER_EFFECTS_ENGINE_CREATOR.create_sequence(naming_prefix)
  local sequence_pool = ShowData().datapools[1].Sequences  -- Adjust pool as needed
  local first_sequence = #sequence_pool + 1
  C(string.format('store sequence %d "%s_phaser_engine" /nu', first_sequence, naming_prefix))
end

--------------------------------------------------
-- Main function: Tie the UI flow to the phaser generation logic.
--------------------------------------------------
local function main()
  -- Step 1: Choose attribute and form
  local step1 = MessageBox({
    title = "PhaserFX - Step 1",
    message = "Choose the attribute and phaser form.",
    commands = {
      { name = "Cancel", value = 0 },
      { name = "Next", value = 1 }
    },
    selectors = {
      { name = "Attribute", selectedValue = 1, type = 1,
        values = { Dimmer = 1, Position = 2, Color = 3 } },
      { name = "Form", selectedValue = 1, type = 1,
        values = { Chase = 1, sin = 2, Cos = 3, ["Ramp+"] = 4, ["Ramp-"] = 5, FlyOut = 6 } }
    }
  })
  if not step1 or step1.result ~= 1 then
    Printf("PhaserFX: Cancelled at step 1.")
    return
  end

  -- Step 2: Set low and high value inputs
  local step2 = MessageBox({
    title = "PhaserFX - Step 2",
    message = "Enter low and high values for the phaser effect.",
    commands = {
      { name = "Cancel", value = 0 },
      { name = "Next", value = 1 }
    },
    inputs = {
      { name = "LowValue", value = "0", whiteFilter = "1234567890" },
      { name = "HighValue", value = "100", whiteFilter = "1234567890" }
    }
  })
  if not step2 or step2.result ~= 1 then
    Printf("PhaserFX: Cancelled at step 2.")
    return
  end

  -- Step 3: Enter phase and width settings
  local step3 = MessageBox({
    title = "PhaserFX - Step 3",
    message = "Enter phase start, phase end, and width values.",
    commands = {
      { name = "Cancel", value = 0 },
      { name = "OK", value = 1 }
    },
    inputs = {
      { name = "PhaseStart", value = "0", whiteFilter = "1234567890" },
      { name = "PhaseEnd", value = "360", whiteFilter = "1234567890" },
      { name = "Width", value = "100", whiteFilter = "1234567890" }
    }
  })
  if not step3 or step3.result ~= 1 then
    Printf("PhaserFX: Cancelled at step 3.")
    return
  end

  -- Collect input values from UI
  local i2 = step2.inputs
  local i3 = step3.inputs
  local s = step1.selectors

  local t_low  = tonumber(i2.LowValue) or 0
  local t_high = tonumber(i2.HighValue) or 100
  local phase_start = tonumber(i3.PhaseStart) or 0
  local phase_end   = tonumber(i3.PhaseEnd) or 360
  local width       = tonumber(i3.Width) or 100
  local t_attribute = tonumber(s.Attribute) or 1
  local t_form      = tonumber(s.Form) or 1

  local attributeMap = { [1] = "Dimmer", [2] = "Position", [3] = "Color" }
  local attributeString = attributeMap[t_attribute] or "Dimmer"

  local lowValStr = tostring(t_low)
  local highValStr = tostring(t_high)

  -- Create a unique naming prefix for this phaser engine
  local naming_prefix = PHASER_EFFECTS_ENGINE_CREATOR.create_name_prefix()

  -- Get declared timing values (if you need to compare against UI values)
  local timing = PHASER_EFFECTS_ENGINE_CREATOR.declare_timing_values()
  -- (timing can be used to set defaults or validate user input)

  -- Create the phaser steps using proper MA3 command syntax
  PHASER_EFFECTS_ENGINE_CREATOR.create_phaser_steps(attributeString, lowValStr, highValStr, phase_start, phase_end, width, t_form)

  -- Optionally import predefined phaser presets (if available)
  PHASER_EFFECTS_ENGINE_CREATOR.import_predefined_phasers()

  -- Declare filenames for each phaser form and create corresponding appearances
  local filenames = PHASER_EFFECTS_ENGINE_CREATOR.declare_filenames()
  PHASER_EFFECTS_ENGINE_CREATOR.create_appearances(naming_prefix, filenames)

  -- Create a sequence to store or recall this phaser engine
  PHASER_EFFECTS_ENGINE_CREATOR.create_sequence(naming_prefix)

  Printf("PhaserFX: Phaser engine created with naming prefix: %s", naming_prefix)
end

return main
