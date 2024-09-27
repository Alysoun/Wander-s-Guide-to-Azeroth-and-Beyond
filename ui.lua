local addonName, addon = ...

local lastMapID = nil

function addon:CheckAndUpdateMap()
    local currentMapID = WorldMapFrame:GetMapID()
    if currentMapID ~= addon.lastMapID then
        addon.lastMapID = currentMapID
        addon:UpdateExplorationButtonText()
    end
end

-- Function to create a custom tab button
local function CreateTabButton(name, parent)
    local tab = CreateFrame("Button", name, parent)
    tab:SetSize(115, 32)
    
    tab.Left = tab:CreateTexture(nil, "BACKGROUND")
    tab.Left:SetTexture("Interface\\ChatFrame\\ChatFrameTab")
    tab.Left:SetTexCoord(0, 0.25, 0, 1)
    tab.Left:SetPoint("TOPLEFT")
    tab.Left:SetSize(32, 32)

    tab.Right = tab:CreateTexture(nil, "BACKGROUND")
    tab.Right:SetTexture("Interface\\ChatFrame\\ChatFrameTab")
    tab.Right:SetTexCoord(0.75, 1, 0, 1)
    tab.Right:SetPoint("TOPRIGHT")
    tab.Right:SetSize(32, 32)

    tab.Middle = tab:CreateTexture(nil, "BACKGROUND")
    tab.Middle:SetTexture("Interface\\ChatFrame\\ChatFrameTab")
    tab.Middle:SetTexCoord(0.25, 0.75, 0, 1)
    tab.Middle:SetPoint("LEFT", tab.Left, "RIGHT")
    tab.Middle:SetPoint("RIGHT", tab.Right, "LEFT")
    tab.Middle:SetSize(51, 32)

    tab.Text = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    tab.Text:SetPoint("CENTER", 0, 2)
    tab:SetFontString(tab.Text)

    tab:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight", "ADD")

    return tab
end

-- Function to select a tab
function addon:SelectTab(frame, id)
    for i, tab in ipairs(frame.tabs) do
        if i == id then
            tab.Left:SetTexCoord(0, 0.25, 0, 1)
            tab.Middle:SetTexCoord(0.25, 0.75, 0, 1)
            tab.Right:SetTexCoord(0.75, 1, 0, 1)
            tab:Disable()
            frame.tabContents[i]:Show()
        else
            tab.Left:SetTexCoord(0, 0.25, 0.5, 1)
            tab.Middle:SetTexCoord(0.25, 0.75, 0.5, 1)
            tab.Right:SetTexCoord(0.75, 1, 0.5, 1)
            tab:Enable()
            frame.tabContents[i]:Hide()
        end
    end
end

-- Function to create the main frame content
function addon:CreateMainFrameContent(frame)
    local tabNames = {"Exploration", "Leveling", "Settings"}
    
    for i, tabName in ipairs(tabNames) do
        local tab = CreateTabButton(addonName.."MainFrameTab"..i, frame)
        tab:SetText(tabName)
        tab:SetID(i)
        
        tab:SetScript("OnClick", function(self)
            addon:SelectTab(frame, self:GetID())
        end)
        
        if i == 1 then
            tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 2)
        else
            tab:SetPoint("LEFT", frame.tabs[i-1], "RIGHT", -10, 0)
        end
        
        table.insert(frame.tabs, tab)
        
        local content = CreateFrame("Frame", nil, frame)
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
        content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
        content:Hide()
        
        frame.tabContents[i] = content
    end
    
    -- Select the first tab by default
    addon:SelectTab(frame, 1)
    
    -- Create content for each tab
    addon:CreateExplorationTab(frame.tabContents[1])
    addon:CreateLevelingTab(frame.tabContents[2])
    addon:CreateSettingsTab(frame.tabContents[3])
end

-- Function to create the Exploration tab content
function addon:CreateExplorationTab(content)
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 10, -10)
    text:SetText("Exploration content goes here")
    
    -- Add more UI elements for the Exploration tab here
end

-- Function to create the Leveling tab content
function addon:CreateLevelingTab(content)
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 10, -10)
    text:SetText("Leveling content goes here")
    
    -- Add more UI elements for the Leveling tab here
end

-- Function to create the Settings tab content
function addon:CreateSettingsTab(content)
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 10, -10)
    text:SetText("Settings content goes here")
    
    -- Add more UI elements for the Settings tab here
end

-- Function to update the Exploration button text
function addon:UpdateExplorationButtonText()
    local mapID = WorldMapFrame:GetMapID()
    local mapInfo = C_Map.GetMapInfo(mapID)
    local currentMap = mapInfo and mapInfo.name or "Unknown Map"
    
    if currentMap == "Cosmic" or currentMap == "Azeroth" then
        addon.ShowAllPOIsButton:SetText("POIs not available")
        addon.ShowAllPOIsButton:Disable()
    else
        local text = "Show all POIs for " .. currentMap
        addon.ShowAllPOIsButton:SetText(text)
        addon.ShowAllPOIsButton:Enable()
    end

    -- Get the width of the button text and adjust button size
    local textWidth = addon.ShowAllPOIsButton:GetFontString():GetStringWidth()
    addon.ShowAllPOIsButton:SetWidth(textWidth + 20)  -- Add padding to the width
end

-- Function to create map buttons
function addon:CreateMapButtons()
    local parentFrame = WorldMapFrame.BorderFrame or WorldMapFrame

    -- Create the Exploration button (ShowAllPOIsButton)
    if not addon.ShowAllPOIsButton then
        addon.ShowAllPOIsButton = CreateFrame("Button", addonName.."MapButton", parentFrame, "UIPanelButtonTemplate")
        addon.ShowAllPOIsButton:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 10, 20)
        addon.ShowAllPOIsButton:SetSize(120, 25)
        addon.ShowAllPOIsButton:SetText("Show All POIs")
        addon.ShowAllPOIsButton:SetScript("OnClick", function()
            local count = addon:ShowPOIsForCurrentMap()
            if count > 0 then
                addon.ShowAllPOIsButton:SetText("Remove All POIs")
                addon.activePOIs = count
            else
                print("No POIs found for the current map")
            end
        end)
        addon:MakeFrameMovable(addon.ShowAllPOIsButton, "Exploration")
    end

    -- Create the Leveling button
    if not addon.LevelingButton then
        addon.LevelingButton = CreateFrame("Button", addonName.."LevelingButton", parentFrame, "UIPanelButtonTemplate")
        addon.LevelingButton:SetText("Start Leveling")
        addon.LevelingButton:SetPoint("LEFT", addon.ShowAllPOIsButton, "RIGHT", 5, 0)
        addon.LevelingButton:SetSize(100, 25)
        addon.LevelingButton:SetScript("OnClick", addon.ToggleLevelingMode)
        addon:MakeFrameMovable(addon.LevelingButton, "Leveling")
    end

    -- Create the Remove All POIs button
    if not addon.RemoveAllPOIsButton then
        addon.RemoveAllPOIsButton = CreateFrame("Button", addonName.."RemoveAllButton", parentFrame, "UIPanelButtonTemplate")
        addon.RemoveAllPOIsButton:SetPoint("TOPLEFT", addon.ShowAllPOIsButton, "BOTTOMLEFT", 0, -5)
        addon.RemoveAllPOIsButton:SetSize(120, 25)
        addon.RemoveAllPOIsButton:SetText("Remove All POIs")
        addon.RemoveAllPOIsButton:SetScript("OnClick", function(self)
            print("Remove All POIs button clicked")
            addon:RemoveAllPOIs()
        end)
    end

    -- Add a script to update the button when the map is shown
    WorldMapFrame:RegisterCallback("OnMapChanged", function()
        addon:CheckAndUpdateMap()
    end)
end

-- Function to make a frame movable
function addon:MakeFrameMovable(frame, buttonName)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if IsAltKeyDown() or IsControlKeyDown() then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save the position
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        if addon.db and addon.db.profile then
            addon.db.profile[buttonName .. "Position"] = {point, relativePoint, xOfs, yOfs}
        end
    end)
end

-- Function to initialize UI components
function addon:InitializeUI()
    print("Wanderer's Guide: InitializeUI started")
    
    -- Add this before creating any frames or buttons
    if not WorldMapFrame then
        print("Wanderer's Guide: WorldMapFrame not found")
        return
    end
    
    -- Add debug prints before creating each UI element
    print("Wanderer's Guide: Creating main frame")
    -- Code to create main frame
    
    print("Wanderer's Guide: Creating map buttons")
    -- Code to create map buttons
    
    print("Wanderer's Guide: Setting up WorldMapFrame hook")
    -- Code to set up WorldMapFrame hook
    
    print("Wanderer's Guide: InitializeUI completed")
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
end

-- Call this at the end of the file to ensure all functions are defined
addon:InitializeUI()

-- Add this function to create the Remove All POIs button
    function addon:ShowAllPOIs(continentID)
        print("ShowAllPOIs called for continent ID:", continentID)
        
        local poiData = self:GetPOIData(continentID)
        if not poiData then
            print("No POI data found for continent ID:", continentID)
            return 0
        end
        
        print("POI data structure:")
        for zoneID, zoneData in pairs(poiData) do
            print("  Zone ID:", zoneID, "Number of POIs:", #zoneData)
        end
        
        local count = 0
        for zoneID, zoneData in pairs(poiData) do
            count = count + self:ShowPOIsForZone(zoneID, zoneData)
        end
        
        print("Total POIs added for continent:", count)
        return count
    end
    
    function addon:ShowPOIsForZone(zoneID, zoneData)
        print("Adding POIs for zone ID:", zoneID)
        local count = 0
        for _, poi in ipairs(zoneData) do
            if self:AddPOI(zoneID, poi.x, poi.y, poi.title) then
                count = count + 1
            end
        end
        print("Added", count, "POIs for zone ID:", zoneID)
        return count
    end
    
    function addon:AddPOI(zoneID, x, y, title)
        if TomTom then
            local uid = TomTom:AddWaypoint(zoneID, x/100, y/100, {
                title = title,
                persistent = false,
                minimap = true,
                world = true
            })
            if uid then
                print("Added POI:", title, "at", x, y, "in zone", zoneID)
                return true
            else
                print("Failed to add POI:", title, "at", x, y, "in zone", zoneID)
            end
        end
        return false
    end

-- Add these functions to your addon table

function addon:UpdateUI()
    -- Update any UI elements here
    if self.ShowAllPOIsButton then
        self.ShowAllPOIsButton:SetText(self.activePOIs > 0 and "Remove All POIs" or "Show All POIs")
    end
    -- Add any other UI updates you need
end