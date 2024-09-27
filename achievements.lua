-- achievements.lua

local addonName, addon = ...

-- Table to store exploration achievements
addon.ExplorationAchievements = {}

-- Function to initialize exploration achievements
function addon.InitializeExplorationAchievements()
    addon.QueryExplorationAchievements()
    addon.DebugPrint("Exploration achievements initialized")
end

-- Function to query exploration achievements and store completed POIs
function addon.QueryExplorationAchievements()
    local explorationCategoryID = 97 -- Exploration Category

    -- Recursive function to process exploration categories and subcategories
    local function ProcessCategory(categoryID)
        local numAchievements = GetCategoryNumAchievements(categoryID)
        for i = 1, numAchievements do
            local achievementID, name, _, completed = GetAchievementInfo(categoryID, i)
            if achievementID then
                if name:find("Explore") then  -- Filter for exploration achievements by name
                    addon.ExplorationAchievements[achievementID] = {
                        name = name,
                        completed = completed,
                        criteria = {}
                    }
                    if completed then
                        ExplorationCoordsDB.completedAchievements[achievementID] = true
                        addon.DebugPrint(string.format("Exploration achievement %d (%s) marked as completed.", achievementID, name))
                    else
                        addon.QueryPartialExplorationAchievements(achievementID)
                    end
                end
            end
        end
    end

    ProcessCategory(explorationCategoryID)
end

-- Function to query partial exploration achievements and mark discovered POIs
function addon.QueryPartialExplorationAchievements(achievementID)
    local numCriteria = GetAchievementNumCriteria(achievementID)

    for i = 1, numCriteria do
        local criteriaString, _, criteriaCompleted, _, _, _, _, assetID = GetAchievementCriteriaInfo(achievementID, i)

        addon.ExplorationAchievements[achievementID].criteria[i] = {
            name = criteriaString,
            completed = criteriaCompleted,
            assetID = assetID
        }

        if criteriaCompleted and assetID then
            ExplorationCoordsDB.discoveredAreas[criteriaString] = true
            addon.DebugPrint(string.format("POI '%s' from achievement %d marked as discovered.", criteriaString, achievementID))
        end
    end
end

-- Function to check if an exploration achievement is complete
function addon.IsExplorationAchievementComplete(achievementID)
    if addon.ExplorationAchievements[achievementID] then
        return addon.ExplorationAchievements[achievementID].completed
    end
    return false
end

-- Function to check if a specific criteria of an achievement is complete
function addon.IsAchievementCriteriaComplete(achievementID, criteriaIndex)
    if addon.ExplorationAchievements[achievementID] and addon.ExplorationAchievements[achievementID].criteria[criteriaIndex] then
        return addon.ExplorationAchievements[achievementID].criteria[criteriaIndex].completed
    end
    return false
end

-- Function to update achievement progress
function addon.UpdateAchievementProgress(achievementID)
    if not addon.ExplorationAchievements[achievementID] then return end

    local _, _, _, completed = GetAchievementInfo(achievementID)
    addon.ExplorationAchievements[achievementID].completed = completed

    if completed then
        ExplorationCoordsDB.completedAchievements[achievementID] = true
    else
        addon.QueryPartialExplorationAchievements(achievementID)
    end

    addon.DebugPrint("Updated achievement progress for " .. addon.ExplorationAchievements[achievementID].name)
end

-- Function to get incomplete exploration achievements for a zone
function addon.GetIncompleteAchievementsForZone(zoneName)
    local incompleteAchievements = {}
    for id, achievement in pairs(addon.ExplorationAchievements) do
        if not achievement.completed and string.find(achievement.name, zoneName) then
            table.insert(incompleteAchievements, id)
        end
    end
    return incompleteAchievements
end

-- Function to get incomplete criteria for an achievement
function addon.GetIncompleteCriteriaForAchievement(achievementID)
    local incompleteCriteria = {}
    if addon.ExplorationAchievements[achievementID] then
        for i, criteria in ipairs(addon.ExplorationAchievements[achievementID].criteria) do
            if not criteria.completed then
                table.insert(incompleteCriteria, i)
            end
        end
    end
    return incompleteCriteria
end

-- Function to handle achievement earned event
function addon.HandleAchievementEarned(achievementID)
    if addon.ExplorationAchievements[achievementID] then
        addon.ExplorationAchievements[achievementID].completed = true
        ExplorationCoordsDB.completedAchievements[achievementID] = true
        addon.DebugPrint("Achievement earned: " .. addon.ExplorationAchievements[achievementID].name)
        addon.UpdateAchievementDisplay()
    end
end

-- Function to handle criteria update event
function addon.HandleCriteriaUpdate(achievementID, criteriaID)
    if addon.ExplorationAchievements[achievementID] and addon.ExplorationAchievements[achievementID].criteria[criteriaID] then
        local criteriaString, _, criteriaCompleted, _, _, _, _, assetID = GetAchievementCriteriaInfo(achievementID, criteriaID)
        addon.ExplorationAchievements[achievementID].criteria[criteriaID].completed = criteriaCompleted
        if criteriaCompleted and assetID then
            ExplorationCoordsDB.discoveredAreas[criteriaString] = true
        end
        addon.DebugPrint("Criteria updated for " .. addon.ExplorationAchievements[achievementID].name)
        addon.UpdateAchievementDisplay()
    end
end

-- Function to create achievement tooltip
function addon.CreateAchievementTooltip(achievementID)
    if not addon.ExplorationAchievements[achievementID] then return end

    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:SetText(addon.ExplorationAchievements[achievementID].name, 1, 1, 1)
    GameTooltip:AddLine(addon.ExplorationAchievements[achievementID].description, nil, nil, nil, true)
    GameTooltip:AddLine(" ")

    for i, criteria in ipairs(addon.ExplorationAchievements[achievementID].criteria) do
        local color = criteria.completed and "|cFF00FF00" or "|cFFFF0000"
        GameTooltip:AddLine(color .. criteria.name .. "|r")
    end

    GameTooltip:Show()
end

-- Function to update achievement display
function addon.UpdateAchievementDisplay()
    -- This function should update any UI elements that display achievement information
    -- For example, updating a list of achievements in the addon's main frame
    addon.DebugPrint("Updating achievement display")
    -- Implement the UI update logic here
    
    -- Example: Update a scrolling achievement list
    if addon.achievementList then
        addon.achievementList:Clear()
        for id, achievement in pairs(addon.ExplorationAchievements) do
            local color = achievement.completed and "|cFF00FF00" or "|cFFFFFFFF"
            local text = string.format("%s%s|r", color, achievement.name)
            addon.achievementList:AddItem(text, id)
        end
    end
end

-- Function to initialize achievement system
function addon.InitializeAchievementSystem()
    addon.InitializeExplorationAchievements()
    addon.UpdateAchievementDisplay()

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ACHIEVEMENT_EARNED")
    frame:RegisterEvent("CRITERIA_UPDATE")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "ACHIEVEMENT_EARNED" then
            local achievementID = ...
            addon.HandleAchievementEarned(achievementID)
        elseif event == "CRITERIA_UPDATE" then
            for id, _ in pairs(addon.ExplorationAchievements) do
                addon.UpdateAchievementProgress(id)
            end
        end
    end)

    addon.DebugPrint("Achievement system initialized")
end

-- Function to get achievement progress as a percentage
function addon.GetAchievementProgress(achievementID)
    if not addon.ExplorationAchievements[achievementID] then return 0 end

    local totalCriteria = #addon.ExplorationAchievements[achievementID].criteria
    local completedCriteria = 0

    for _, criteria in ipairs(addon.ExplorationAchievements[achievementID].criteria) do
        if criteria.completed then
            completedCriteria = completedCriteria + 1
        end
    end

    return (completedCriteria / totalCriteria) * 100
end

-- Function to get all exploration achievements for a specific zone
function addon.GetZoneExplorationAchievements(zoneName)
    local zoneAchievements = {}
    for id, achievement in pairs(addon.ExplorationAchievements) do
        if string.find(achievement.name, zoneName) then
            table.insert(zoneAchievements, id)
        end
    end
    return zoneAchievements
end

-- Function to check if all exploration achievements are completed
function addon.AreAllExplorationAchievementsCompleted()
    for _, achievement in pairs(addon.ExplorationAchievements) do
        if not achievement.completed then
            return false
        end
    end
    return true
end

-- Function to get the next incomplete exploration achievement
function addon.GetNextIncompleteExplorationAchievement()
    for id, achievement in pairs(addon.ExplorationAchievements) do
        if not achievement.completed then
            return id
        end
    end
    return nil
end

-- Function to reset achievement progress (for testing purposes)
function addon.ResetAchievementProgress()
    for id, _ in pairs(addon.ExplorationAchievements) do
        addon.ExplorationAchievements[id].completed = false
        for _, criteria in ipairs(addon.ExplorationAchievements[id].criteria) do
            criteria.completed = false
        end
    end
    ExplorationCoordsDB.completedAchievements = {}
    ExplorationCoordsDB.discoveredAreas = {}
    addon.UpdateAchievementDisplay()
    addon.DebugPrint("Achievement progress reset")
end