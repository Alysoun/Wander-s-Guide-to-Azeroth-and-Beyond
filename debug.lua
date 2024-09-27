-- debug.lua

local addonName, addon = ...

-- Debug print function
local function DebugPrint(message)
    if addon.config and addon.config.debug then
        print(addonName .. " Debug: " .. tostring(message))
    end
end

-- Function to toggle debug mode
function addon.ToggleDebugMode()
    addon.config.DEBUG = not addon.config.DEBUG
    addon.SaveConfig()
    print("ExplorationCoords: Debug mode " .. (addon.config.DEBUG and "enabled" or "disabled"))
end

-- Debug slash command
SLASH_EXPLOREDEBUG1 = "/exploredebug"
SlashCmdList["EXPLOREDEBUG"] = function(msg)
    if msg == "on" then
        addon.config.DEBUG = true
        addon.SaveConfig()
        print("ExplorationCoords: Debugging enabled.")
    elseif msg == "off" then
        addon.config.DEBUG = false
        addon.SaveConfig()
        print("ExplorationCoords: Debugging disabled.")
    else
        print("ExplorationCoords: Usage - /exploredebug [on|off]")
    end
end

-- Function to print the contents of CollectCoordDB
function addon.DebugPrintCollectCoordDB()
    if CollectCoordDB and CollectCoordDB.exploredCoords then
        addon.DebugPrint("Printing available expansions and zones in CollectCoordDB:")
        for expansion, zones in pairs(CollectCoordDB.exploredCoords) do
            addon.DebugPrint("Expansion: " .. expansion)
            for zone, _ in pairs(zones) do
                addon.DebugPrint("  Zone: " .. zone)
            end
        end
    else
        addon.DebugPrint("CollectCoordDB or exploredCoords table is missing or empty.")
    end
end

-- Function to print Chromie Time options
function addon.DebugPrintChromieTimeOptions()
    local options = C_ChromieTime.GetChromieTimeExpansionOptions()
    if options and #options > 0 then
        addon.DebugPrint("Chromie Time expansions loaded:")
        for i, option in ipairs(options) do
            if option.minLevel and option.maxLevel and option.minLevel > 0 and option.maxLevel > 0 then
                addon.DebugPrint(string.format("Chromie Time: %s (Level %d-%d)", option.name, option.minLevel, option.maxLevel))
            else
                addon.DebugPrint(string.format("Chromie Time: %s (Level data unavailable)", option.name))
            end
        end
    else
        addon.DebugPrint("No Chromie Time data available. Using static data fallback.")
    end
end

-- Function to print current addon state
function addon.DebugPrintAddonState()
    addon.DebugPrint("Current Addon State:")
    addon.DebugPrint("  Leveling Mode: " .. tostring(addon.LevelingMode))
    addon.DebugPrint("  Showing Discoveries: " .. tostring(addon.ShowingDiscoveries))
    addon.DebugPrint("  Number of TomTom Waypoints: " .. tostring(#addon.TomTomWaypoints))
    addon.DebugPrint("  Number of Discovered Areas: " .. tostring(#ExplorationCoordsDB.discoveredAreas))
    addon.DebugPrint("  Number of Ignored Areas: " .. tostring(#ExplorationCoordsDB.ignoredAreas))
end

-- Function to dump a table's contents (recursive)
function addon.DebugDumpTable(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            addon.DebugPrint(formatting)
            addon.DebugDumpTable(v, indent+1)
        else
            addon.DebugPrint(formatting .. tostring(v))
        end
    end
end

-- Debug command to dump specific tables
SLASH_EXPLOREDUMP1 = "/exploredump"
SlashCmdList["EXPLOREDUMP"] = function(msg)
    if msg == "config" then
        addon.DebugPrint("Dumping addon.config:")
        addon.DebugDumpTable(addon.config)
    elseif msg == "discovered" then
        addon.DebugPrint("Dumping ExplorationCoordsDB.discoveredAreas:")
        addon.DebugDumpTable(ExplorationCoordsDB.discoveredAreas)
    elseif msg == "ignored" then
        addon.DebugPrint("Dumping ExplorationCoordsDB.ignoredAreas:")
        addon.DebugDumpTable(ExplorationCoordsDB.ignoredAreas)
    elseif msg == "zoneids" then
        addon.DebugPrint("Dumping addon.ZoneIds:")
        addon.DebugDumpTable(addon.ZoneIds)
    else
        print("ExplorationCoords: Usage - /exploredump [config|discovered|ignored|zoneids]")
    end
end

-- Addon directory (alternative method)
local addonDir = string.match(debugstack(), "AddOns\\(.+)\\") or ""
DebugPrint("Addon directory (alternative method): " .. addonDir)

-- Listing some global variables:
DebugPrint("Listing some global variables:")
for _, var in ipairs({"addonName", "addon", "GetAddOnMetadata", "C_AddOns"}) do
    DebugPrint(var .. " = " .. tostring(_G[var]))
end

-- At the end of the file, add:
addon.DebugPrint = DebugPrint