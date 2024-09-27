-- tomtom.lua

local addonName, addon = ...

-- Table to store active TomTom waypoints
addon.TomTomWaypoints = addon.TomTomWaypoints or {}
print("TomTomWaypoints initialized, count: " .. #addon.TomTomWaypoints)

-- Function to create a TomTom waypoint
function addon:CreateTomTomWaypoint(poi)
    if not TomTom then
        print("TomTom is not available")
        return false
    end
    
    local x, y = poi.x / 100, poi.y / 100  -- Convert to 0-1 range if necessary
    
    print("Creating TomTom waypoint:", poi.name, "at", x, y, "on map", poi.mapID)
    
    local uid = TomTom:AddWaypoint(poi.mapID, x, y, {
        title = poi.name,
        persistent = false,
        minimap = true,
        world = true
    })
    
    if uid then
        table.insert(self.TomTomWaypoints, {uid = uid, name = poi.name})
        print("Created TomTom waypoint for:", poi.name)
        return true
    else
        print("Failed to create TomTom waypoint for:", poi.name)
        return false
    end
end

-- Function to remove all TomTom waypoints created by the addon
function addon:RemoveAllTomTomWaypoints()
    local count = 0
    if TomTom then
        for i = #self.TomTomWaypoints, 1, -1 do
            local waypoint = self.TomTomWaypoints[i]
            if waypoint and waypoint.uid then
                TomTom:RemoveWaypoint(waypoint.uid)
                count = count + 1
                table.remove(self.TomTomWaypoints, i)
            end
        end
    end
    
    print("Removed " .. count .. " TomTom waypoints")
    return count
end

-- Function to update TomTom waypoints based on player position
function addon:UpdateTomTomWaypoints()
--    print("UpdateTomTomWaypoints called")
    if not self or not self.TomTomWaypoints then
        print("Error: self or self.TomTomWaypoints is nil")
        return
    end
    
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not playerMapID then 
        print("Error: Unable to get player map ID")
        return 
    end

    local playerPosition = C_Map.GetPlayerMapPosition(playerMapID, "player")
    if not playerPosition then 
        print("Error: Unable to get player position")
        return 
    end

    local playerX, playerY = playerPosition:GetXY()
    if not playerX or not playerY then 
        print("Error: Unable to get player X or Y coordinate")
        return 
    end

   -- print("Player position: " .. playerX .. ", " .. playerY)
 --   print("Number of waypoints: " .. #self.TomTomWaypoints)

    local waypointsToRemove = {}

    for i, waypoint in ipairs(self.TomTomWaypoints) do
        if waypoint.mapID == playerMapID then
            local distance = ((playerX - waypoint.x)^2 + (playerY - waypoint.y)^2)^0.5
            print("Waypoint " .. waypoint.name .. " distance: " .. distance)
            if distance < 0.05 then  -- If within 5% of the map's size
                print("Player is near waypoint: " .. waypoint.name)
                table.insert(waypointsToRemove, i)
            end
        end
    end

 --   print("Waypoints to remove: " .. #waypointsToRemove)

    -- Remove waypoints
    for i = #waypointsToRemove, 1, -1 do
        local index = waypointsToRemove[i]
        local waypoint = self.TomTomWaypoints[index]
        if TomTom and TomTom.RemoveWaypoint then
            TomTom:RemoveWaypoint(waypoint.uid)
        else
            print("Error: TomTom or RemoveWaypoint function not available")
        end
        table.remove(self.TomTomWaypoints, index)
    end

  --  print("UpdateTomTomWaypoints completed")
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