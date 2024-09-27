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
addon.ZoneIds = {}

-- Function to populate Zone IDs
function addon.PopulateZoneIds()
    for continentID = 1, 2000 do
        local continentInfo = C_Map.GetMapInfo(continentID)
        if continentInfo then
            for zoneID = 1, 2000 do
                local zoneInfo = C_Map.GetMapInfo(zoneID)
                if zoneInfo and zoneInfo.parentMapID == continentID then
                    addon.ZoneIds[zoneInfo.name] = zoneID
                end
            end
        end
    end
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