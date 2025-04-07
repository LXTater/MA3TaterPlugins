-- GrandMA3 Plugin: TaterFX - MessageBox-based UI version (Compatible with all MA3 versions)

local function main()
  local returnTable = MessageBox({
    title = "TaterFX - Old Heads Unite!",
    message = "Enter your phaser settings below.",
    commands = {
      { name = "Cancel", value = 0 },
      { name = "OK", value = 1 }
    },
    inputs = {
      { name = "LowValue", value = "0", whiteFilter = "1234567890" },
      { name = "HighValue", value = "100", whiteFilter = "1234567890" },
      { name = "Groups", value = "0", whiteFilter = "1234567890" },
      { name = "Blocks", value = "0", whiteFilter = "1234567890" },
      { name = "Wings", value = "0", whiteFilter = "1234567890" },
      { name = "PhaseX", value = "0", whiteFilter = "1234567890" },
      { name = "PhaseY", value = "360", whiteFilter = "1234567890" },
      { name = "Width", value = "100", whiteFilter = "1234567890" }
    },
    selectors = {
      {
        name = "Attribute",
        selectedValue = 1,
        type = 0,
        values = { Dimmer = 1, Position = 2, Color = 3 }
      },
      {
        name = "Form",
        selectedValue = 1,
        type = 0,
        values = {
          Chase = 1,
          sin = 2,
          Cos = 3,
          RampPlus = 4,
          RampMinus = 5,
          FlyOut = 6
        }
      }
    },
    states = {
      { name = "Shuffle" },
      { name = "Loop" }
    }
  })

  -- Read the data back
  if returnTable and returnTable.result == 1 then
    local i = returnTable.inputs
    local s = returnTable.selectors
    local st = returnTable.states

    taterLowValue = tonumber(i.LowValue) or 0
    taterHighValue = tonumber(i.HighValue) or 100
    taterGroups = tonumber(i.Groups) or 0
    taterBlocks = tonumber(i.Blocks) or 0
    taterWings = tonumber(i.Wings) or 0
    taterPhaseX = tonumber(i.PhaseX) or 0
    taterPhaseY = tonumber(i.PhaseY) or 360
    taterWidth = tonumber(i.Width) or 100

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
  else
    Printf("TaterFX cancelled or closed.")
  end
end

return main
