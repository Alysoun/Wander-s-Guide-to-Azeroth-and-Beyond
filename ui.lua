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
    print("Wanderer's Guide: Creating map buttons")
    local parentFrame = WorldMapFrame.BorderFrame or WorldMapFrame

    -- Create a container frame for our buttons
    if not addon.ButtonContainer then
        addon.ButtonContainer = CreateFrame("Frame", addonName.."ButtonContainer", parentFrame)
        addon.ButtonContainer:SetSize(250, 60)
        addon.ButtonContainer:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 10, 10)
        addon.ButtonContainer:SetMovable(true)
        addon.ButtonContainer:EnableMouse(true)
        addon.ButtonContainer:RegisterForDrag("LeftButton")
        addon.ButtonContainer:SetScript("OnDragStart", function(self)
            if IsControlKeyDown() or IsAltKeyDown() then
                self:StartMoving()
            end
        end)
        addon.ButtonContainer:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            addon:SaveButtonPosition()
        end)
        -- Make the container frame click-through
        addon.ButtonContainer:EnableMouse(false)
    end

    -- Create the "Show All POIs" button
    if not addon.ShowAllPOIsButton then
        addon.ShowAllPOIsButton = CreateFrame("Button", addonName.."ShowPOIsButton", addon.ButtonContainer, "UIPanelButtonTemplate")
        addon.ShowAllPOIsButton:SetSize(120, 25)
        addon.ShowAllPOIsButton:SetPoint("TOPLEFT", addon.ButtonContainer, "TOPLEFT", 0, 0)
        addon.ShowAllPOIsButton:SetText("Show All POIs")
        addon.ShowAllPOIsButton:SetScript("OnClick", function()
            addon:TogglePOIs()
        end)
        addon.ShowAllPOIsButton:SetScript("OnDragStart", function()
            addon.ButtonContainer:GetScript("OnDragStart")(addon.ButtonContainer)
        end)
        addon.ShowAllPOIsButton:SetScript("OnDragStop", function()
            addon.ButtonContainer:GetScript("OnDragStop")(addon.ButtonContainer)
        end)
        addon.ShowAllPOIsButton:RegisterForDrag("LeftButton")
    end

    -- Create the "Remove POIs" button
    if not addon.RemovePOIsButton then
        addon.RemovePOIsButton = CreateFrame("Button", addonName.."RemovePOIsButton", addon.ButtonContainer, "UIPanelButtonTemplate")
        addon.RemovePOIsButton:SetSize(120, 25)
        addon.RemovePOIsButton:SetPoint("TOPLEFT", addon.ShowAllPOIsButton, "BOTTOMLEFT", 0, -5)
        addon.RemovePOIsButton:SetText("Remove POIs")
        addon.RemovePOIsButton:SetScript("OnClick", function()
            addon:RemoveAllPOIs()
        end)
        addon.RemovePOIsButton:SetScript("OnDragStart", function()
            addon.ButtonContainer:GetScript("OnDragStart")(addon.ButtonContainer)
        end)
        addon.RemovePOIsButton:SetScript("OnDragStop", function()
            addon.ButtonContainer:GetScript("OnDragStop")(addon.ButtonContainer)
        end)
        addon.RemovePOIsButton:RegisterForDrag("LeftButton")
    end

    -- Create the "Leveling" button
    if not addon.LevelingButton then
        addon.LevelingButton = CreateFrame("Button", addonName.."LevelingButton", addon.ButtonContainer, "UIPanelButtonTemplate")
        addon.LevelingButton:SetSize(120, 25)
        addon.LevelingButton:SetPoint("LEFT", addon.ShowAllPOIsButton, "RIGHT", 10, 0)
        addon.LevelingButton:SetText("Leveling")
        addon.LevelingButton:SetScript("OnClick", function()
            addon:ToggleLevelingMode()
        end)
        addon.LevelingButton:SetScript("OnDragStart", function()
            addon.ButtonContainer:GetScript("OnDragStart")(addon.ButtonContainer)
        end)
        addon.LevelingButton:SetScript("OnDragStop", function()
            addon.ButtonContainer:GetScript("OnDragStop")(addon.ButtonContainer)
        end)
        addon.LevelingButton:RegisterForDrag("LeftButton")
    end

    -- Add tooltip to each button
    local function AddMoveTooltip(button)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Hold Ctrl/Alt to move")
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end

    AddMoveTooltip(addon.ShowAllPOIsButton)
    AddMoveTooltip(addon.RemovePOIsButton)
    AddMoveTooltip(addon.LevelingButton)

    addon:LoadButtonPosition()
    print("Wanderer's Guide: Map buttons created")
end

-- Function to save button positions
function addon:SaveButtonPosition()
    local point, _, relativePoint, xOfs, yOfs = addon.ButtonContainer:GetPoint()
    WandererGuideDB = WandererGuideDB or {}
    WandererGuideDB.buttonPosition = {point, relativePoint, xOfs, yOfs}
end

-- Function to load button positions
function addon:LoadButtonPosition()
    if WandererGuideDB and WandererGuideDB.buttonPosition then
        local point, relativePoint, xOfs, yOfs = unpack(WandererGuideDB.buttonPosition)
        addon.ButtonContainer:ClearAllPoints()
        addon.ButtonContainer:SetPoint(point, WorldMapFrame, relativePoint, xOfs, yOfs)
    end
end

-- Function to reset button positions
function addon:ResetButtonPosition()
    addon.ButtonContainer:ClearAllPoints()
    addon.ButtonContainer:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMLEFT", 10, 10)
    addon:SaveButtonPosition()
    print("Wanderer's Guide: Button positions reset")
end

-- Function to initialize UI components
function addon:InitializeUI()
    print("Wanderer's Guide: InitializeUI started")
    
    if not WorldMapFrame then
        print("Wanderer's Guide: WorldMapFrame not found")
        return
    end
    
    self:CreateMapButtons()
    self:SetupWorldMapHook()
    
    -- Ensure buttons are visible when the map is shown
    WorldMapFrame:HookScript("OnShow", function()
        if addon.ShowAllPOIsButton then addon.ShowAllPOIsButton:Show() end
        if addon.RemovePOIsButton then addon.RemovePOIsButton:Show() end
        if addon.LevelingButton then addon.LevelingButton:Show() end
    end)
    
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

-- Function to toggle leveling mode
function addon:ToggleLevelingMode()
    self.LevelingMode = not self.LevelingMode
    if self.LevelingMode then
        print("Leveling mode enabled")
        -- Add any additional logic for enabling leveling mode
    else
        print("Leveling mode disabled")
        -- Add any additional logic for disabling leveling mode
    end
    self:UpdateLevelingButton()
end

-- Function to update leveling button text
function addon:UpdateLevelingButton()
    if self.LevelingButton then
        self.LevelingButton:SetText(self.LevelingMode and "Leveling On" or "Leveling Off")
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