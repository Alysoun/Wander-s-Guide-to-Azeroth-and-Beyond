-- pois.lua

local addonName, addon = ...

-- Add this variable at the top of the file to keep track of active POIs
addon.activePOIs = 0

function addon:InitializeDatabase()
    print("Initializing database")
    if not CollectCoordDB then
        print("CollectCoordDB is nil")
    elseif not CollectCoordDB.exploredCoords then
        print("CollectCoordDB.exploredCoords is nil")
    else
        print("CollectCoordDB structure:")
        for continent, zones in pairs(CollectCoordDB.exploredCoords) do
            print("  Continent: " .. continent)
            for zone, pois in pairs(zones) do
                print("    Zone: " .. zone .. ", POIs: " .. #pois)
            end
        end
    end
    
    self.db = CollectCoordDB
    
    if not self.db.exploredCoords then
        print("Warning: exploredCoords not found in database. Initializing empty table.")
        self.db.exploredCoords = {}
    end
    
    local continentCount = 0
    for _ in pairs(self.db.exploredCoords) do continentCount = continentCount + 1 end
    print("Number of continents in database:", continentCount)
    
    -- Debug: Print structure of exploredCoords
    for continent, zones in pairs(self.db.exploredCoords) do
        print("Continent:", continent)
        for zone, coords in pairs(zones) do
            print("  Zone:", zone, "Number of POIs:", #coords)
        end
    end
end

function addon:GetPOIData(mapID)
    self:DebugPrint("GetPOIData called for mapID: " .. tostring(mapID))
    if not self.db or not self.db.exploredCoords then
        print("Error: Database or exploredCoords not initialized")
        return {}
    end

    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then
        print("Error: Invalid map ID", mapID)
        return {}
    end

    local zoneName = mapInfo.name
    local continentID = mapInfo.parentMapID
    local continentInfo = C_Map.GetMapInfo(continentID)
    local continentName = continentInfo and continentInfo.name or "Unknown"

    print("Searching for POIs in zone:", zoneName, "continent:", continentName)

    local pois = {}

    -- Function to add POIs from a specific zone
    local function addPOIsFromZone(zoneData, zoneMapID)
        for poiName, poiData in pairs(zoneData) do
            if type(poiData) == "table" and poiData.x and poiData.y then
                table.insert(pois, {x = poiData.x, y = poiData.y, title = poiName, mapID = zoneMapID})
            end
        end
    end

    -- Check if we're looking at a continent
    if self.db.exploredCoords[zoneName] then
        print("Loading continent-wide POIs for", zoneName)
        for subZoneName, subZoneData in pairs(self.db.exploredCoords[zoneName]) do
            local subZoneMapID = self:GetMapIDByName(subZoneName)
            if subZoneMapID then
                addPOIsFromZone(subZoneData, subZoneMapID)
            end
        end
    elseif self.db.exploredCoords[continentName] and self.db.exploredCoords[continentName][zoneName] then
        print("Loading zone-specific POIs for", zoneName)
        addPOIsFromZone(self.db.exploredCoords[continentName][zoneName], mapID)
    else
        print("No POI data found for", zoneName, "in", continentName)
    end

    print("Found", #pois, "POIs")
    self:DebugPrint("GetPOIData found " .. #pois .. " POIs")
    return pois
end

function addon:GetMapIDByName(mapName)
    for id, name in pairs(self.mapIDToName) do
        if name == mapName then
            return id
        end
    end
    return nil
end

function addon:ShowPOIsForCurrentMap()
    local mapID = WorldMapFrame:GetMapID()
    if not mapID then 
        print("Unable to get current map ID")
        return 0
    end

    local mapInfo = C_Map.GetMapInfo(mapID)
    local continentInfo = mapInfo and C_Map.GetMapInfo(mapInfo.parentMapID)
    
    print("Viewed map: " .. (mapInfo and mapInfo.name or "Unknown") .. " (ID: " .. mapID .. ") in continent: " .. (continentInfo and continentInfo.name or "Unknown"))
    
    local pois = self:GetPOIData(mapID)
    
    if pois and #pois > 0 then
        local count = 0
        for _, poi in ipairs(pois) do
            if self:CreateTomTomWaypoint(poi) then
                count = count + 1
            end
        end
        print("Added " .. count .. " waypoints to TomTom")
        return count
    else
        print("No POI data for viewed map (ID: " .. mapID .. ")")
        return 0
    end
end

function addon:CreateTomTomWaypoint(poi)
    if not poi or not poi.x or not poi.y or not poi.mapID then
        print("Invalid POI data:", poi)
        return false
    end

    local title = poi.title or "Unknown POI"
    print(string.format("CreateTomTomWaypoint: Attempting to create waypoint for '%s' at (%.2f, %.2f) on mapID %d", 
        title, poi.x, poi.y, poi.mapID))

    if TomTom then
        TomTom:AddWaypoint(poi.mapID, poi.x / 100, poi.y / 100, {
            title = title,
            persistent = false,
            minimap = true,
            world = true
        })
        return true
    else
        print("TomTom not found. Unable to create waypoint.")
        return false
    end
end

function addon:RemoveAllPOIs()
    if TomTom then
        TomTom:ClearWaypoints()
        print("All waypoints cleared")
    else
        print("TomTom not found. Unable to clear waypoints.")
    end
    self.activePOIs = 0
    -- Do not change any button text here
end

function addon:TogglePOIs()
    if self.activePOIs == 0 then
        local count = self:ShowPOIsForCurrentMap()
        if count > 0 then
            self.activePOIs = count
        end
    else
        self:RemoveAllPOIs()
        self.activePOIs = 0
    end
    -- The button text remains unchanged
end

function addon:DecodeCoord(coord)
    local x, y = string.match(coord, "(%d+%.?%d*),(%d+%.?%d*)")
    return tonumber(x), tonumber(y)
end

-- Initialize the database when the addon loads
addon:InitializeDatabase()
