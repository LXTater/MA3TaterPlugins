        -- StabberPro
        -- - Assumes a single exact group match; uses the first if multiple.
        -- - Preset detection uses the first selected subfixture's Programmer phasers.
        -- - Z dimension not handled.
        -- - Temporary sequence is created but not deleted; user can manage it.
        -- 0.1.3 : Cleaning up redundent, debug, and unused bugfix code
        -- Absolutely no UI in this version. In order to make this work, make (1) group selection, one or more preset selections, and then run the plugin.
        -- do not use this if u don't what ur doing lol, this is such an early version it will most likely break things if u aren't careful.
        -- Author: LXTater
        -- Website: www.lxtater.com
        -- Github: https://github.com/LXTater
        -- https://lxtater.odoo.com/odoo/project/1/tasks
        -- Version: 0.1.3
        -- Date: September 11, 2025

        return function()
        -- Utility: Checks if a specific bit is set in a value.
        -- @param val number The value to check.
        -- @param bitNum number The bit position (0-based).
        -- @return boolean True if the bit is set.
        -- This is so that we can accurately determine what preset is active.

        local function stabberBitCheck(val, bitNum)
            return (((val or 0) & (0x01 << bitNum)) >> bitNum) == 1
        end

        -- Subfixture handling
        -- Collects the list of selected subfixture indices using SelectionFirst/Next.
        -- @return table List of selected subfixture indices.
        local function stabberGetSelectedSFList()
            local stabberList = {}
            local stabberIdx = SelectionFirst()
            while stabberIdx do
            table.insert(stabberList, stabberIdx)
            stabberIdx = SelectionNext(stabberIdx)
            end
            return stabberList
        end

        -- Converts a list to a set for efficient lookups.
        -- @param t table The list to convert.
        -- @return table The set (keys are values from the list).
        local function stabberToSet(t)
            local stabberSet = {}
            for _, v in ipairs(t) do
            stabberSet[v] = true
            end
            return stabberSet
        end

        -- Checks if two lists contain exactly the same elements (order-independent).
        -- @param a table First list.
        -- @param b table Second list.
        -- @return boolean True if sets are equal.
        local function stabberSetsEqual(a, b)
            if #a ~= #b then return false end
            local stabberSetB = stabberToSet(b)
            for _, v in ipairs(a) do
            if not stabberSetB[v] then return false end
            end
            return true
        end

        -- Finds groups whose SelectionData exactly matches the current selection.
        -- This is so that if you have 2 identical groups, with different selections stored, it will only grab the group that you have selected.
        -- @param selectedSF table List of selected subfixture indices.
        -- @return table List of matching groups {index, name}.
        local function stabberFindMatchingGroups(selectedSF)
            local stabberMatches = {}
            local stabberGroups = DataPool().Groups
            if not stabberGroups then return stabberMatches end

            for stabberI = 1, #stabberGroups do
            local stabberGroup = stabberGroups[stabberI]
            if stabberGroup and stabberGroup.SELECTIONDATA then
                local stabberGroupList = {}
                for stabberZ = 1, #stabberGroup.SELECTIONDATA do
                table.insert(stabberGroupList, stabberGroup.SELECTIONDATA[stabberZ].sf_index)
                end
                if stabberSetsEqual(selectedSF, stabberGroupList) then
                table.insert(stabberMatches, { index = stabberGroup.index, name = stabberGroup.name or "", appearance = stabberGroup.Appearance or "No Appearance"}) -- Grabs number, name, and appearance for the matched group
                end
            end
            end
            return stabberMatches
        end

        -- Parses preset pool and index from a handle address string
        -- @param addr string The address string.
        -- @return number|nil Pool index.
        -- @return number|nil Preset index.
        local function stabberParsePresetAddr(addr)
            if not addr then return nil, nil end
            local stabberPool, stabberIdx = addr:match("Preset%s+(%d+)%.(%d+)")
            if stabberPool and stabberIdx then
            return tonumber(stabberPool), tonumber(stabberIdx)
            end
            -- Fallback for partial matches
            stabberPool = addr:match("Preset%s+(%d+)")
            stabberIdx = addr:match("%.(%d+)")
            return tonumber(stabberPool), tonumber(stabberIdx)
        end

        -- Resolves preset details (type/pool name, index, name) from a handle.
        -- @param h handle The preset handle.
        -- @return table Preset info {pool, index, typeName, name, addr}.
        local function stabberGetPresetInfoFromHandle(h)
            local stabberAddr = ToAddr(h) or ""
            local stabberPoolIndex, stabberPresetIndex = stabberParsePresetAddr(stabberAddr)
            local stabberPoolName = ("Pool %s"):format(tostring(stabberPoolIndex or "?"))
            local stabberPresetName = h and (h.name or "") or ""

            -- Fetch from PresetPools
            local stabberPresetPools = DataPool().PresetPools
            if stabberPresetPools and stabberPoolIndex and stabberPresetPools[stabberPoolIndex] then
            stabberPoolName = stabberPresetPools[stabberPoolIndex].name or stabberPoolName
            local stabberPresetItem = stabberPresetPools[stabberPoolIndex][stabberPresetIndex]
            if stabberPresetItem and stabberPresetItem.name then
                stabberPresetName = stabberPresetItem.name
            end
            end

            return {
            pool = stabberPoolIndex,
            index = stabberPresetIndex,
            typeName = stabberPoolName,
            name = stabberPresetName,
            addr = stabberAddr
            }
        end

        -- Collects unique presets referenced in the Programmer
        -- Uses the first selected subfixture for attribute scanning.
        -- @param selectedSF table List of selected subfixture indices.
        -- @return table List of unique preset info tables.
        local function stabberCollectActivePresets(selectedSF)
            local stabberFirstSF = selectedSF[1]
            if not stabberFirstSF then return {} end

            local stabberAttributes = ShowData().LivePatch.AttributeDefinitions.Attributes -- Fixture attributes
            local stabberUniques = {}
            local stabberSeen = {}

            for stabberI = 1, #stabberAttributes do
            local stabberAttrName = stabberAttributes[stabberI].NAME
            local stabberAttrIdx = GetAttributeIndex(stabberAttrName)
            local stabberUIChan = GetUIChannelIndex(stabberFirstSF, stabberAttrIdx)
            local stabberPhaser = stabberUIChan and GetProgPhaser(stabberUIChan, false) or nil

            if stabberPhaser then
                local stabberMask = stabberPhaser.mask_active_phaser or 0
                if stabberPhaser.abs_preset and stabberBitCheck(stabberMask, 0) then
                local stabberKey = HandleToStr(stabberPhaser.abs_preset)
                if not stabberSeen[stabberKey] then
                    stabberSeen[stabberKey] = true
                    table.insert(stabberUniques, stabberGetPresetInfoFromHandle(stabberPhaser.abs_preset))
                end
                end
                if stabberPhaser.rel_preset and stabberBitCheck(stabberMask, 1) then
                local stabberKey = HandleToStr(stabberPhaser.rel_preset)
                if not stabberSeen[stabberKey] then
                    stabberSeen[stabberKey] = true
                    table.insert(stabberUniques, stabberGetPresetInfoFromHandle(stabberPhaser.rel_preset))
                end
                end
            end
            end

            return stabberUniques
        end

        -- Extracts MAtricks information from the Selection object.

        -- @return table MAtricks info {active, source, addr}.
        local function stabberGetMAtricksInfo()
            local stabberSelObj = Selection()
            local stabberInfo = { active = false, source = nil, addr = nil }

            if stabberSelObj then
            -- Check for active state (handle casing variations)
            stabberInfo.active = (stabberSelObj.ACTIVE == true) or (stabberSelObj.Active == true) or false
            -- Get initial MAtricks (handle casing)
            local stabberInit = stabberSelObj.INITIALMATRICKS or stabberSelObj.InitialMAtricks
            if stabberInit then
                stabberInfo.addr = ToAddr(stabberInit)
                if stabberInfo.addr and stabberInfo.addr:match("^Preset") then
                stabberInfo.source = "Preset"
                else
                stabberInfo.source = "Pool"
                end
            end
            end
            return stabberInfo
        end

        -- Creates a helper MAtricks pool item from the current programmer MAtricks.
        -- Optionally searches for an existing pool item match.
        -- This section is going to get cleaned up/removed. Borrowed from an old plugin, not sure if most of this stuff is needed.
        -- @param poolItem boolean True to search for existing pool item.
        -- @return number|nil Helper index if created.
        -- @return number|string|nil Existing pool index or preset address if found.
        local function stabberRecipeMAtricksProg(poolItem)
            Echo("Start Function stabberRecipeMAtricksProg")
            local stabberMAtricksCount = DataPool().MAtricks:Children()
            local stabberMAtricks = DataPool().MAtricks
            local stabberLastMAtricks = #stabberMAtricksCount
            local stabberHelperMAtricksIndex
            if stabberLastMAtricks == 0 then
            stabberHelperMAtricksIndex = 9000
            else
            stabberHelperMAtricksIndex = stabberMAtricksCount[stabberLastMAtricks].index + 1
            if stabberHelperMAtricksIndex < 800 then stabberHelperMAtricksIndex = stabberHelperMAtricksIndex + 9000 end
            end
            local stabberHelperMAtricksName = "HelperMAtricksStabber"
            local stabberMAtricksPreset = nil

            Cmd("Store Matricks " .. "\"" .. stabberHelperMAtricksName .. "\"")
            Cmd("Reset Selection MAtricks")

            local stabberReferenceMAtricks = stabberMAtricks[stabberHelperMAtricksIndex]

            if poolItem then
            for stabberI = 1, #stabberMAtricks - 1 do
                local stabberCurrentMAtricks = stabberMAtricks[stabberI]
                if stabberReferenceMAtricks:Compare(stabberCurrentMAtricks) and (stabberCurrentMAtricks.index) ~= stabberHelperMAtricksIndex then
                stabberMAtricksPreset = stabberCurrentMAtricks.index
                stabberHelperMAtricksIndex = nil
                Echo("Found MAtricks " .. stabberCurrentMAtricks.index)
                break
                end
            end
            if stabberMAtricksPreset == nil then
                stabberMAtricksPreset = ToAddr(Selection().InitialMAtricks)
                if stabberMAtricksPreset ~= nil then
                stabberHelperMAtricksIndex = nil
                Echo("Found MAtricks in " .. stabberMAtricksPreset)
                end
            end
            else
            Echo("MAtricks Helper Index " .. stabberHelperMAtricksIndex)
            end

            Echo("End Function stabberRecipeMAtricksProg")
            return stabberHelperMAtricksIndex, stabberMAtricksPreset
        end

        -- Main Execution: Print the Programmer inspection readout and create temporary sequence.
        Printf("[StabberPro]: *** Programmer Information ***")

        local stabberSelectedSF = stabberGetSelectedSFList()
        local stabberSelCount = #stabberSelectedSF
        Printf("[StabberPro]: Selection Amount: %d", stabberSelCount)
        if stabberSelCount == 0 then
            Printf("[StabberPro]: No fixtures selected. (Nothing in selection grid)")
            Printf("[StabberPro]:*** End ***")
            return
        end

        -- Matching Groups
        local stabberMatches = stabberFindMatchingGroups(stabberSelectedSF)
        if #stabberMatches == 0 then
            Printf("[StabberPro]: Group: (no exact group match)")
            Printf("[StabberPro]:*** End ***")
            return
        else
            for _, stabberG in ipairs(stabberMatches) do
            Printf("[StabberPro]: Group %s \"%s\"", tostring(stabberG.index or "?"), tostring(stabberG.name or ""))
            Printf("[StabberPro]: Group Appearance: %s", tostring(stabberG.appearance or "No Appearance"))
            end
        end
        -- Assume first matching group for sequence creation
        local stabberGroupIndex = stabberMatches[1].index
        local stabberGroupName = stabberMatches[1].name
        -- Active Presets
        local stabberPresets = stabberCollectActivePresets(stabberSelectedSF)
        if #stabberPresets == 0 then
            Printf("[StabberPro]: Presets: none referenced by Programmer (values may be raw)")
            Printf("[StabberPro]:*** End ***")
            return
        else
            for _, stabberP in ipairs(stabberPresets) do
            local stabberPoolStr = (stabberP.pool and stabberP.index) and (tostring(stabberP.pool) .. "." .. tostring(stabberP.index)) or "?.?"
            Printf("[StabberPro]: Preset Type=\"%s\" Number=%s Name=\"%s\"", tostring(stabberP.typeName or ""), stabberPoolStr, tostring(stabberP.name or ""))
            end
        end

        -- MAtricks Info
        local stabberMI = stabberGetMAtricksInfo()
        Printf("[StabberPro]: MAtricks Active: %s", tostring(stabberMI.active))
        if stabberMI.addr then
            Printf("[StabberPro]: MAtricks Source: %s (%s)", tostring(stabberMI.source or "Unknown"), stabberMI.addr)
        end

        -- Fetch World (if any) - simplified, set to nil as not implemented
        local stabberWorld = nil  -- Replace with actual world detection if needed

        -- Get MAtricks division properties if active
        local stabberHelperIndex = nil
        local stabberXGroup = 0
        local stabberXBlock = 0
        local stabberXWings = 0
        local stabberYGroup = 0
        local stabberYBlock = 0
        local stabberYWings = 0
        if stabberMI.active then
            local stabberPoolItem = (stabberMI.source == "Pool")
            stabberHelperIndex, _ = stabberRecipeMAtricksProg(stabberPoolItem)
            local stabberMAtricksObj
            if stabberHelperIndex then
            stabberMAtricksObj = DataPool().MAtricks[stabberHelperIndex]
            end
            if stabberMAtricksObj then
            stabberXGroup = tonumber(stabberMAtricksObj.XGroup) or 0
            stabberXBlock = tonumber(stabberMAtricksObj.XBlock) or 0
            stabberXWings = tonumber(stabberMAtricksObj.XWings) or 0
            stabberYGroup = tonumber(stabberMAtricksObj.YGroup) or 0
            stabberYBlock = tonumber(stabberMAtricksObj.YBlock) or 0
            stabberYWings = tonumber(stabberMAtricksObj.YWings) or 0
            end
        end

        -- Calculate selection grid dimensions by iterating selection
        local stabberMinX, stabberMaxX = math.huge, -math.huge
        local stabberMinY, stabberMaxY = math.huge, -math.huge
        local stabberIdx, stabberGX, stabberGY, stabberGZ = SelectionFirst(true)
        while stabberIdx do
            local gxNum = tonumber(stabberGX or 0) or 0
            local gyNum = tonumber(stabberGY or 0) or 0
            stabberMinX = math.min(stabberMinX, gxNum)
            stabberMaxX = math.max(stabberMaxX, gxNum)
            stabberMinY = math.min(stabberMinY, gyNum)
            stabberMaxY = math.max(stabberMaxY, gyNum)
            stabberIdx, stabberGX, stabberGY, stabberGZ = SelectionNext(stabberIdx, true)
        end

        local stabberXDiv = (stabberMinX ~= math.huge) and (stabberMaxX - stabberMinX + 1) or 0
        local stabberYDiv = (stabberMinY ~= math.huge) and (stabberMaxY - stabberMinY + 1) or 0

        -- If not active and appears 1D, treat as linear with X from 1 to selCount
        if not stabberMI.active then
            if stabberXDiv <= 1 and stabberYDiv <= 1 and stabberSelCount > 1 then
            stabberMinX = 0  -- Set to 0 so relative starts at 1
            stabberMaxX = stabberSelCount - 1
            stabberXDiv = stabberSelCount
            end
        end

        -- Calculate total Stabs
        local stabberSlices = stabberXDiv * stabberYDiv
        if stabberSlices == 0 then
            Printf("[StabberPro]: No valid grid dimensions detected.")
            Printf("[StabberPro]:*** End ***")
            return
        end

         --Prevents storing the programmer information into Cue 1.
        Cmd("ClearAll") 
        -- Create temporary sequence, in the future we we will create the sequence that the user defines in the UI.
        Cmd("Store Sequence \"StabberRecipeTemp\" /o")

        local stabberCueNum = 1
        for stabberGY = stabberMinY, stabberMaxY do
            for stabberGX = stabberMinX, stabberMaxX do
            local stabberXRel = stabberGX - stabberMinX + 1
            local stabberYRel = stabberGY - stabberMinY + 1
            
            Cmd("Store Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum)
            for stabberP = 1, #stabberPresets do
                local stabberPart = stabberP
                Cmd("Store Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart)
                Cmd("Assign Group " .. stabberGroupIndex .. " at Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart)
                Cmd("Assign Preset " .. stabberPresets[stabberP].pool .. "." .. stabberPresets[stabberP].index .. " at Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart)
                if stabberWorld then
                Cmd("Assign World \"" .. stabberWorld .. "\" at Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart)
                end
                Cmd("Set Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart .. " Property \"X\" " .. stabberXRel)
                if stabberYDiv > 1 then
                Cmd("Set Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart .. " Property \"Y\" " .. stabberYRel)
                end
                if stabberXGroup > 0 then
                Cmd("Set Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart .. " Property \"XGroup\" " .. stabberXGroup)
                end
                if stabberXBlock > 0 then
                Cmd("Set Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart .. " Property \"XBlock\" " .. stabberXBlock)
                end
                if stabberXWings > 0 then
                Cmd("Set Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart .. " Property \"XWings\" " .. stabberXWings)
                end
                if stabberYGroup > 0 then
                Cmd("Set Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart .. " Property \"YGroup\" " .. stabberYGroup)
                end
                if stabberYBlock > 0 then
                Cmd("Set Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart .. " Property \"YBlock\" " .. stabberYBlock)
                end
                if stabberYWings > 0 then
                Cmd("Set Sequence \"StabberRecipeTemp\" Cue " .. stabberCueNum .. " Part 0." .. stabberPart .. " Property \"YWings\" " .. stabberYWings)
                end
            end
            stabberCueNum = stabberCueNum + 1
            end
        end

        -- Cleanup helper MAtricks if created
        if stabberHelperIndex then
            Cmd("Delete Matricks " .. stabberHelperIndex .. " /nc")
        end

        Printf("[StabberPro]: Temporary sequence 'StabberRecipeTemp' created with %d cues.", stabberSlices)
        Printf("[StabberPro]:*** End ***")
        end