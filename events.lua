-- events.lua

local addonName, addon = ...

-- Create the event frame
local eventFrame = CreateFrame("Frame")
addon.eventFrame = eventFrame

-- Table to store event handlers
addon.eventHandlers = {
    PLAYER_ENTERING_WORLD = function()
        addon.DebugPrint("PLAYER_ENTERING_WORLD event fired")
        addon:UpdateUI()  -- Assuming you have a general UI update function
    end,
    ADDON_LOADED = function(loadedAddonName)
        if loadedAddonName == addonName then
            addon.OnAddonLoaded()
        end
    end,
    -- Other event handlers...
}

-- Function to register event handlers
function addon:RegisterEventHandlers()
    for event, handler in pairs(self.eventHandlers) do
        self.eventFrame:RegisterEvent(event)
    end
    self.eventFrame:SetScript("OnEvent", function(_, event, ...)
        local handler = addon.eventHandlers[event]
        if handler then
            handler(addon, event, ...)
        end
    end)
end

-- Event handler for ADDON_LOADED
addon.eventHandlers.ADDON_LOADED = function(loadedAddonName)
    if loadedAddonName == addonName then
        addon.OnAddonLoaded()
    end
end

-- Function to set up WorldMapFrame hook
function addon.SetupWorldMapHook()
    if not WorldMapFrame then
        addon.DebugPrint("WorldMapFrame not found. Hooking failed.")
        return
    end
    if not WorldMapFrame.OnMapChanged then
        addon.DebugPrint("WorldMapFrame.OnMapChanged not found. Using alternative method.")
        WorldMapFrame:HookScript("OnShow", function()
            addon.UpdateExplorationButtonText()
        end)
    else
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
            addon.UpdateExplorationButtonText()
        end)
    end
end

-- Function to handle addon loading
function addon.OnAddonLoaded()
    -- Initialize saved variables
    ExplorationCoordsDB = ExplorationCoordsDB or {}
    ExplorationCoordsDB.discoveredAreas = ExplorationCoordsDB.discoveredAreas or {}
    ExplorationCoordsDB.ignoredAreas = ExplorationCoordsDB.ignoredAreas or {}

    -- Other initialization code...
end

-- Event handler for PLAYER_ENTERING_WORLD
addon.eventHandlers.PLAYER_ENTERING_WORLD = function(self, event, isInitialLogin, isReloadingUi)
    addon.DebugPrint("PLAYER_ENTERING_WORLD: Player entered world")
    if isInitialLogin or isReloadingUi then
        addon.UpdatePlayerInfo()
        addon.CheckChromieTimeStatus()  -- New function to check Chromie Time status
    end
    addon.UpdateWaypoints()
end

-- Event handler for ZONE_CHANGED_NEW_AREA
addon.eventHandlers.ZONE_CHANGED_NEW_AREA = function(self, event)
    addon.DebugPrint("ZONE_CHANGED_NEW_AREA: Player entered new zone")
    addon.UpdatePlayerInfo()
    addon.UpdateWaypoints()
    if addon.LevelingMode then
        addon.UpdateLevelingSuggestions()
    end
end

-- Event handler for PLAYER_LEVEL_UP
addon.eventHandlers.PLAYER_LEVEL_UP = function(self, event, level, healthDelta, powerDelta, strengthDelta, staminaDelta, intellectDelta, spiritDelta)
    addon.DebugPrint("PLAYER_LEVEL_UP: Player leveled up to " .. level)
    addon.UpdatePlayerInfo()
    if addon.LevelingMode then
        addon.UpdateLevelingSuggestions()
    end
end

-- Event handler for ACHIEVEMENT_EARNED
addon.eventHandlers.ACHIEVEMENT_EARNED = function(self, event, achievementID)
    addon.DebugPrint("ACHIEVEMENT_EARNED: Achievement " .. achievementID .. " earned")
    addon.ProcessAchievement(achievementID)
end

-- Event handler for CRITERIA_COMPLETE
addon.eventHandlers.CRITERIA_COMPLETE = function(self, event, criteriaID)
    addon.DebugPrint("CRITERIA_COMPLETE: Criteria " .. criteriaID .. " completed")
    addon.ProcessCriteria(criteriaID)
end

-- Event handler for QUEST_TURNED_IN
addon.eventHandlers.QUEST_TURNED_IN = function(self, event, questID, xpReward, moneyReward)
    addon.DebugPrint("QUEST_TURNED_IN: Quest " .. questID .. " turned in")
    addon.ProcessQuestTurnIn(questID, xpReward)
end

-- Event handler for PLAYER_XP_UPDATE
addon.eventHandlers.PLAYER_XP_UPDATE = function(self, event)
    addon.DebugPrint("PLAYER_XP_UPDATE: Player XP updated")
    addon.UpdateXPEstimation()
end

-- Function to initialize the addon
function addon.InitializeAddon()
    addon.LoadConfig()
    addon.PopulateZoneIds()
    addon.InitializeWaypointSystem()
    addon.CreateMapButtons()
    addon.UpdatePlayerInfo()
    addon.DebugPrint("Addon initialization complete")
end

-- Function to update player information
function addon.UpdatePlayerInfo()
    local playerLevel = UnitLevel("player")
    local playerXP = UnitXP("player")
    local playerMaxXP = UnitXPMax("player")
    local currentZone = GetZoneText()
    
    addon.DebugPrint(string.format("Player Info: Level %d, XP: %d/%d, Zone: %s", 
                                   playerLevel, playerXP, playerMaxXP, currentZone))
end

-- Function to process achievements
function addon.ProcessAchievement(achievementID)
    local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(achievementID)
    
    if completed and wasEarnedByMe then
        if string.find(name, "Explore") then
            addon.DebugPrint("Exploration achievement completed: " .. name)
            addon.UpdateExploredAreas(name)
        end
    end
end

-- Function to process criteria completion
function addon.ProcessCriteria(criteriaID)
    -- Implement logic to handle criteria completion
    -- This might involve updating discovered areas or other addon-specific logic
end

-- Function to process quest turn-ins
function addon.ProcessQuestTurnIn(questID, xpReward)
    -- Implement logic to handle quest turn-ins
    -- This might involve updating XP estimations or other addon-specific logic
end

-- Function to update XP estimation
function addon.UpdateXPEstimation()
    local estimatedXP = addon.EstimateXPTo70()
    addon.DebugPrint("Updated XP estimation to level 70: " .. estimatedXP)
    -- Update UI or other components with the new XP estimation
end

-- Function to update Chromie Time options
function addon.UpdateChromieTimeOptions()
    addon.GetChromieTimeOptions()
    -- Update UI or other components with the new Chromie Time options
end

-- Function to update Chromie Time selection
function addon.UpdateChromieTimeSelection(expansionInfo)
    if expansionInfo then
        -- Handle active Chromie Time
        addon.DebugPrint("Updating addon for Chromie Time expansion: " .. (expansionInfo.name or "Unknown"))
        -- Update relevant addon functionality here
    else
        -- Handle inactive Chromie Time
        addon.DebugPrint("Updating addon for standard (non-Chromie Time) mode")
        -- Update relevant addon functionality here
    end
end

-- Function to update leveling suggestions
function addon.UpdateLevelingSuggestions()
    local suggestedZone = addon.GetSuggestedLevelingZone()
    addon.DebugPrint("Updated leveling suggestion: " .. (suggestedZone or "No suggestion"))
    -- Update UI or other components with the new leveling suggestion
end

-- New function to check Chromie Time status
function addon.CheckChromieTimeStatus()
    if not C_ChromieTime then
        addon.DebugPrint("C_ChromieTime API is not available")
        addon.UpdateChromieTimeSelection(nil)
        return
    end

    local isChromieTimeActive = C_ChromieTime.IsChromieTimeActive and C_ChromieTime.IsChromieTimeActive() or false
    addon.DebugPrint("Chromie Time active: " .. tostring(isChromieTimeActive))

    if isChromieTimeActive then
        local expansions = C_ChromieTime.GetChromieTimeExpansionOptions and C_ChromieTime.GetChromieTimeExpansionOptions() or {}
        if expansions and #expansions > 0 then
            for _, expansion in ipairs(expansions) do
                if expansion.selected then
                    addon.DebugPrint("Selected Chromie Time expansion: " .. expansion.name)
                    addon.UpdateChromieTimeSelection(expansion)
                    return
                end
            end
        end
        addon.DebugPrint("No Chromie Time expansion selected")
        addon.UpdateChromieTimeSelection(nil)
    else
        addon.DebugPrint("Chromie Time is not active")
        addon.UpdateChromieTimeSelection(nil)
    end
end

-- Create a frame to handle events
local function OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        addon:UpdateUI()  -- Assuming you have a general UI update function
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
eventFrame:SetScript("OnEvent", OnEvent)

-- Register all event handlers
addon:RegisterEventHandlers()