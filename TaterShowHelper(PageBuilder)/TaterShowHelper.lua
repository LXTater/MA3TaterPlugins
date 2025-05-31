-- grandMA3 Plugin: TaterShowHelper (PageBuilder)
-- Author: Tater
-- Plugin Version: 0.2.0
-- MA3 Version: 2.2.5.2
-- https://www.lxtater.com
-- https://github.com/LXTater/MA3TaterPlugins

return function()

  local TaterPageStart = tonumber(GetVar(GlobalVars(), "TaterPageStart") or "11")
  local TaterMacroStart = tonumber(GetVar(GlobalVars(), "TaterMacroStart") or "1")
  local TaterMacroEnd = tonumber(GetVar(GlobalVars(), "TaterMacroEnd") or "11")

  local function getMacroNames()
    local names = {}
    for i = TaterMacroStart, TaterMacroEnd do
      local m = DataPool().Macros[i]
      if m and m.name and m.name ~= "" then
        table.insert(names, string.format("%d: %s", i, m.name))
      end
    end
    return names
  end

  local function setMacroRange()
    local start = tonumber(TextInput("Enter starting macro slot:", tostring(TaterMacroStart))) or TaterMacroStart
    local finish = tonumber(TextInput("Enter ending macro slot:", tostring(TaterMacroEnd))) or TaterMacroEnd
    if finish <= start then
      ErrPrintf("[TaterPageBuilder][Error]: Ending slot must be after starting slot.")
      return
    end
    TaterMacroStart = start
    TaterMacroEnd = finish
    SetVar(GlobalVars(), "TaterMacroStart", tostring(start))
    SetVar(GlobalVars(), "TaterMacroEnd", tostring(finish))
  end

  local function setStartPage()
    local pg = tonumber(TextInput("Enter starting page number:", tostring(TaterPageStart)))
    if pg then
      TaterPageStart = pg
      SetVar(GlobalVars(), "TaterPageStart", tostring(pg))
    end
  end

  local function buildPages()
    local pageOffset = 0
    for i = TaterMacroStart, TaterMacroEnd do
      local macro = DataPool().Macros[i]
      if macro and macro.name and macro.name ~= "" then
        local currentPage = TaterPageStart + pageOffset

        Cmd(string.format("Store Page %d", currentPage))
        Cmd(string.format("Label Page %d \"%s\"", currentPage, macro.name))

        local songPage = string.format("%d.%s", currentPage, macro.name)
        Cmd(string.format("Store Page %s \"%s\"", songPage, macro.name))
        Cmd(string.format("Assign Appearance \"Song\" At Page %s", songPage))
        Cmd(string.format("Select Page %s", songPage))

        Cmd("Store Cue 0.1 /m")
        Cmd("Assign Appearance \"Trans\" At Cue 0.1")
        Cmd("Store Cue 500 \"Transition\"")
        Cmd("Set Cue 500 Property \"Command\" \"Macro 'Trans'\"")

        -- Optional template copies
     --   Cmd(string.format("Copy Page 1.291 Thru 1.298 At Page %d.291", currentPage))
    --    Cmd(string.format("Copy Page 1.191 Thru 1.198 At Page %d.191", currentPage))

        pageOffset = pageOffset + 1
      else
        ErrPrintf("[TaterPageBuilder][Warning]: Macro slot %d is empty or invalid.", i)
      end
    end

    Printf("[TaterPageBuilder]: Page build complete.")
  end

  local function mainMenu()
    local names = getMacroNames()
    local nameList = (#names > 0) and table.concat(names, "\n") or "No macros found in range."

    local msg = string.format(
      "Macro Range: %d to %d\nStart Page: %d\n\nMacros:\n%s",
      TaterMacroStart, TaterMacroEnd, TaterPageStart, nameList
    )

    local choice = MessageBox({
      title = "Tater Page Builder",
      message = msg,
      commands = {
        { value = 1, name = "Set Macro Range" },
        { value = 2, name = "Set Start Page" },
        { value = 3, name = "Build Pages" },
        { value = 4, name = "Cancel" }
      }
    })

    if choice.result == 1 then
      setMacroRange()
      mainMenu()
    elseif choice.result == 2 then
      setStartPage()
      mainMenu()
    elseif choice.result == 3 then
      buildPages()
    else
      Printf("[TaterPageBuilder]: Cancelled.")
    end
  end

  mainMenu()
end
