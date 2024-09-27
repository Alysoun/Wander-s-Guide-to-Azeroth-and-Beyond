-- main.lua

local addonName, addon = ...
print("Wanderer's Guide to Azeroth and Beyond: main.lua loading")

addon.loadedFiles = {}

-- Debug function using the game's message system
local function DebugPrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DEBUG " .. addonName .. "]|r " .. tostring(message))
end

addon.DebugPrint = DebugPrint

LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceEvent-3.0", "AceTimer-3.0")

function addon:InitializeDatabase()
    if CollectCoordDB and CollectCoordDB.exploredCoords then
        for continent, zones in pairs(CollectCoordDB.exploredCoords) do
            for zone, pois in pairs(zones) do
                print("Continent: " .. continent .. ", Zone: " .. zone .. ", Number of POIs: " .. #pois)
            end
        end
    else
        print("CollectCoordDB or exploredCoords is empty or nil")
    end
end

function addon:OnInitialize()
    print("Wanderer's Guide: OnInitialize started")
    self:DebugPrint(addonName .. " initializing")
    
    -- Load configuration
    print("Wanderer's Guide: Loading configuration")
    self:LoadConfig()
    
    -- Initialize database
    print("Wanderer's Guide: Initializing database")
    self:InitializeDatabase()
    
    -- Populate Zone IDs
    print("Wanderer's Guide: Populating Zone IDs")
    self:PopulateZoneIds()
    
    -- Register events
    print("Wanderer's Guide: Registering events")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("ACHIEVEMENT_EARNED")
    self:RegisterEvent("CRITERIA_COMPLETE")
    self:RegisterEvent("QUEST_TURNED_IN")
    self:RegisterEvent("PLAYER_XP_UPDATE")
    
    print("Wanderer's Guide: OnInitialize completed")
end

function addon:OnEnable()
    print("Wanderer's Guide: OnEnable started")
    self:DebugPrint("Addon enabled")
    print("Wanderer's Guide: About to initialize UI")
    self:InitializeUI()
    self:InitializeWaypointSystem()
    self:ScheduleRepeatingTimer("UpdateTomTomWaypoints", 1)
    print("Wanderer's Guide: OnEnable completed")
end

function addon:PLAYER_ENTERING_WORLD()
    self:DebugPrint("Player entering world")
    self:UpdateUI()
end

function addon:PLAYER_LOGIN()
    self:DebugPrint("Player logged in")
    self:UpdatePlayerInfo()
    self:CheckChromieTimeStatus()
end

function addon:ZONE_CHANGED_NEW_AREA()
    self:DebugPrint("Zone changed")
    self:UpdateUI()
    if self.LevelingMode then
        self:UpdateLevelingSuggestions()
    end
end

function addon:ACHIEVEMENT_EARNED(achievementID)
    self:DebugPrint("Achievement " .. achievementID .. " earned")
    self:ProcessAchievement(achievementID)
end

function addon:CRITERIA_COMPLETE(criteriaID)
    self:DebugPrint("Criteria " .. criteriaID .. " completed")
    self:ProcessCriteria(criteriaID)
end

function addon:QUEST_TURNED_IN(questID, xpReward, moneyReward)
    self:DebugPrint("Quest " .. questID .. " turned in")
    self:ProcessQuestTurnIn(questID, xpReward)
end

function addon:PLAYER_XP_UPDATE()
    self:DebugPrint("Player XP updated")
    self:UpdateXPEstimation()
end

-- Slash command
SLASH_WANDERERSGUIDE1 = "/wg"
SlashCmdList["WANDERERSGUIDE"] = function(msg)
    addon:HandleSlashCommand(msg)
end

SLASH_WGCHECK1 = "/wgcheck"
SlashCmdList["WGCHECK"] = function(msg)
    print("Wanderer's Guide to Azeroth and Beyond is " .. (addon:IsEnabled() and "loaded" or "not loaded"))
end

function addon:HandleSlashCommand(msg)
    if msg == "debug" then
        self:ToggleDebugMode()
    elseif msg == "reset" then
        self:ResetConfig()
    elseif msg == "start" then
        self:StartLevelingProcess()
    elseif msg == "stop" then
        self:StopLevelingProcess()
    else
        print("Wanderer's Guide to Azeroth and Beyond commands:")
        print("  /wg debug - Toggle debug mode")
        print("  /wg reset - Reset addon configuration")
        print("  /wg start - Start leveling process")
        print("  /wg stop - Stop leveling process")
    end
end

C_Timer.After(0, function()
    addon:DebugPrint("Files loaded for " .. addonName .. ":")
    for _, file in ipairs(addon.loadedFiles) do
        addon:DebugPrint("  - " .. file)
    end
end)

DebugPrint("Addon initialization complete")