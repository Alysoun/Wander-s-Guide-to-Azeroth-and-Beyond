-- helpers.lua

local addonName, addon = ...

-- Function to calculate distance between two points
function addon.CalculateDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Function to get the region name for a given zone
function addon.GetRegionNameFromZone(zoneName)
    for region, zones in pairs(CollectCoordDB.exploredCoords) do
        if zones[zoneName] then
            return region
        end
    end
    return nil
end

-- Function to get POIs from a zone
function addon.GetPOIsForZone(zoneName)
    local region = addon.GetRegionNameFromZone(zoneName)
    if region and CollectCoordDB.exploredCoords[region] then
        return CollectCoordDB.exploredCoords[region][zoneName]
    else
        addon.DebugPrint("No POIs found for zone: " .. zoneName)
        return nil
    end
end

-- Function to get the mapID for a zone
function addon.GetMapIDForZone(zoneName)
    return addon.ZoneIds[zoneName]
end

-- Function to calculate the center of a zone based on its POIs
function addon.CalculateZoneCenter(zoneID)
    local totalX, totalY, count = 0, 0, 0

    for zoneName, coords in pairs(CollectCoordDB.exploredCoords) do
        if addon.ZoneIds[zoneName] == zoneID then
            for _, waypoint in pairs(coords) do
                if waypoint.x and waypoint.y then
                    totalX = totalX + waypoint.x
                    totalY = totalY + waypoint.y
                    count = count + 1
                end
            end
        end
    end

    if count > 0 then
        return totalX / count, totalY / count
    else
        return nil, nil
    end
end

-- Function to calculate the distance between two zone centers
function addon.CalculateZoneDistance(currentZoneID, targetZoneID)
    local currentX, currentY = addon.CalculateZoneCenter(currentZoneID)
    local targetX, targetY = addon.CalculateZoneCenter(targetZoneID)

    if currentX and targetX and currentY and targetY then
        local distance = addon.CalculateDistance(currentX, currentY, targetX, targetY)
        return distance
    else
        return math.huge
    end
end

-- Function to get the level range of a zone dynamically
function addon.GetZoneLevelRange(zoneName)
    -- First, try to get the uiMapID from the zone name
    local uiMapID = addon.GetMapIDFromName(zoneName)
    
    if not uiMapID then
        addon.DebugPrint("Could not find map ID for zone: " .. zoneName)
        return nil, nil
    end
    
    -- Now use the numeric uiMapID
    local playerMinLevel, playerMaxLevel = C_Map.GetMapLevels(uiMapID)
    
    if not playerMinLevel or not playerMaxLevel then
        addon.DebugPrint("Could not get level range for zone: " .. zoneName)
        return nil, nil
    end
    
    return playerMinLevel, playerMaxLevel
end

-- Helper function to get map ID from zone name
function addon.GetMapIDFromName(zoneName)
    for id, info in pairs(C_Map.GetMapChildrenInfo(946, Enum.UIMapType.Zone, true)) do
        if info.name == zoneName then
            return id
        end
    end
    return nil
end

-- Function to check if a zone is in the player's level range
function addon.IsZoneInLevelRange(mapID, playerLevel)
    if not mapID or not playerLevel then
        addon.DebugPrint("IsZoneInLevelRange: Invalid mapID or playerLevel")
        return true
    end

    local playerMinLevel, playerMaxLevel = C_Map.GetMapLevels(mapID)
    
    if not playerMinLevel or not playerMaxLevel then
        addon.DebugPrint(string.format("IsZoneInLevelRange: Unable to get level range for mapID %s", mapID))
        return true
    end
    
    return playerLevel >= playerMinLevel and playerLevel <= playerMaxLevel
end

-- Function to check if Chromie Time is needed for a zone
function addon.NeedsChromieTime(zoneName)
    local continent = addon.GetRegionNameFromZone(zoneName)
    local requiredExpansion = addon.continentToChromieExpansion[continent]
    
    if not requiredExpansion then
        return false
    end
    
    local playerLevel = UnitLevel("player")
    if playerLevel >= 50 then
        return false
    end
    
    local currentChromieTime = C_ChromieTime.GetChromieTimeExpansionOption()
    return currentChromieTime ~= requiredExpansion
end

-- Function to get the suggested leveling zone
function addon.GetSuggestedLevelingZone()
    local playerLevel = UnitLevel("player")
    local bestZone = nil
    local maxPOIs = 0

    for continent, zones in pairs(CollectCoordDB.exploredCoords) do
        for zone, pois in pairs(zones) do
            local undiscoveredPOIs = 0
            for poiName, coords in pairs(pois) do
                if not ExplorationCoordsDB.discoveredAreas[poiName] and not ExplorationCoordsDB.ignoredAreas[poiName] then
                    undiscoveredPOIs = undiscoveredPOIs + 1
                end
            end

            if undiscoveredPOIs > maxPOIs and addon.IsZoneInLevelRange(addon.GetMapIDForZone(zone), playerLevel) then
                bestZone = zone
                maxPOIs = undiscoveredPOIs
            end
        end
    end

    return bestZone
end

-- Function to estimate XP to reach level 70
function addon.EstimateXPTo70()
    local playerLevel = UnitLevel("player")
    local currentXP = UnitXP("player")
    local totalXPNeeded = 0

    for level = playerLevel, 69 do
        totalXPNeeded = totalXPNeeded + UnitXPMax("player")
    end

    local remainingXP = totalXPNeeded - currentXP

    if remainingXP <= 0 then
        addon.DebugPrint("EstimateXPTo70: Level 70 already reached or surpassed.")
        return 0
    end

    local totalEstimatedXP = 0

    for expansion, zones in pairs(CollectCoordDB.exploredCoords) do
        for zoneName, coords in pairs(zones) do
            if not ExplorationCoordsDB.ignoredAreas[zoneName] then
                local zoneLevel = addon.GetZoneLevelRange(zoneName)
                for _, coord in ipairs(coords) do
                    if not ExplorationCoordsDB.discoveredAreas[coord.name] then
                        local xp = addon.CalculateXP(playerLevel, zoneLevel.min)
                        totalEstimatedXP = totalEstimatedXP + xp
                    end
                end
            end
        end
    end

    addon.DebugPrint(string.format("EstimateXPTo70: Total estimated XP from undiscovered POIs: %d", totalEstimatedXP))
    return math.min(remainingXP, totalEstimatedXP)
end

-- Function to calculate XP based on player level and area level
function addon.CalculateXP(playerLevel, areaLevel)
    -- This is a simplified XP calculation. You may want to adjust this based on actual game mechanics.
    local basePOIXP = 1000
    local levelDifference = math.abs(playerLevel - areaLevel)
    local xpMultiplier = 1

    if levelDifference > 5 then
        xpMultiplier = math.max(0.1, 1 - (levelDifference - 5) * 0.1)
    end

    return math.floor(basePOIXP * xpMultiplier)
end

-- Function to get the current map name
function addon.GetCurrentMapName()
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local mapInfo = C_Map.GetMapInfo(mapID)
        return mapInfo and mapInfo.name or "Unknown Map"
    end
    return "Unknown Map"
end

-- Function to get POIs for a specific map ID
function addon.GetPOIsForMapID(mapID)
    local pois = {}
    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then return pois end

    local continentName = addon.GetContinentName(mapID)
    local zoneName = mapInfo.name

    if CollectCoordDB and CollectCoordDB.exploredCoords and 
       CollectCoordDB.exploredCoords[continentName] and 
       CollectCoordDB.exploredCoords[continentName][zoneName] then
        for locationName, coords in pairs(CollectCoordDB.exploredCoords[continentName][zoneName]) do
            table.insert(pois, {
                name = locationName,
                mapID = mapID,
                x = coords.x,
                y = coords.y
            })
        end
    end

    return pois
end

-- Helper function to get continent name
function addon.GetContinentName(mapID)
    local continentID = C_Map.GetWorldPosFromMapPos(mapID, {x=0, y=0})
    if continentID then
        local continentInfo = C_Map.GetMapInfo(continentID)
        return continentInfo and continentInfo.name or nil
    end
    return nil
end
