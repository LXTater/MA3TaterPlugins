-- TaterSolitaire - Phase 1: UI Setup with Card Grid (font + signalTable patch)

function main(...)
    local pluginName = select(1, ...)
    local componentName = select(2, ...)
    local signalTable = select(3, ...) or {}  -- <-- Ensure non-nil table
    local myHandle = select(4, ...)
  
    local display = GetFocusDisplay()
    local overlay = display.ScreenOverlay
    overlay:ClearUIChildren()
  
    local cardSymbols = {
      "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"
    }
  
    local suits = {"♠", "♥", "♦", "♣"} -- Spades, Hearts, Diamonds, Clubs
    local deck = {}
  
    -- Generate a basic shuffled deck (face-up for now)
    math.randomseed(os.time())
    for _, suit in ipairs(suits) do
      for _, value in ipairs(cardSymbols) do
        table.insert(deck, value .. suit)
      end
    end
    for i = #deck, 2, -1 do
      local j = math.random(i)
      deck[i], deck[j] = deck[j], deck[i]
    end
  
    -- Base dialog
    local base = overlay:Append("BaseInput")
    base.Name = "TaterSolitaire"
    base.W = 1500
    base.H = 0
    base.Columns = 1
    base.Rows = 2
    base[1][1].SizePolicy = "Fixed"
    base[1][1].Size = 60
    base[1][2].SizePolicy = "Stretch"
    base.AutoClose = "No"
    base.CloseOnEscape = "Yes"
  
    local title = base:Append("TitleBar")
    title.Columns = 2
    title.Rows = 1
    title[2][2].SizePolicy = "Fixed"
    title[2][2].Size = 50
  
    local titleButton = title:Append("TitleButton")
    titleButton.Text = "TaterSolitaire"
    titleButton.Icon = "star"
    titleButton.PluginComponent = myHandle
  
    local closeButton = title:Append("CloseButton")
    closeButton.PluginComponent = myHandle
    closeButton.Clicked = "QuitGame"
  
    local dlg = base:Append("DialogFrame")
    dlg.Columns = 1
    dlg.Rows = 2
    dlg[1][1].SizePolicy = "Stretch"
    dlg[1][2].SizePolicy = "Fixed"
    dlg[1][2].Size = 100
  
    local grid = dlg:Append("UILayoutGrid")
    grid.Columns = 7
    grid.Rows = 5
    grid.Anchors = "0,0"
    grid.Margin = { left = 20, right = 20, top = 10, bottom = 10 }
  
    -- Display first 35 cards in a grid (5x7)
    for i = 1, 35 do
      local btn = grid:Append("Button")
      btn.Text = deck[i]
      btn.Font = "Medium20"
      btn.TextalignmentH = "Centre"
      btn.TextalignmentV = "Centre"
      btn.Padding = { left = 5, right = 5, top = 5, bottom = 5 }
      btn.Anchors = {
        left = (i - 1) % 7,
        right = (i - 1) % 7,
        top = math.floor((i - 1) / 7),
        bottom = math.floor((i - 1) / 7)
      }
      btn.PluginComponent = myHandle
      btn.Clicked = "CardClicked"
    end
  
    local buttonBar = dlg:Append("UILayoutGrid")
    buttonBar.Columns = 2
    buttonBar.Rows = 1
    buttonBar.Anchors = "0,1"
    buttonBar.Margin = { left = 100, right = 100, top = 10, bottom = 10 }
  
    local resetBtn = buttonBar:Append("Button")
    resetBtn.Text = "Restart"
    resetBtn.Font = "Medium20"
    resetBtn.PluginComponent = myHandle
    resetBtn.Clicked = "QuitGame"
  
    local quitBtn = buttonBar:Append("Button")
    quitBtn.Text = "Quit"
    quitBtn.Font = "Medium20"
    quitBtn.PluginComponent = myHandle
    quitBtn.Clicked = "QuitGame"
  
    signalTable.QuitGame = function()
      overlay:ClearUIChildren()
    end
  
    signalTable.CardClicked = function(caller)
      Echo("Clicked: " .. caller.Text)
    end
  end
  
  return main
  