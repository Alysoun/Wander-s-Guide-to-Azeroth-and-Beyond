-- leveling.lua

local addonName, addon = ...

addon.LevelingMode = false
addon.CurrentLevelingZone = nil

function addon.StartLevelingProcess()
    addon.LevelingMode = true
    addon.DebugPrint("Starting leveling process")
    addon.UpdateLevelingSuggestions()
    addon.ShowLevelingFrame()
end

function addon.StopLevelingProcess()
    addon.LevelingMode = false
    addon.CurrentLevelingZone = nil
    addon.DebugPrint("Stopping leveling process")
    addon.ClearLevelingWaypoints()
    addon.HideLevelingFrame()
end

function addon.UpdateLevelingSuggestions()
    local playerLevel = UnitLevel("player")
    local suggestions = {}

    addon.DebugPrint("Updating leveling suggestions for player level: " .. playerLevel)

    for _, zoneName in ipairs(addon.SuggestedZones) do
        local minLevel, maxLevel = addon.GetZoneLevelRange(zoneName)
        if minLevel and maxLevel then
            addon.DebugPrint("Zone: " .. zoneName .. ", Level Range: " .. minLevel .. "-" .. maxLevel)
            if playerLevel >= minLevel and playerLevel <= maxLevel then
                table.insert(suggestions, {
                    name = zoneName,
                    minLevel = minLevel,
                    maxLevel = maxLevel
                })
            end
        else
            addon.DebugPrint("Could not get level range for zone: " .. zoneName)
        end
    end

    -- Sort suggestions by min level
    table.sort(suggestions, function(a, b) return a.minLevel < b.minLevel end)

    -- Update the UI with the new suggestions
    addon.UpdateLevelingSuggestionsUI(suggestions)

    -- If we're in leveling mode, update the current suggestion
    if addon.LevelingMode then
        addon.UpdateCurrentLevelingSuggestion(suggestions)
    end

    addon.DebugPrint("Found " .. #suggestions .. " suitable zones for leveling")
end

function addon.UpdateLevelingSuggestionsUI(suggestions)
    -- Clear existing suggestions
    addon.LevelingFrame.SuggestionsContainer:ReleaseChildren()

    for i, suggestion in ipairs(suggestions) do
        local button = AceGUI:Create("InteractiveLabel")
        button:SetText(suggestion.name .. " (" .. suggestion.minLevel .. "-" .. suggestion.maxLevel .. ")")
        button:SetFullWidth(true)
        button:SetCallback("OnClick", function()
            addon.SelectLevelingZone(suggestion.name)
        end)
        addon.LevelingFrame.SuggestionsContainer:AddChild(button)
    end
end

function addon.UpdateCurrentLevelingSuggestion(suggestions)
    if #suggestions > 0 then
        local currentSuggestion = suggestions[1]
        addon.CurrentLevelingZone = currentSuggestion.name
        addon.LevelingFrame.CurrentZoneLabel:SetText("Current Zone: " .. currentSuggestion.name)
        addon.UpdateWaypointsForZone(currentSuggestion.name)
    else
        addon.CurrentLevelingZone = nil
        addon.LevelingFrame.CurrentZoneLabel:SetText("No suitable zones found")
        addon.ClearLevelingWaypoints()
    end
end

function addon.SelectLevelingZone(zoneName)
    addon.CurrentLevelingZone = zoneName
    addon.DebugPrint("Selected leveling zone: " .. zoneName)
    addon.LevelingFrame.CurrentZoneLabel:SetText("Current Zone: " .. zoneName)
    addon.UpdateWaypointsForZone(zoneName)
end

function addon.UpdateWaypointsForZone(zoneName)
    addon.ClearLevelingWaypoints()
    local waypoints = addon.GetWaypointsForZone(zoneName)
    for _, waypoint in ipairs(waypoints) do
        addon.AddLevelingWaypoint(waypoint)
    end
    addon.DebugPrint("Updated waypoints for zone: " .. zoneName)
end

function addon.GetWaypointsForZone(zoneName)
    -- This function should return a list of waypoints for the given zone
    -- You'll need to implement this based on your waypoint data structure
    -- For example:
    return addon.POIData[zoneName] or {}
end

function addon.AddLevelingWaypoint(waypoint)
    -- Add the waypoint to your map/minimap
    -- You'll need to implement this based on how you're displaying waypoints
    -- For example, if using TomTom:
    if TomTom then
        TomTom:AddWaypoint(waypoint.mapID, waypoint.x, waypoint.y, {
            title = waypoint.title,
            persistent = false,
            minimap = true,
            world = true
        })
    end
end

function addon.ClearLevelingWaypoints()
    -- Clear all leveling waypoints
    -- You'll need to implement this based on how you're managing waypoints
    -- For example, if using TomTom:
    if TomTom then
        TomTom:ClearWaypoints()
    end
end

function addon.ShowLevelingFrame()
    if not addon.LevelingFrame then
        addon.CreateLevelingFrame()
    end
    addon.LevelingFrame:Show()
end

function addon.HideLevelingFrame()
    if addon.LevelingFrame then
        addon.LevelingFrame:Hide()
    end
end

function addon.CreateLevelingFrame()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Leveling Guide")
    frame:SetLayout("Flow")
    frame:SetWidth(300)
    frame:SetHeight(400)

    local currentZoneLabel = AceGUI:Create("Label")
    currentZoneLabel:SetFullWidth(true)
    frame:AddChild(currentZoneLabel)

    local suggestionsContainer = AceGUI:Create("SimpleGroup")
    suggestionsContainer:SetFullWidth(true)
    suggestionsContainer:SetLayout("List")
    frame:AddChild(suggestionsContainer)

    local stopButton = AceGUI:Create("Button")
    stopButton:SetText("Stop Leveling")
    stopButton:SetFullWidth(true)
    stopButton:SetCallback("OnClick", function()
        addon.StopLevelingProcess()
    end)
    frame:AddChild(stopButton)

    addon.LevelingFrame = frame
    addon.LevelingFrame.CurrentZoneLabel = currentZoneLabel
    addon.LevelingFrame.SuggestionsContainer = suggestionsContainer
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LEVEL_UP" then
        if addon.LevelingMode then
            addon.UpdateLevelingSuggestions()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        if addon.LevelingMode then
            addon.UpdateLevelingSuggestions()
        end
    end
end)