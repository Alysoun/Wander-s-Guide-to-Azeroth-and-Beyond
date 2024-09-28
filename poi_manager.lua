local addonName, addon = ...

-- Table to store active TomTom waypoints
addon.TomTomWaypoints = {}

-- Variable to keep track of active POIs
addon.activePOIs = 0

-- Function to initialize the database
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

-- Function to get POI data for a specific map
function addon:GetPOIData(mapID)
    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then
        print("No map info found for mapID: " .. tostring(mapID))
        return nil
    end

    local mapName = mapInfo.name
    print("Getting POI data for: " .. mapName .. " (mapID: " .. mapID .. ")")

    local pois = {}

    if CollectCoordDB and CollectCoordDB.exploredCoords then
        print("CollectCoordDB and exploredCoords exist")
        
        local function AddPOI(poiName, zoneName, x, y, zoneMapID)
            print(string.format("DEBUG: Adding POI: %s in %s at (%.2f, %.2f)", poiName, zoneName, x, y))
            table.insert(pois, {
                name = poiName,
                zoneName = zoneName,
                mapID = zoneMapID,
                x = x,
                y = y
            })
        end

        local isContinent = (mapInfo.mapType == Enum.UIMapType.Continent)
        print("Is continent view: " .. tostring(isContinent))

        local function GetZoneMapID(parentMapID, zoneName)
            local childMapInfo = C_Map.GetMapChildrenInfo(parentMapID)
            for _, childInfo in ipairs(childMapInfo) do
                if childInfo.name == zoneName then
                    return childInfo.mapID
                end
            end
            return nil
        end

        local function ProcessZoneData(zoneData, zoneName, zoneMapID)
            print("Processing zone: " .. zoneName)
            for poiName, coords in pairs(zoneData) do
                print(string.format("DEBUG: Reading POI: %s at (%.2f, %.2f)", poiName, coords.x, coords.y))
                if type(coords) == "table" and coords.x and coords.y then
                    AddPOI(poiName, zoneName, coords.x, coords.y, zoneMapID)
                else
                    print("Invalid coords for POI: " .. tostring(poiName))
                end
            end
        end

        if isContinent then
            for continentName, continentData in pairs(CollectCoordDB.exploredCoords) do
                if type(continentData) == "table" then
                    for zoneName, zoneData in pairs(continentData) do
                        local zoneMapID = GetZoneMapID(mapID, zoneName)
                        if zoneMapID then
                            ProcessZoneData(zoneData, zoneName, zoneMapID)
                        else
                            print("Could not find mapID for zone: " .. zoneName)
                        end
                    end
                end
            end
        else
            local zoneData = nil
            for continentName, continentData in pairs(CollectCoordDB.exploredCoords) do
                if type(continentData) == "table" and continentData[mapName] then
                    zoneData = continentData[mapName]
                    break
                end
            end
            if zoneData then
                ProcessZoneData(zoneData, mapName, mapID)
            else
                print("Zone not found in CollectCoordDB.exploredCoords: " .. mapName)
            end
        end
    else
        print("CollectCoordDB or exploredCoords is nil")
    end

    print("Found " .. #pois .. " POIs for " .. mapName)
    for i, poi in ipairs(pois) do
        print(string.format("DEBUG: Final POI %d: Name: %s, Zone: %s, X: %.2f, Y: %.2f, MapID: %d", 
                            i, tostring(poi.name), tostring(poi.zoneName), poi.x, poi.y, poi.mapID))
    end
    return pois
end

-- Function to get map ID by name
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

-- Function to show POIs for the current map being viewed
function addon:ShowPOIsForCurrentMap()
    local mapID = WorldMapFrame:GetMapID()
    if not mapID then
        print("No map is currently being viewed.")
        return 0
    end

    local pois = self:GetPOIData(mapID)
    if not pois or #pois == 0 then
        print("No POI data for viewed map (ID: " .. mapID .. ")")
        return 0
    end

    print("Received POIs for viewed map:")
    local count = 0
    for i, poi in ipairs(pois) do
        print(string.format("DEBUG: Full POI %d data:", i))
        for k, v in pairs(poi) do
            print(string.format("  %s: %s", k, tostring(v)))
        end
        if self:CreateTomTomWaypoint(poi) then
            count = count + 1
        end
    end
    
    self.activePOIs = count
    print("Added " .. self.activePOIs .. " waypoints to TomTom")
    return count
end

-- Function to create a TomTom waypoint
function addon:CreateTomTomWaypoint(poi)
    print("DEBUG: Running CreateTomTomWaypoint from poi_manager.lua")
    if not TomTom then
        print("TomTom is not available")
        return false
    end
    
    local x, y = poi.x / 100, poi.y / 100  -- Convert to 0-1 range if necessary
    
    print(string.format("DEBUG: Creating waypoint - Name: %s, Zone: %s, X: %.4f, Y: %.4f, MapID: %d", 
                        tostring(poi.name), tostring(poi.zoneName), x, y, poi.mapID))
    
    local opts = {
        title = poi.name,
        persistent = false,
        minimap = true,
        world = true,
        callbacks = self:GetCustomCallbacks()
    }
    
    print("DEBUG: TomTom options:")
    for k, v in pairs(opts) do
        print(string.format("  %s: %s", k, tostring(v)))
    end
    
    print(string.format("DEBUG: Calling TomTom:AddWaypoint with: mapID: %d, x: %.4f, y: %.4f, title: %s", 
                        poi.mapID, x, y, opts.title))
    
    local uid = TomTom:AddWaypoint(poi.mapID, x, y, opts)
    
    if uid then
        table.insert(self.TomTomWaypoints, {uid = uid, name = poi.name, mapID = poi.mapID, x = x, y = y})
        print(string.format("Created waypoint for '%s' at (%.4f, %.4f) on mapID %d", poi.name, x, y, poi.mapID))
        return true
    else
        print(string.format("Failed to create waypoint for '%s'", poi.name))
        return false
    end
end

-- Function to get custom callbacks for TomTom waypoints
function addon:GetCustomCallbacks()
    return {
        minimap = {
            onclick = function(event, uid, self, button)
                if button == "RightButton" then
                    local waypoint = TomTom:GetWaypoint(uid)
                    if waypoint then
                        addon:ShowCustomMenu(uid, waypoint.title)
                    end
                end
            end,
        },
        world = {
            onclick = function(event, uid, self, button)
                if button == "RightButton" then
                    local waypoint = TomTom:GetWaypoint(uid)
                    if waypoint then
                        addon:ShowCustomMenu(uid, waypoint.title)
                    end
                end
            end,
        },
    }
end

-- Function to remove a TomTom waypoint by name
function addon:RemoveTomTomWaypointByName(name)
    for i, waypoint in ipairs(self.TomTomWaypoints) do
        if waypoint.name == name then
            TomTom:RemoveWaypoint(waypoint.uid)
            table.remove(self.TomTomWaypoints, i)
            self.DebugPrint(string.format("RemoveTomTomWaypointByName: Removed waypoint for '%s'", name))
            return true
        end
    end
    self.DebugPrint(string.format("RemoveTomTomWaypointByName: No waypoint found for '%s'", name))
    return false
end

-- Function to remove all TomTom waypoints
function addon:RemoveAllTomTomWaypoints()
    for _, waypoint in ipairs(self.TomTomWaypoints) do
        TomTom:RemoveWaypoint(waypoint.uid)
    end
    self.TomTomWaypoints = {}
    self.DebugPrint("RemoveAllTomTomWaypoints: All waypoints removed")
end

-- Function to update waypoints based on player position
function addon:UpdateTomTomWaypoints()
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not playerMapID then return end

    local playerPosition = C_Map.GetPlayerMapPosition(playerMapID, "player")
    if not playerPosition then return end

    local playerX, playerY = playerPosition:GetXY()
    local closestWaypoint = nil
    local closestDistance = math.huge

    for _, waypoint in ipairs(self.TomTomWaypoints) do
        if waypoint.mapID == playerMapID then
            local distance = self:CalculateDistance(playerX, playerY, waypoint.x, waypoint.y)
            if distance < closestDistance then
                closestWaypoint = waypoint
                closestDistance = distance
            end
        end
    end

    if closestWaypoint then
        TomTom:SetClosestWaypoint(closestWaypoint.uid)
        self.DebugPrint(string.format("UpdateWaypoints: Set closest waypoint to '%s'", closestWaypoint.name))
    end
end

-- Function to add waypoints for a specific zone
function addon:AddWaypointsForZone(zoneName)
    local zoneData = self:GetPOIsForZone(zoneName)
    if not zoneData then
        self.DebugPrint(string.format("AddWaypointsForZone: No data found for zone '%s'", zoneName))
        return
    end

    local mapID = self:GetMapIDForZone(zoneName)
    if not mapID then
        self.DebugPrint(string.format("AddWaypointsForZone: No mapID found for zone '%s'", zoneName))
        return
    end

    for poiName, coords in pairs(zoneData) do
        if not ExplorationCoordsDB.discoveredAreas[poiName] and not ExplorationCoordsDB.ignoredAreas[poiName] then
            self:CreateTomTomWaypoint({
                name = poiName,
                mapID = mapID,
                x = coords.x,
                y = coords.y
            })
        end
    end
    self.DebugPrint(string.format("AddWaypointsForZone: Added waypoints for zone '%s'", zoneName))
end

-- Function to show custom menu for waypoints
function addon:ShowCustomMenu(uid, pointName)
    local menu = {
        { text = "Mark as Discovered", notCheckable = true, func = function() 
            self:MarkAsDiscovered(pointName)
            TomTom:RemoveWaypoint(uid)
        end },
        { text = "Mark as Ignored", notCheckable = true, func = function() 
            self:MarkAsIgnored(pointName)
            TomTom:RemoveWaypoint(uid)
        end },
    }
    EasyMenu(menu, CreateFrame("Frame", "ExplorationCoordsCustomMenuFrame", UIParent, "UIDropDownMenuTemplate"), "cursor", 0, 0, "MENU")
end

-- Function to hook into TomTom's waypoint system
function addon:HookTomTomWaypoints()
    self.DebugPrint("HookTomTomWaypoints called")
    if not TomTom then
        self.DebugPrint("TomTom not found, retrying in 1 second")
        C_Timer.After(1, function() self:HookTomTomWaypoints() end)
        return
    end

    self.DebugPrint("Hooking into TomTom's waypoint system")
    
    -- Hook into TomTom's waypoint creation function
    local oldAddWaypoint = TomTom.AddWaypoint
    TomTom.AddWaypoint = function(self, mapId, x, y, opts)
        opts = opts or {}
        if opts.source == "ExplorationCoords" then
            addon.DebugPrint("Adding custom menu items for ExplorationCoords waypoint")
            opts.callbacks = opts.callbacks or {}
            for _, callback in ipairs(addon:GetCustomCallbacks()) do
                table.insert(opts.callbacks, callback)
            end
        end
        return oldAddWaypoint(self, mapId, x, y, opts)
    end

    self.DebugPrint("Successfully hooked into TomTom's waypoint system")
end

-- Function to load discovery points for the current map
function addon:LoadDiscoveryPointsForCurrentMap()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then return end

    local zoneName = mapInfo.name
    self:AddWaypointsForZone(zoneName)
end

-- Function to toggle POIs
function addon:TogglePOIs()
    print("TogglePOIs called. Current activePOIs:", self.activePOIs)
    if self.activePOIs == 0 then
        print("Attempting to show POIs for current map")
        local count = self:ShowPOIsForCurrentMap()
        print("ShowPOIsForCurrentMap returned:", count)
        if count and count > 0 then
            self.activePOIs = count
            print("Set activePOIs to:", self.activePOIs)
        else
            print("No POIs were added")
        end
    else
        print("Removing all POIs")
        self:RemoveAllPOIs()
        self.activePOIs = 0
        print("Set activePOIs to 0")
    end
    self:UpdateUI()
    print("TogglePOIs finished. Current activePOIs:", self.activePOIs)
end

-- Function to remove all POIs
function addon:RemoveAllPOIs()
    print("RemoveAllPOIs called")
    if TomTom and TomTom.RemoveAllWaypoints then
        TomTom:RemoveAllWaypoints()
        print("All TomTom waypoints cleared")
    else
        print("TomTom or RemoveAllWaypoints function not available, removing waypoints manually")
        for _, waypoint in ipairs(self.TomTomWaypoints) do
            if TomTom and TomTom.RemoveWaypoint then
                TomTom:RemoveWaypoint(waypoint.uid)
            end
        end
    end
    -- Clear our internal waypoints table
    wipe(self.TomTomWaypoints)
    self.activePOIs = 0
    print("Removed all POIs")
end

-- Function to decode coordinates
function addon:DecodeCoord(coord)
    local x, y = string.match(coord, "(%d+%.?%d*),(%d+%.?%d*)")
    return tonumber(x), tonumber(y)
end

-- Function to calculate distance between two points
function addon:CalculateDistance(x1, y1, x2, y2)
    return ((x2 - x1)^2 + (y2 - y1)^2)^0.5
end

-- Create a frame to handle updates
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
    if self.timeSinceLastUpdate >= 1 then -- Update every second
        addon:UpdateTomTomWaypoints()
        self.timeSinceLastUpdate = 0
    end
end)

-- Make sure DebugPrint is available
if not addon.DebugPrint then
    addon.DebugPrint = function(message)
        print(addonName .. " Debug: " .. message)
    end
end

-- Initialize the waypoint system
function addon:InitializeWaypointSystem()
    self:HookTomTomWaypoints()
    self:InitializeDatabase()
    self.DebugPrint("Waypoint system initialized")
end

-- Call the initialization function when the addon loads
addon:InitializeWaypointSystem()