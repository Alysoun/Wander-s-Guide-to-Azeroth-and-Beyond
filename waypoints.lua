-- waypoints.lua

local addonName, addon = ...

-- Table to store active TomTom waypoints
addon.TomTomWaypoints = {}

-- Function to create a TomTom waypoint
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

-- Function to remove a TomTom waypoint by name
function addon.RemoveTomTomWaypointByName(name)
    for i, waypoint in ipairs(addon.TomTomWaypoints) do
        if waypoint.name == name then
            TomTom:RemoveWaypoint(waypoint.uid)
            table.remove(addon.TomTomWaypoints, i)
            addon.DebugPrint(string.format("RemoveTomTomWaypointByName: Removed waypoint for '%s'", name))
            return true
        end
    end
    addon.DebugPrint(string.format("RemoveTomTomWaypointByName: No waypoint found for '%s'", name))
    return false
end

-- Function to remove all TomTom waypoints
function addon.RemoveAllTomTomWaypoints()
    for _, waypoint in ipairs(addon.TomTomWaypoints) do
        TomTom:RemoveWaypoint(waypoint.uid)
    end
    addon.TomTomWaypoints = {}
    addon.DebugPrint("RemoveAllTomTomWaypoints: All waypoints removed")
end

-- Function to update waypoints based on player position
function addon.UpdateWaypoints()
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not playerMapID then return end

    local playerPosition = C_Map.GetPlayerMapPosition(playerMapID, "player")
    if not playerPosition then return end

    local playerX, playerY = playerPosition:GetXY()
    local closestWaypoint = nil
    local closestDistance = math.huge

    for _, waypoint in ipairs(addon.TomTomWaypoints) do
        if waypoint.mapID == playerMapID then
            local distance = addon.CalculateDistance(playerX, playerY, waypoint.x / 100, waypoint.y / 100)
            if distance < closestDistance then
                closestWaypoint = waypoint
                closestDistance = distance
            end
        end
    end

    if closestWaypoint then
        TomTom:SetClosestWaypoint(closestWaypoint.uid)
        addon.DebugPrint(string.format("UpdateWaypoints: Set closest waypoint to '%s'", closestWaypoint.name))
    end
end

-- Function to add waypoints for a specific zone
function addon.AddWaypointsForZone(zoneName)
    local zoneData = addon.GetPOIsForZone(zoneName)
    if not zoneData then
        addon.DebugPrint(string.format("AddWaypointsForZone: No data found for zone '%s'", zoneName))
        return
    end

    local mapID = addon.GetMapIDForZone(zoneName)
    if not mapID then
        addon.DebugPrint(string.format("AddWaypointsForZone: No mapID found for zone '%s'", zoneName))
        return
    end

    for poiName, coords in pairs(zoneData) do
        if not ExplorationCoordsDB.discoveredAreas[poiName] and not ExplorationCoordsDB.ignoredAreas[poiName] then
            addon.CreateTomTomWaypoint({
                name = poiName,
                mapID = mapID,
                x = coords.x,
                y = coords.y
            })
        end
    end
    addon.DebugPrint(string.format("AddWaypointsForZone: Added waypoints for zone '%s'", zoneName))
end

-- Function to get custom callbacks for TomTom waypoints
function addon:GetCustomCallbacks()
    return {
        {
            "MarkAsDiscovered", 
            function(cb)
                addon.DebugPrint("Mark as Discovered clicked for " .. (cb.title or "unknown"))
                addon.MarkAsDiscovered(cb.title)
                TomTom:RemoveWaypoint(cb.uid)
            end
        },
        {
            "MarkAsIgnored", 
            function(cb)
                addon.DebugPrint("Mark as Ignored clicked for " .. (cb.title or "unknown"))
                addon.MarkAsIgnored(cb.title)
                TomTom:RemoveWaypoint(cb.uid)
            end
        }
    }
end

-- Function to hook into TomTom's waypoint system
function addon.HookTomTomWaypoints()
    addon.DebugPrint("HookTomTomWaypoints called")
    if not TomTom then
        addon.DebugPrint("TomTom not found, retrying in 1 second")
        C_Timer.After(1, addon.HookTomTomWaypoints)
        return
    end

    addon.DebugPrint("Hooking into TomTom's waypoint system")
    
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

    addon.DebugPrint("Successfully hooked into TomTom's waypoint system")
end

-- Function to load discovery points for the current map
function addon.LoadDiscoveryPointsForCurrentMap()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then return end

    local zoneName = mapInfo.name
    addon.AddWaypointsForZone(zoneName)
end

-- Initialize waypoint system
function addon.InitializeWaypointSystem()
    addon.HookTomTomWaypoints()
    addon.DebugPrint("Waypoint system initialized")
end