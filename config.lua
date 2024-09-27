-- config.lua

local addonName, addon = ...

-- Saved Variables
ExplorationCoordsDB = ExplorationCoordsDB or {
    ignoredAreas = {},
    completedAchievements = {},
    discoveredAreas = {}
}

CollectCoordDB = CollectCoordDB or {
    exploredCoords = {}
}

CollectCoordCharDB = CollectCoordCharDB or {}

-- Configuration options
addon.config = {
    DEBUG = false,
    showMinimapButton = true,
    autoTrackNearestPOI = true,
    maxWaypoints = 5,
    minimapIconSize = 16,
}

-- Function to load saved configuration
function addon.LoadConfig()
    if ExplorationCoordsDB.config then
        for key, value in pairs(ExplorationCoordsDB.config) do
            addon.config[key] = value
        end
    end
end

-- Function to save configuration
function addon.SaveConfig()
    ExplorationCoordsDB.config = ExplorationCoordsDB.config or {}
    for key, value in pairs(addon.config) do
        ExplorationCoordsDB.config[key] = value
    end
end

-- Function to reset configuration to defaults
function addon.ResetConfig()
    ExplorationCoordsDB.config = nil
    addon.config = {
        DEBUG = false,
        showMinimapButton = true,
        autoTrackNearestPOI = true,
        maxWaypoints = 5,
        minimapIconSize = 16,
    }
    addon.SaveConfig()
end

-- Continent to Chromie Time expansion mapping
addon.continentToChromieExpansion = {
    ["Eastern Kingdoms"] = "The Cataclysm",
    ["Kalimdor"] = "The Cataclysm",
    ["Outland"] = "Portal to Outland",
    ["Northrend"] = "Fall of the Lich King",
    ["Pandaria"] = "Wilds of Pandaria",
    ["Draenor"] = "Draenor",
    ["Broken Isles"] = "The Legion Invasion",
    ["Zandalar"] = "Battle for Azeroth",
    ["Kul Tiras"] = "Battle for Azeroth",
    ["Shadowlands"] = "Shadowlands",
    ["Dragon Isles"] = "Dragonflight",
}

-- Zone IDs table
addon.ZoneIds = addon.ZoneIds or {}

-- Function to populate Zone IDs
function addon.PopulateZoneIds()
    addon.ZoneIds = {}
    local mapChildrenInfo = C_Map.GetMapChildrenInfo(946, Enum.UIMapType.Zone, true)
    for _, childInfo in ipairs(mapChildrenInfo) do
        addon.ZoneIds[childInfo.name] = childInfo.mapID
    end
    print("ZoneIds populated with " .. addon.TableLength(addon.ZoneIds) .. " entries")
end

-- Helper function to get table length
function addon.TableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Load configuration when the addon is loaded
addon.OnAddonLoaded = addon.OnAddonLoaded or function() end
local originalOnAddonLoaded = addon.OnAddonLoaded
addon.OnAddonLoaded = function(self, event, loadedAddonName)
    if loadedAddonName == addonName then
        addon.LoadConfig()
        addon.PopulateZoneIds()
    end
    originalOnAddonLoaded(self, event, loadedAddonName)
end