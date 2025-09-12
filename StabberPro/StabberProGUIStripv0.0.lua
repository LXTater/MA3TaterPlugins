        -- StabberProGUIStripped
        -- This is just the UI stripped out of Nick's original plugin + my additons. This doesn't do anything but open a UI that has zero function.
        -- Author: LXTater
        -- Website: www.lxtater.com
        -- Github: https://github.com/LXTater
        -- https://lxtater.odoo.com/odoo/project/1/tasks
        -- Version: 0.1.3
        -- Date: September 11, 2025
local pluginName = select(1, ...)
local componentName = select(2, ...)
local signalTable = select(3, ...)
local myHandle = select(4, ...)

function CreateInputDialog(displayHandle)  

  FixtureCount = SelectionCount()
  Interleave = SelectionCount()

   -- Get the index of the display on which to create the dialog.
  local displayIndex = Obj.Index(GetFocusDisplay())
  if displayIndex > 5 then
    displayIndex = 1
  end
  
  -- Get the overlay.
  local display = GetDisplayByIndex(displayIndex)
  if not display or not display.W or not display.H then
    Echo("Warning: Invalid display dimensions, using defaults.")
    display = { W = 1920, H = 1080 } -- Default resolution as fallback
  end
  local screenOverlay = display.ScreenOverlay
  
  -- Delete any UI elements currently displayed on the overlay.
  screenOverlay:ClearUIChildren()   
  
  -- Create the dialog base.
  -- size of the box
  local dialogWidth = 1800  -- Increased width to accommodate left and right sides
  local baseInput = screenOverlay:Append("BaseInput")
  baseInput.Name = "DMXTesterWindow"
  baseInput.H = "0"
  baseInput.W = dialogWidth
  baseInput.MaxSize = string.format("%d,%d", math.floor(display.W * 0.8), math.floor(display.H)) -- Ensure numeric values
  baseInput.MinSize = string.format("%d,0", dialogWidth - 100) -- Ensure numeric value
  baseInput.Columns = 1  
  baseInput.Rows = 2
  baseInput[1][1].SizePolicy = "Fixed"
  baseInput[1][1].Size = "80"
  baseInput[1][2].SizePolicy = "Stretch"
  baseInput.AutoClose = "No"
  baseInput.CloseOnEscape = "Yes"
  
  -- Get the colors from color themes
  local colorTransparent = Root().ColorTheme.ColorGroups.Global.Transparent
  local colorBackground = Root().ColorTheme.ColorGroups.Button.Background
  local colorBackgroundPlease = Root().ColorTheme.ColorGroups.Button.BackgroundPlease
  local colorPartlySelected = Root().ColorTheme.ColorGroups.Global.PartlySelected
  local colorPartlySelectedPreset = Root().ColorTheme.ColorGroups.Global.PartlySelectedPreset
  local colorBlack = Root().ColorTheme.ColorGroups.Global.Transparent
  -- MAtricks colors (no longer used after removal, but kept for potential future reference)
  local colorXMAtricks = Root().ColorTheme.ColorGroups.MATricks.BackgroundX
  local colorYMAtricks = Root().ColorTheme.ColorGroups.MATricks.BackgroundY
  local colorZMAtricks = Root().ColorTheme.ColorGroups.MATricks.BackgroundZ

  --Value colors
  local colorFadeValue = Root().ColorTheme.ColorGroups.ProgLayer.Fade
  local colorDelayValue = Root().ColorTheme.ColorGroups.ProgLayer.Delay
  
  -- Create the title bar.
  local titleBar = baseInput:Append("TitleBar")
  titleBar.Columns = 2  
  titleBar.Rows = 1
  titleBar.Anchors = "0,0"
  titleBar[2][2].SizePolicy = "Fixed"
  titleBar[2][2].Size = "50"
  titleBar.Texture = "corner2"
  
  local titleBarIcon = titleBar:Append("TitleButton")
  titleBarIcon.Text = "StabberPro"  -- Updated title based on image
  titleBarIcon.Texture = "corner1"
  titleBarIcon.Anchors = "0,0"
  titleBarIcon.Icon = "star"
  
  local titleBarCloseButton = titleBar:Append("CloseButton")
  titleBarCloseButton.Anchors = "1,0"
  titleBarCloseButton.Texture = "corner2"
  
  -- Create the dialog's main frame.
  local dlgFrame = baseInput:Append("DialogFrame")
  dlgFrame.H = "100%"
  dlgFrame.W = "100%"
  dlgFrame.Columns = 1  
  dlgFrame.Rows = 3
  dlgFrame.Anchors = {
    left = 0,
    right = 0,
    top = 1,
    bottom = 1
  }
  -- subtitle row
  dlgFrame[1][1].SizePolicy = "Fixed"
  dlgFrame[1][1].Size = "60"
  -- main grid row
  dlgFrame[1][2].SizePolicy = "Fixed"
  dlgFrame[1][2].Size = "400"
  -- button button row
  dlgFrame[1][3].SizePolicy = "Fixed"  
  dlgFrame[1][3].Size = "80"    
  
  -- Create the sub title.
  -- This is row 1 of the dlgFrame.
  local subTitle = dlgFrame:Append("UIObject")
  subTitle.Text = "Set Group and Value for Stabs"  -- Updated to reflect removal of MATricks
  subTitle.ContentDriven = "Yes"
  subTitle.ContentWidth = "No"
  subTitle.TextAutoAdjust = "No"
  subTitle.Anchors = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0
  }
  subTitle.Padding = {
    left = 20,
    right = 20,
    top = 15,
    bottom = 15
  }
  subTitle.Font = "Medium20"
  subTitle.HasHover = "No"
  subTitle.BackColor = colorBlack
  
  -- Create the main content grid (split left/right).
  -- This is row 2 of the dlgFrame
  local mainContent = dlgFrame:Append("UILayoutGrid")
  mainContent.Columns = 2
  mainContent.Rows = 1
  mainContent.Anchors = {
    left = 0,
    right = 0,
    top = 1,
    bottom = 1
  }
  mainContent.Margin = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 5    
  }
  mainContent.BackColor = colorTransparent

  -- Left side: Minimal recipe sheet (Group, Value)
  local recipeGrid = mainContent:Append("UILayoutGrid")
  recipeGrid.Columns = 2  -- Reduced from 3 to remove MATricks column
  recipeGrid.Rows = 2  -- Headers + one data row (removed MATricks sub-section)
  recipeGrid.Anchors = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0
  }
  recipeGrid.Margin = {
    left = 5,
    right = 5,
    top = 5,
    bottom = 5
  }
  recipeGrid.BackColor = colorTransparent

  -- Recipe headers (resized to be more compact)
  local headerGroup = recipeGrid:Append("UIObject")
  headerGroup.Text = "Group"
  headerGroup.Anchors = {left=0, right=0, top=0, bottom=0}
  headerGroup.Font = "Medium14"  -- Reduced font size
  headerGroup.TextalignmentH = "Center"
  headerGroup.Padding = "2,2"  -- Reduced padding
  headerGroup.HasHover = "No"

  local headerValue = recipeGrid:Append("UIObject")
  headerValue.Text = "Value"
  headerValue.Anchors = {left=1, right=1, top=0, bottom=0}
  headerValue.Font = "Medium14"  -- Reduced font size
  headerValue.TextalignmentH = "Center"
  headerValue.Padding = "2,2"  -- Reduced padding
  headerValue.HasHover = "No"

  -- Recipe data row (minimal: one row for inputs, resized)
  local inputGroup = recipeGrid:Append("Button")
  inputGroup.Text = "Select Group"
  inputGroup.Anchors = {left=0, right=0, top=1, bottom=1}
  inputGroup.TextalignmentH = "Center"
  inputGroup.Padding = "2,2"  -- Reduced padding
  inputGroup.W = 10  -- Keep current width
  inputGroup.H = 15  -- Changed height to ~15
  inputGroup.PluginComponent = myHandle
  inputGroup.Clicked = "SelectGroup"

  local inputPreset = recipeGrid:Append("LineEdit")
  inputPreset.Prompt = "Preset #"
  inputPreset.TextAutoAdjust = "Yes"
  inputPreset.Anchors = {left=1, right=1, top=1, bottom=1}
  inputPreset.Padding = "2,2"  -- Reduced padding
  inputPreset.W = 70  -- Keep current width
  inputPreset.H = 15  -- Changed height to ~15
  inputPreset.Filter = "0123456789"
  inputPreset.VkPluginName = "TextInputNumOnly"
  inputPreset.MaxTextLength = 6
  inputPreset.HideFocusFrame = "Yes"
  inputPreset.PluginComponent = myHandle
  -- Add TextChanged handler if needed later

  -- Right side: Original Stab Me UI (renamed to stabsGrid)
  local stabsGrid = mainContent:Append("UILayoutGrid")
  stabsGrid.Columns = 10
  stabsGrid.Rows = 5
  stabsGrid.Anchors = {
    left = 1,
    right = 1,
    top = 0,
    bottom = 0
  }
  stabsGrid.Margin = {
    left = 10,
    right = 10,
    top = 10,
    bottom = 10    
  }
  stabsGrid.BackColor = colorTransparent

  local inputMargins = {
    left = 0,
    right = 10,
    top = 0,
    bottom = 20
  }

-- manually input number of fixtures selected

    local fixtureCountInputLine = stabsGrid:Append("Button")
    fixtureCountInputLine.Margin = inputMargins
    fixtureCountInputLine.Anchors = {
        left = 0,
        right = 2,
        top = 0,
        bottom = 0
    }
    --fixtureCountInputLine.Prompt = "Number of Fixtures: " 
    --fixtureCountInputLine.TextAutoAdjust = "Yes"
    --fixtureCountInputLine.Filter = "0123456789"
    --fixtureCountInputLine.VkPluginName = "TextInputNumOnly"
    fixtureCountInputLine.Text = "Selection Count: "..FixtureCount..""
    fixtureCountInputLine.TextalignmentH = "Left"
    fixtureCountInputLine.Padding = '5,5'
    fixtureCountInputLine.HasHover = 'No'
    --fixtureCountInputLine.MaxTextLength = 6
    --fixtureCountInputLine.HideFocusFrame = "Yes"
    fixtureCountInputLine.PluginComponent = myHandle
    --fixtureCountInputLine.TextChanged = "OnInputFixtureCountTextChanged" 

    

    local stabsTypeStraight = stabsGrid:Append("CheckBox")
    stabsTypeStraight.Margin = inputMargins
    stabsTypeStraight.Anchors = {
        left = 3,
        right = 4,
        top = 0,
        bottom = 0
        }
    stabsTypeStraight.Text = "Straight Stabs"
    stabsTypeStraight.TextalignmentH = "Center"
    stabsTypeStraight.State = 1;
    stabsTypeStraight.Padding = '5,5'
    stabsTypeStraight.PluginComponent = myHandle
    stabsTypeStraight.Clicked = "StraightStabsSelected"
    --add color?

    local stabsTypeScatter = stabsGrid:Append("CheckBox")
    stabsTypeScatter.Margin = inputMargins
    stabsTypeScatter.Anchors = {
        left = 5,
        right = 6,
        top = 0,
        bottom = 0
    }
    stabsTypeScatter.Text = "Scatter Stabs"
    stabsTypeScatter.TextalignmentH = "Center"
    stabsTypeScatter.State = 0;
    stabsTypeScatter.Padding = '5,5'
    stabsTypeScatter.PluginComponent = myHandle
    stabsTypeScatter.Clicked = "ScatterStabsSelected"
    --add color?

    local stabsTypeShuffle = stabsGrid:Append("CheckBox")
    stabsTypeShuffle.Margin = inputMargins
    stabsTypeShuffle.Anchors = {
        left = 7,
        right = 8,
        top = 0,
        bottom = 0
    }
    stabsTypeShuffle.Text = "Shuffle Stabs"
    stabsTypeShuffle.TextalignmentH = "Center"
    stabsTypeShuffle.State = 0;
    stabsTypeShuffle.Padding = '5,5'
    stabsTypeShuffle.PluginComponent = myHandle
    stabsTypeShuffle.Clicked = "ShuffleStabsSelected"
    --add color?



  -- sequence selected option
  local sequenceLineSelect = stabsGrid:Append("CheckBox")
    --sequenceLineSelect.Margin = inputMargins
    sequenceLineSelect.Anchors = {
     left = 0,
     right = 1,
     top = 1,
     bottom = 1
   }  
    sequenceLineSelect.Text = "Sequence Selected"
    sequenceLineSelect.TextalignmentH = "Center";
    sequenceLineSelect.State = 0;
    sequenceLineSelect.Padding = "5,5"
    sequenceLineSelect.PluginComponent = myHandle
    sequenceLineSelect.Clicked = "SequenceSelected"
    sequenceLineSelect.BackColor = colorPartlySelected


   -- manually input sequence number

   local sequenceInputLine = stabsGrid:Append("LineEdit")
   --sequenceInputLine.Margin = inputMargins
   sequenceInputLine.Anchors = {
    left = 2,
    right = 3,
    top = 1,
    bottom = 1
   }
    sequenceInputLine.Prompt = "Sequence #: " 
    sequenceInputLine.TextAutoAdjust = "Yes"
    sequenceInputLine.Filter = "0123456789"
    sequenceInputLine.VkPluginName = "TextInputNumOnly"
    sequenceInputLine.Content = ""
    sequenceInputLine.MaxTextLength = 6
    sequenceInputLine.HideFocusFrame = "Yes"
    sequenceInputLine.PluginComponent = myHandle
    sequenceInputLine.TextChanged = "OnInputSequenceTextChanged"
    sequenceLineSelect.BackColor = colorPartlySelected






    ----------------
    ---Direction 
    ---
    local directionForwardSelect = stabsGrid:Append("CheckBox")
    directionForwardSelect.Anchors = {
     left = 7,
     right = 8,
     top = 4,
     bottom = 4
   }

    directionForwardSelect.Text = "Direction Forward"
    directionForwardSelect.TextalignmentH = "Center";
    directionForwardSelect.State = 1;
    directionForwardSelect.Padding = "5,5"
    directionForwardSelect.PluginComponent = myHandle
    directionForwardSelect.Clicked = "DirectionForward"
    --directionForwardSelect.BackColor = colorPartlySelected



    local directionBackwardSelect = stabsGrid:Append("CheckBox")
    directionBackwardSelect.Anchors = {
     left = 5,
     right = 6,
     top = 4,
     bottom = 4
   }

    directionBackwardSelect.Text = "Direction Backward"
    directionBackwardSelect.TextalignmentH = "Center";
    directionBackwardSelect.State = 0;
    directionBackwardSelect.Padding = "5,5"
    directionBackwardSelect.PluginComponent = myHandle
    directionBackwardSelect.Clicked = "DirectionBackward"
    --directionBackwardSelect.BackColor = colorPartlySelected
     
    ---
    ---
    ---Fade and Delay
    ---
    ---
    local fadeTime = stabsGrid:Append("LineEdit")
    fadeTime.Margin = inputMargins
    fadeTime.Prompt = "Fade Off: "
    fadeTime.TextAutoAdjust = "Yes"
    -- positioning of textbox
    fadeTime.Anchors = {
      left = 0,
      right = 1,
      top = 4,
      bottom = 4
    }
    fadeTime.Padding = "5,5"
    fadeTime.Filter = ".0123456789"
    fadeTime.VkPluginName = "TextInputNumOnly"
    fadeTime.Content = "0"
    fadeTime.MaxTextLength = 6
    fadeTime.HideFocusFrame = "Yes"
    fadeTime.PluginComponent = myHandle
    fadeTime.TextChanged = "OnInputFadeTimeChanged"
    fadeTime.BackColor = colorFadeValue
    OffFade = 0

    local delayTime = stabsGrid:Append("LineEdit")
    delayTime.Margin = inputMargins
    delayTime.Prompt = "Delay Off: "
    delayTime.TextAutoAdjust = "Yes"
    -- positioning of textbox
    delayTime.Anchors = {
      left = 2,
      right = 3,
      top = 4,
      bottom = 4
    }
    delayTime.Padding = "5,5"
    delayTime.Filter = ".0123456789"
    delayTime.VkPluginName = "TextInputNumOnly"
    delayTime.Content = "0.25"
    delayTime.MaxTextLength = 6
    delayTime.HideFocusFrame = "Yes"
    delayTime.PluginComponent = myHandle
    delayTime.TextChanged = "OnInputDelayTimeChanged"
    delayTime.BackColor = colorDelayValue
    OffTime = 0.25
    

   

    ---
    ---
    ---
    ---
    

    -- reset all matricks button
   local resetAllButton = stabsGrid:Append("Button")
   resetAllButton.Anchors = {
     left = 9,
     right = 9,
     top = 0,
     bottom = 0
   }
   resetAllButton.Margin = inputMargins
   resetAllButton.Text = "Reset All"
   resetAllButton.TextalignmentH = "Center";
   --resetXButton.State = 0;
   resetAllButton.Padding = "5,5"
   resetAllButton.PluginComponent = myHandle
   resetAllButton.Clicked = "ResetAllButtonClicked"
    






   --Number of steps Display

   local displayNumSteps = stabsGrid:Append("Button")
   displayNumSteps.Anchors = {
    left = 6,
    right = 7,
    top = 1,
    bottom = 1
   }
   displayNumSteps.HasHover = "No"
   displayNumSteps.Text = ("Number of Steps: "..FixtureCount.."")
   displayNumSteps.TextalignmentH = "Center"
   displayNumSteps.Padding = "5,5"
   displayNumSteps.PluginComponent = myHandle

-- Number of steps Display


   local numberofsteps = stabsGrid:Append("Button")
   numberofsteps.Anchors = {
    left = 8,
    right = 8,
    top = 1,
    bottom = 1
   }
   numberofsteps.HasHover = "No"
   numberofsteps.Text = fixtureCountInputLine.Text
   numberofsteps.TextalignmentH = "Center";
   numberofsteps.Padding = "5,5"
   numberofsteps.PluginComponent = myHandle

   local storetoseqdisplay = stabsGrid:Append("Button")
   storetoseqdisplay.Anchors = {
    left = 4,
    right = 5,
    top = 1,
    bottom = 1
   }
   storetoseqdisplay.HasHover = "No"
   storetoseqdisplay.Text = ''
   storetoseqdisplay.TextalignmentH = "Center";
   storetoseqdisplay.Padding = "5,5"
   storetoseqdisplay.PluginComponent = myHandle




---------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------



  -- Create the UI elements for the first input.
  -- line for X Groups input
  local input1ALineEdit = stabsGrid:Append("LineEdit")
  input1ALineEdit.Margin = inputMargins
  input1ALineEdit.Prompt = "XGroups: "
  input1ALineEdit.TextAutoAdjust = "Yes"
  -- positioning of textbox
  input1ALineEdit.Anchors = {
    left = 0,
    right = 1,
    top = 2,
    bottom = 2
  }
  input1ALineEdit.Padding = "5,5"
  input1ALineEdit.Filter = "0123456789"
  input1ALineEdit.VkPluginName = "TextInputNumOnly"
  input1ALineEdit.Content = ""
  input1ALineEdit.MaxTextLength = 6
  input1ALineEdit.HideFocusFrame = "Yes"
  input1ALineEdit.PluginComponent = myHandle
  input1ALineEdit.TextChanged = "OnInput1ATextChanged"
  input1ALineEdit.BackColor = colorXMAtricks
  XGroups = 0

  -- line for X blocks input
  local input1BLineEdit = stabsGrid:Append("LineEdit")
  input1BLineEdit.Margin = inputMargins
  input1BLineEdit.Prompt = "XBlocks: "
  input1BLineEdit.TextAutoAdjust = "Yes"
  -- positioning of textbox
  input1BLineEdit.Anchors = {
    left = 2,
    right = 3,
    top = 2,
    bottom = 2
  }
  input1BLineEdit.Padding = "5,5"
  input1BLineEdit.Filter = "0123456789"
  input1BLineEdit.VkPluginName = "TextInputNumOnly"
  input1BLineEdit.Content = ""
  input1BLineEdit.MaxTextLength = 6
  input1BLineEdit.HideFocusFrame = "Yes"
  input1BLineEdit.PluginComponent = myHandle
  input1BLineEdit.TextChanged = "OnInput1BTextChanged"
  input1BLineEdit.BackColor = colorXMAtricks
  XBlocks = 0


   -- line for X wings input
   local input1CLineEdit = stabsGrid:Append("LineEdit")
   input1CLineEdit.Margin = inputMargins
   input1CLineEdit.Prompt = "XWings: "
   input1CLineEdit.TextAutoAdjust = "Yes"
   input1CLineEdit.Anchors = {
     left = 4,
     right = 5,
     top = 2,
     bottom = 2
   }
   input1CLineEdit.Padding = "5,5"
   input1CLineEdit.Filter = "0123456789"
   input1CLineEdit.VkPluginName = "TextInputNumOnly"
   input1CLineEdit.Content = ""
   input1CLineEdit.MaxTextLength = 6
   input1CLineEdit.HideFocusFrame = "Yes"
   input1CLineEdit.PluginComponent = myHandle
   input1CLineEdit.TextChanged = "OnInput1CTextChanged" 
   input1CLineEdit.BackColor = colorXMAtricks
   XWings = 0

   -- Prefer Axis Checkbox
   local checkBox1 = stabsGrid:Append("CheckBox")
   checkBox1.Margin = inputMargins
   checkBox1.Anchors = {
     left = 6,
     right = 7,
     top = 2,
     bottom = 2
   }  
   checkBox1.Text = "Prefer X Axis"
   checkBox1.TextalignmentH = "Left";
   checkBox1.State = 1;
   checkBox1.Padding = "5,5"
   checkBox1.PluginComponent = myHandle
   checkBox1.Clicked = "CheckBoxXClicked"
   checkBox1.BackColor = colorXMAtricks
   --checkBox1.ColorIndicator = colorXMAtricks
   XAxisSelected = 0

   -- reset x matricks button
   local resetXButton = stabsGrid:Append("Button")
   resetXButton.Anchors = {
     left = 8,
     right = 8,
     top = 2,
     bottom = 2
   }
   resetXButton.Margin = inputMargins
   resetXButton.Text = "Reset X"
   resetXButton.TextalignmentH = "Center";
   --resetXButton.State = 0;
   resetXButton.Padding = "5,5"
   resetXButton.PluginComponent = myHandle
   resetXButton.Clicked = "ResetXButtonClicked"



-------
---Y elements
---


  -- Create the UI elements for the second input.
    -- line for Y Groups input
    local input2ALineEdit = stabsGrid:Append("LineEdit")
    input2ALineEdit.Margin = inputMargins
    input2ALineEdit.Prompt = "YGroups: "
    input2ALineEdit.TextAutoAdjust = "Yes"
    -- positioning of textbox
    input2ALineEdit.Anchors = {
      left = 0,
      right = 1,
      top = 3,
      bottom = 3
    }
    input2ALineEdit.Padding = "5,5"
    input2ALineEdit.Filter = "0123456789"
    input2ALineEdit.VkPluginName = "TextInputNumOnly"
    input2ALineEdit.Content = ""
    input2ALineEdit.MaxTextLength = 6
    input2ALineEdit.HideFocusFrame = "Yes"
    input2ALineEdit.PluginComponent = myHandle
    input2ALineEdit.TextChanged = "OnInput2ATextChanged"
    input2ALineEdit.BackColor = colorYMAtricks
    YGroups = 0
  
    -- line for Y blocks input
    local input2BLineEdit = stabsGrid:Append("LineEdit")
    input2BLineEdit.Margin = inputMargins
    input2BLineEdit.Prompt = "YBlocks: "
    input2BLineEdit.TextAutoAdjust = "Yes"
    -- positioning of textbox
    input2BLineEdit.Anchors = {
      left = 2,
      right = 3,
      top = 3,
      bottom = 3
    }
    input2BLineEdit.Padding = "5,5"
    input2BLineEdit.Filter = "0123456789"
    input2BLineEdit.VkPluginName = "TextInputNumOnly"
    input2BLineEdit.Content = ""
    input2BLineEdit.MaxTextLength = 6
    input2BLineEdit.HideFocusFrame = "Yes"
    input2BLineEdit.PluginComponent = myHandle
    input2BLineEdit.TextChanged = "OnInput2BTextChanged"
    input2BLineEdit.BackColor = colorYMAtricks
    YBlocks = 0
  
     -- line for Y wings input
    local input2CLineEdit = stabsGrid:Append("LineEdit")
    input2CLineEdit.Margin = inputMargins
    input2CLineEdit.Prompt = "YWings: "
    input2CLineEdit.TextAutoAdjust = "Yes"
    input2CLineEdit.Anchors = {
       left = 4,
       right = 5,
       top = 3,
       bottom = 3
     }
    input2CLineEdit.Padding = "5,5"
    input2CLineEdit.Filter = "0123456789"
    input2CLineEdit.VkPluginName = "TextInputNumOnly"
    input2CLineEdit.Content = ""
    input2CLineEdit.MaxTextLength = 6
    input2CLineEdit.HideFocusFrame = "Yes"
    input2CLineEdit.PluginComponent = myHandle
    input2CLineEdit.TextChanged = "OnInput2CTextChanged"
    input2CLineEdit.BackColor = colorYMAtricks
    YWings = 0
  
    -- PRefer Axis Checkbox
    local checkBox2 = stabsGrid:Append("CheckBox")
    checkBox2.Anchors = {
     left = 6,
     right = 7,
     top = 3,
     bottom = 3
    }
    checkBox2.Margin = inputMargins
    checkBox2.Text = "Prefer Y Axis"
    checkBox2.TextalignmentH = "Left";
    checkBox2.State = 0;
    checkBox2.Padding = "5,5"
    checkBox2.PluginComponent = myHandle
    checkBox2.Clicked = "CheckBoxYClicked"
    checkBox2.BackColor = colorYMAtricks
    YAxisSelected = 0
   --checkBox1.ColorIndicator = colorBackgroundPlease

   -- reset Y matricks button
   local resetYButton = stabsGrid:Append("Button")
   resetYButton.Anchors = {
     left = 8,
     right = 8,
     top = 3,
     bottom = 3
   }
   resetYButton.Margin = inputMargins
   resetYButton.Text = "Reset Y"
   resetYButton.TextalignmentH = "Center";
   --resetXButton.State = 0;
   resetYButton.Padding = "5,5"
   resetYButton.PluginComponent = myHandle
   resetYButton.Clicked = "ResetYButtonClicked"




  -- Create the button grid.
  -- This is row 3 of the dlgFrame. --- Apply & Cancel Button section
  local buttonGrid = dlgFrame:Append("UILayoutGrid")
  buttonGrid.Columns = 2
  buttonGrid.Rows = 1
  buttonGrid.Anchors = {
    left = 0,
    right = 0,
    top = 2,
    bottom = 2
  }
  
  local applyButton = buttonGrid:Append("Button");
  applyButton.Anchors = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0
  }
  applyButton.Textshadow = 1;
  applyButton.HasHover = "Yes";
  applyButton.Text = "Apply";
  applyButton.Font = "Medium20";
  applyButton.TextalignmentH = "Centre";
  applyButton.PluginComponent = myHandle
  applyButton.Clicked = "ApplyButtonClicked"  

  local cancelButton = buttonGrid:Append("Button");
  cancelButton.Anchors = {
    left = 1,
    right = 1,
    top = 0,
    bottom = 0
  }
  cancelButton.Textshadow = 1;
  cancelButton.HasHover = "Yes";
  cancelButton.Text = "Cancel";
  cancelButton.Font = "Medium20";
  cancelButton.TextalignmentH = "Centre";
  cancelButton.PluginComponent = myHandle
  cancelButton.Clicked = "CancelButtonClicked"
  cancelButton.Visible = "Yes"  
  




-------------------------------------------------------------------------------------------------------------------------------------------
  ------------------------------------------------------- Handlers ------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------
  ---
  ---
  
  ---
  --- Var set
  --- 
  TYPE = 1
  Direction = ">"
  XAxisSelected = 1
  
  ---

  -- update the number of steps that will be created
  function UpdateNumSteps(input)
    numberofsteps.Text = math.floor(tonumber(input))
    
end



------- Apply and cancel Buttons


  signalTable.CancelButtonClicked = function(caller)
    
    Echo("Cancel button clicked.")
    Obj.Delete(screenOverlay, Obj.Index(baseInput))
    
  end  
  
  signalTable.ApplyButtonClicked = function(caller)
    
    Echo("Apply button clicked.")    
    
    if (applyButton.BackColor == colorBackground) then
      applyButton.BackColor = colorBackgroundPlease
    else
      applyButton.BackColor = colorBackground
    end 
    Create_Seq()
    Obj.Delete(screenOverlay, Obj.Index(baseInput))
    
  end



  -- var sets

  --set sequence to be stored to - is selected
  signalTable.SequenceSelected = function(caller)
  
    Echo("Sequence Selected '" .. caller.Text .. "' clicked. State = " .. caller.State)
    
    if (caller.State == 1) then
      caller.State = 0
    else
      caller.State = 1
      Storeseq = SelectedSequence()
      Echo("Selected Sequence number is "..Storeseq.." ")
      sequenceInputLine.Content = ''
      storetoseqdisplay.Text = ("Store Seq: "..Storeseq)
    end
  end

  -- store seq is manually put in
    signalTable.OnInputSequenceTextChanged = function(caller)
 
        Echo("InputSequencechanged: '" .. caller.Content .. "'")
        if caller.Content ~= '' then
            Storeseq = caller.Content
            storetoseqdisplay.Text = ("Store Seq: "..Storeseq)
            if sequenceLineSelect.State == 1 then
                sequenceLineSelect.State = 0
            end
        end
      end

    signalTable.OnInputFixtureCountTextChanged = function (caller)
        Echo("Fixture Count text changed: '"..caller.Content.."'")
        Interleave = caller.Content
        UpdateNumSteps(Interleave)

        
    end


    -- stabs type 

    signalTable.StraightStabsSelected = function(caller)
        Echo("Straight Stabs Selected")
        if (caller.State == 1) then
                  caller.State = 0
        else
                  caller.State = 1
                  TYPE = 1
                  stabsTypeScatter.State = 0
                  stabsTypeShuffle.State = 0
        end
    end

    signalTable.ScatterStabsSelected = function(caller)
        Echo("Scatter Stabs Selected")
        if (caller.State == 1) then
                  caller.State = 0
        else
                  caller.State = 1
                  TYPE = 2
                  stabsTypeStraight.State = 0
                  stabsTypeShuffle.State = 0
        end
    end

    signalTable.ShuffleStabsSelected = function(caller)
        Echo("Shuffle Stabs Selected")
        if (caller.State == 1) then
                  caller.State = 0
        else
                  caller.State = 1
                  TYPE = 3
                  stabsTypeStraight.State = 0
                  stabsTypeScatter.State = 0
        end
    end

    ------Direction selection
    signalTable.DirectionForward = function(caller)
      Echo("Forward direction selected")
      if (caller.State == 1) then
                caller.State = 0
      else
                caller.State = 1
                Direction = ">"
                directionBackwardSelect.State = 0
      end
  end

  signalTable.DirectionBackward = function(caller)
    Echo("Backward direction selected")
    if (caller.State == 1) then
              caller.State = 0
    else
              caller.State = 1
              Direction = "<"
              directionForwardSelect.State = 0
    end
end

    

    signalTable.ResetAllButtonClicked = function(caller)
  
        Echo("Reset All Button '" .. caller.Text .. "' clicked. State = " .. caller.State)
        -- send commands
        Cmd('Set selection Property "XGroup" "None"')
        Cmd('Set selection Property "XBlock" "None"')
        Cmd('Set selection Property "XWings" "None"')
        -- change visible values
    
        input1ALineEdit.Content = ""
        input1BLineEdit.Content = ""
        input1CLineEdit.Content = ""
        checkBox1.State = 0

        Cmd('Set selection Property "YGroup" "None"')
        Cmd('Set selection Property "YBlock" "None"')
        Cmd('Set selection Property "YWings" "None"')
    -- change visible values

        input2ALineEdit.Content = ""
        input2BLineEdit.Content = ""
        input2CLineEdit.Content = ""
        checkBox2.State = 0

        Cmd("Reset Selection MAtricks")

        
        end



  
  -- X Matricks
  signalTable.OnInput1ATextChanged = function(caller)
 
    Echo("Input1A changed: '" .. caller.Content .. "'")
    if caller.Content ~= '' then
        Cmd('Set selection Property "XGroup" '..caller.Content..'')
        Interleave = caller.Content
        XGroups = tonumber(caller.Content)
    elseif caller.Content == '' then
      Interleave = FixtureCount
      XGroups = 0
    end
    UpdateNumSteps(Interleave)
  end

  signalTable.OnInput1BTextChanged = function(caller)
 
    Echo("Input1B changed: '" .. caller.Content .. "'")
    if caller.Content ~= '' then
        Cmd('Set selection Property "XBlock" '..caller.Content..'')
        Interleave = (Interleave / caller.Content)
        XBlocks = tonumber(caller.Content)
    elseif caller.Content == '' then
        Interleave = FixtureCount
        XBlocks = 0
    end
    UpdateNumSteps(Interleave) 
  end

  signalTable.OnInput1CTextChanged = function(caller)
    Echo("Input1C changed: '" .. caller.Content .. "'")
    if caller.Content ~= ''then
        Cmd('Set selection Property "XWings" '..caller.Content..'')
        Interleave = (Interleave / caller.Content)
        XWings = tonumber(caller.Content)
    elseif caller.Content == '' then
      Interleave = FixtureCount
      XWings = 0
    end
    UpdateNumSteps(Interleave)
  end

  -- X Axis prefer // Shuffle Button
  signalTable.CheckBoxXClicked = function(caller)
    if (caller.State == 1) then
      caller.State = 0
      Echo("Checkbox '" .. caller.Text .. "' clicked. State = " .. caller.State)
      XAxisSelected = 0
      
   else
      caller.State = 1
      XAxisSelected = 1
      YAxisSelected = 0
      ZAxisSelected = 0
      checkBox2.State = 0
      Echo("Checkbox '" .. caller.Text .. "' clicked. State = " .. caller.State)
      Echo("X Axis Selected")
    
      
    end
  end

signalTable.ResetXButtonClicked = function(caller)
  
    Echo("Reset X MAtricks Button '" .. caller.Text .. "' clicked. State = " .. caller.State)
    -- send commands
    Cmd('Set selection Property "XGroup" "None"')
    Cmd('Set selection Property "XBlock" "None"')
    Cmd('Set selection Property "XWings" "None"')
    -- change visible values

    input1ALineEdit.Content = ""
    input1BLineEdit.Content = ""
    input1CLineEdit.Content = ""
    checkBox1.State = 1
    Interleave = FixtureCount
    
    end
    




  -- Y Matricks
  --Y Groups
  signalTable.OnInput2ATextChanged = function(caller)
 
    Echo("Input2A changed: '" .. caller.Content .. "'")
    if caller.Content ~= '' then
        Cmd('Set selection Property "YGroup" '..caller.Content..'')
        Interleave = caller.Content
        YGroups = tonumber(caller.Content)
    elseif caller.Content == '' then
        Interleave = FixtureCount
        YGroups = 0
    end
    UpdateNumSteps(Interleave)
  end

  --Y Blocks
  signalTable.OnInput2BTextChanged = function(caller)
 
    Echo("Input2B changed: '" .. caller.Content .. "'")
    if caller.Content ~= '' then
        Cmd('Set selection Property "YBlock" '..caller.Content..'')
        Interleave = (Interleave / caller.Content)
        YBlocks = tonumber(caller.Content)
    elseif caller.Content == '' then
      Interleave = FixtureCount
      YBlocks = 0
    end
    UpdateNumSteps(Interleave)
  end

  -- Y WIngs
  signalTable.OnInput2CTextChanged = function(caller)
 
    Echo("Input2C changed: '" .. caller.Content .. "'")
    if caller.Content ~= '' then
        Cmd('Set selection Property "YWings" '..caller.Content..'')
        Interleave = (Interleave / caller.Content)
        YWings = tonumber(caller.Content)
    elseif caller.Content == '' then
        YWings = 0
        Interleave = FixtureCount
    end
    UpdateNumSteps(Interleave)
  end 

-- Y Prefer Axis // Shuffle checkbox
  signalTable.CheckBoxYClicked = function(caller)
--    
    if (caller.State == 1) then
      Echo("Checkbox2 '" .. caller.Text .. "' clicked. State = " .. caller.State)
      caller.State = 0
      YAxisSelected = 0
  
      
    else
      caller.State = 1
      Echo("Checkbox2 '" .. caller.Text .. "' clicked. State = " .. caller.State)
      Echo("Y Axis Selected")
      XAxisSelected = 0
      YAxisSelected = 1
      ZAxisSelected = 0
      checkBox1.State = 0

    end
 end

  signalTable.ResetYButtonClicked = function(caller)
    Echo("Reset Y MAtricks Button '" .. caller.Text .. "' clicked. State = " .. caller.State)
    -- send commands
    Cmd('Set selection Property "YGroup" "None"')
    Cmd('Set selection Property "YBlock" "None"')
    Cmd('Set selection Property "YWings" "None"')
    -- change visible values

    input2ALineEdit.Content = ""
    input2BLineEdit.Content = ""
    input2CLineEdit.Content = ""
    checkBox2.State = 1
    Interleave = FixtureCount
    end

---
--- Set Fade and Delay Times
---
  signalTable.OnInputFadeTimeChanged = function(caller)
    if caller.Content ~= '' then
      OffFade = tonumber(caller.Content)
    elseif caller.Content == '' then
      OffFade = 0
    end
  end

  signalTable.OnInputDelayTimeChanged = function(caller)
    if caller.Content ~= '' then
      OffTime = tonumber(caller.Content)
    elseif caller.Content == '' then
      OffTime = 0
    end
  end

  

UpdateNumSteps(Interleave)
  
  -- Group selection popup handler with group number and fixture count
  signalTable.SelectGroup = function(caller)
    local groups = Root().ShowData.DataPools.Default.Groups:Children()
    local groupItems = {}
    for _, group in ipairs(groups) do
      local groupNum = group.id  -- Get the group number
      local fixtureCount = #group:Children()  -- Get the number of fixtures in the group
      table.insert(groupItems, string.format("%d: %s (%d fixtures)", groupNum, group.name, fixtureCount))
    end
    local _, choice = PopupInput{title = "Select Group", caller = caller, items = groupItems, selectedValue = caller.Text}
    if choice then
      caller.Text = choice
      -- Optionally store the selected group number or name for further use
      local selectedNum = tonumber(choice:match("^(%d+)"))
      if selectedNum then
        -- You can use selectedNum to apply the group selection via a command if needed
        -- e.g., Cmd('Select Group ' .. selectedNum)
      end
    end
  end
 
end

 return CreateInputDialog