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
    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then
        print("No map info found for mapID: " .. tostring(mapID))
        return nil
    end

    local zoneName = mapInfo.name
    print("Getting POI data for zone: " .. zoneName)

    local pois = {}
    local continentInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    local continentName = continentInfo and continentInfo.name or "Unknown"

    if CollectCoordDB and CollectCoordDB.exploredCoords then
        print("CollectCoordDB and exploredCoords exist")
        print("Searching in continent: " .. continentName)
        
        if CollectCoordDB.exploredCoords[continentName] and CollectCoordDB.exploredCoords[continentName][zoneName] then
            print("Found zone under continent: " .. continentName)
            for subZoneName, coords in pairs(CollectCoordDB.exploredCoords[continentName][zoneName]) do
                print("Processing sub-zone: " .. subZoneName)
                if type(coords) == "table" and coords.x and coords.y then
                    table.insert(pois, {
                        name = subZoneName,
                        mapID = mapID,
                        x = coords.x,
                        y = coords.y
                    })
                    print(string.format("Added POI: %s at (%.2f, %.2f)", subZoneName, coords.x, coords.y))
                else
                    print("Invalid coords for " .. subZoneName)
                    print("Coords type: " .. type(coords))
                    if type(coords) == "table" then
                        for k, v in pairs(coords) do
                            print(k .. ": " .. tostring(v))
                        end
                    end
                end
            end
        else
            print("Zone not found under continent: " .. continentName)
        end
    else
        print("CollectCoordDB or exploredCoords is nil")
    end

    print("Found " .. #pois .. " POIs for " .. zoneName)
    return pois
end

function addon:GetMapIDByName(mapName)
    if not addon.ZoneIds then
        print("ZoneIds table is nil")
        return nil
    end
    for id, name in pairs(addon.ZoneIds) do
        if name == mapName then
            return id
        end
    end
    return nil
end

function addon:ShowPOIsForCurrentMap()
    local mapID = WorldMapFrame:GetMapID()
    local mapInfo = C_Map.GetMapInfo(mapID)
    local continentInfo = mapInfo and C_Map.GetMapInfo(mapInfo.parentMapID) or nil
    
    print("Viewed map: " .. (mapInfo and mapInfo.name or "Unknown") .. " (ID: " .. mapID .. ") in continent: " .. (continentInfo and continentInfo.name or "Unknown"))
    
    local pois = self:GetPOIData(mapID)
    
    if pois and #pois > 0 then
        print("Received POIs:")
        for i, poi in ipairs(pois) do
            print(string.format("%d. %s at (%.2f, %.2f)", i, poi.name, poi.x, poi.y))
        end
        local count = 0
        for _, poi in ipairs(pois) do
            if self:CreateTomTomWaypoint(poi) then
                count = count + 1
            end
        end
        print("Added " .. count .. " waypoints to TomTom")
        self.activePOIs = count
        return count
    else
        print("No POI data for viewed map (ID: " .. mapID .. ")")
        return 0
    end
end

function addon:CreateTomTomWaypoint(poi)
    if not poi then
        print("CreateTomTomWaypoint: POI is nil")
        return false
    end

    print("CreateTomTomWaypoint: Attempting to create waypoint for:")
    for k, v in pairs(poi) do
        print("  " .. tostring(k) .. ": " .. tostring(v))
    end

    if not poi.x or not poi.y or not poi.mapID then
        print("CreateTomTomWaypoint: Invalid POI data - missing x, y, or mapID")
        return false
    end

    local title = poi.name or "Unknown POI"
    print(string.format("CreateTomTomWaypoint: Creating waypoint for '%s' at (%.2f, %.2f) on mapID %d", 
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
    if TomTom and TomTom.ClearAllWaypoints then
        TomTom:ClearAllWaypoints()
        print("All waypoints cleared")
    else
        local count = 0
        -- Create a temporary table to store UIDs
        local uidsToRemove = {}
        for uid, waypoint in pairs(TomTom.waypoints) do
            table.insert(uidsToRemove, uid)
            count = count + 1
        end
        -- Remove waypoints using their UIDs
        for _, uid in ipairs(uidsToRemove) do
            TomTom:RemoveWaypoint(uid)
        end
        print(string.format("Removed %d waypoints", count))
    end
    -- Clear the waypoints table
    wipe(TomTom.waypoints)
    self.activePOIs = 0
end

function addon:TogglePOIs()
    print("TogglePOIs called. Active POIs:", self.activePOIs)
    if self.activePOIs > 0 then
        print("Removing all POIs")
        self:RemoveAllPOIs()
    else
        print("Showing POIs for current map")
        self:ShowPOIsForCurrentMap()
    end
end

function addon:DecodeCoord(coord)
    local x, y = string.match(coord, "(%d+%.?%d*),(%d+%.?%d*)")
    return tonumber(x), tonumber(y)
end

-- Initialize the database when the addon loads
addon:InitializeDatabase()
