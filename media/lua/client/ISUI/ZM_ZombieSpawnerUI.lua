-- ZM_ZombieSpawnerUI.lua - UI for Zombie Spawning Functions
require "ISUI/ISPanel"

ZM_ZombieSpawnerUI = ISPanel:derive("ZM_ZombieSpawnerUI")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function ZM_ZombieSpawnerUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.width = width
    o.height = height
    o.moveWithMouse = true
    o.title = "ZM Zombie Spawner Control"
    return o
end

function ZM_ZombieSpawnerUI:initialise()
    ISPanel.initialise(self)

    local btnWidth = 120
    local btnHeight = 25
    local padding = 10
    local currentY = 40

    -- Title
    self.titleLabel = ISLabel:new(padding, 10, FONT_HGT_MEDIUM, "ZM Zombie Spawner Control", 1, 1, 1, 1, UIFont.Medium, true)
    self:addChild(self.titleLabel)

    -- ========== SPAWN AT COORDINATES SECTION ==========
    self.coordsLabel = ISLabel:new(padding, currentY, FONT_HGT_SMALL, "Spawn at Coordinates:", 1, 1, 0, 1, UIFont.Small, true)
    self:addChild(self.coordsLabel)
    currentY = currentY + 25

    -- X Coordinate
    self.xLabel = ISLabel:new(padding, currentY, FONT_HGT_SMALL, "X:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.xLabel)
    self.xEntry = ISTextEntryBox:new("0", 40, currentY - 2, 80, 20)
    self.xEntry:initialise()
    self:addChild(self.xEntry)

    -- Y Coordinate
    self.yLabel = ISLabel:new(140, currentY, FONT_HGT_SMALL, "Y:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.yLabel)
    self.yEntry = ISTextEntryBox:new("0", 160, currentY - 2, 80, 20)
    self.yEntry:initialise()
    self:addChild(self.yEntry)

    -- Z Coordinate
    self.zLabel = ISLabel:new(260, currentY, FONT_HGT_SMALL, "Z:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.zLabel)
    self.zEntry = ISTextEntryBox:new("0", 280, currentY - 2, 60, 20)
    self.zEntry:initialise()
    self:addChild(self.zEntry)
    currentY = currentY + 30

    -- Zombie Type for coords
    self.coordsTypeLabel = ISLabel:new(padding, currentY, FONT_HGT_SMALL, "Type:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.coordsTypeLabel)
    self.coordsTypeCombo = ISComboBox:new(60, currentY - 2, 100, 20, self, self.onCoordsTypeChange)
    self.coordsTypeCombo:initialise()
    self:addChild(self.coordsTypeCombo)

    -- Count for coords
    self.coordsCountLabel = ISLabel:new(180, currentY, FONT_HGT_SMALL, "Count:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.coordsCountLabel)
    self.coordsCountEntry = ISTextEntryBox:new("1", 230, currentY - 2, 60, 20)
    self.coordsCountEntry:initialise()
    self:addChild(self.coordsCountEntry)
    currentY = currentY + 30

    -- Spawn at coords button
    self.spawnCoordsBtn = ISButton:new(padding, currentY, btnWidth, btnHeight, "Spawn at Coords", self, self.onSpawnAtCoords)
    self.spawnCoordsBtn:initialise()
    self:addChild(self.spawnCoordsBtn)
    currentY = currentY + 40

    -- ========== SPAWN AT PLAYER SECTION ==========
    self.playerLabel = ISLabel:new(padding, currentY, FONT_HGT_SMALL, "Spawn at Player:", 1, 1, 0, 1, UIFont.Small, true)
    self:addChild(self.playerLabel)
    currentY = currentY + 25

    -- Zombie Type for player spawn
    self.playerTypeLabel = ISLabel:new(padding, currentY, FONT_HGT_SMALL, "Type:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.playerTypeLabel)
    self.playerTypeCombo = ISComboBox:new(60, currentY - 2, 100, 20, self, self.onPlayerTypeChange)
    self.playerTypeCombo:initialise()
    self:addChild(self.playerTypeCombo)

    -- Count for player spawn
    self.playerCountLabel = ISLabel:new(180, currentY, FONT_HGT_SMALL, "Count:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.playerCountLabel)
    self.playerCountEntry = ISTextEntryBox:new("1", 230, currentY - 2, 60, 20)
    self.playerCountEntry:initialise()
    self:addChild(self.playerCountEntry)

    -- Safe Radius for player spawn
    self.safeRadiusLabel = ISLabel:new(310, currentY, FONT_HGT_SMALL, "Safe:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.safeRadiusLabel)
    self.safeRadiusEntry = ISTextEntryBox:new("0", 350, currentY - 2, 50, 20)
    self.safeRadiusEntry:initialise()
    self:addChild(self.safeRadiusEntry)
    currentY = currentY + 30

    -- Spawn at player button
    self.spawnPlayerBtn = ISButton:new(padding, currentY, btnWidth, btnHeight, "Spawn at Player", self, self.onSpawnAtPlayer)
    self.spawnPlayerBtn:initialise()
    self:addChild(self.spawnPlayerBtn)
    currentY = currentY + 40

    -- ========== SPAWN HORDE SECTION ==========
    self.hordeLabel = ISLabel:new(padding, currentY, FONT_HGT_SMALL, "Spawn Horde:", 1, 1, 0, 1, UIFont.Small, true)
    self:addChild(self.hordeLabel)
    currentY = currentY + 25

    -- Horde Count
    self.hordeCountLabel = ISLabel:new(padding, currentY, FONT_HGT_SMALL, "Count:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.hordeCountLabel)
    self.hordeCountEntry = ISTextEntryBox:new("10", 60, currentY - 2, 60, 20)
    self.hordeCountEntry:initialise()
    self:addChild(self.hordeCountEntry)

    -- Horde Radius
    self.hordeRadiusLabel = ISLabel:new(140, currentY, FONT_HGT_SMALL, "Radius:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.hordeRadiusLabel)
    self.hordeRadiusEntry = ISTextEntryBox:new("5", 190, currentY - 2, 60, 20)
    self.hordeRadiusEntry:initialise()
    self:addChild(self.hordeRadiusEntry)

    -- Horde Safe Radius
    self.hordeSafeLabel = ISLabel:new(270, currentY, FONT_HGT_SMALL, "Safe:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.hordeSafeLabel)
    self.hordeSafeEntry = ISTextEntryBox:new("0", 310, currentY - 2, 50, 20)
    self.hordeSafeEntry:initialise()
    self:addChild(self.hordeSafeEntry)
    currentY = currentY + 30

    -- Horde Type
    self.hordeTypeLabel = ISLabel:new(padding, currentY, FONT_HGT_SMALL, "Type:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.hordeTypeLabel)
    self.hordeTypeCombo = ISComboBox:new(60, currentY - 2, 100, 20, self, self.onHordeTypeChange)
    self.hordeTypeCombo:initialise()
    self:addChild(self.hordeTypeCombo)

    -- Target Player checkbox and entry
    self.targetCheckbox = ISTickBox:new(180, currentY, 20, 20, "", self, self.onTargetToggle)
    self.targetCheckbox:initialise()
    self:addChild(self.targetCheckbox)

    self.targetLabel = ISLabel:new(205, currentY + 2, FONT_HGT_SMALL, "Target:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.targetLabel)

    self.targetEntry = ISTextEntryBox:new("", 250, currentY - 2, 100, 20)
    self.targetEntry:initialise()
    self:addChild(self.targetEntry)
    currentY = currentY + 30

    -- Spawn horde button
    self.spawnHordeBtn = ISButton:new(padding, currentY, btnWidth, btnHeight, "Spawn Horde", self, self.onSpawnHorde)
    self.spawnHordeBtn:initialise()
    self:addChild(self.spawnHordeBtn)
    currentY = currentY + 40

    -- ========== CONTROL BUTTONS ==========
    -- Close button
    self.closeBtn = ISButton:new(self.width - 80, 10, 70, 25, "Close", self, self.onClose)
    self.closeBtn:initialise()
    self:addChild(self.closeBtn)

    -- Get current player position button
    self.getCurrentPosBtn = ISButton:new(padding, currentY, 150, btnHeight, "Get Current Position", self, self.onGetCurrentPos)
    self.getCurrentPosBtn:initialise()
    self:addChild(self.getCurrentPosBtn)

    -- Populate zombie type combos
    self:populateZombieTypes()

    -- Set initial state for target entry
    if self.targetEntry and self.targetEntry.setEditable then
        self.targetEntry:setEditable(false)
    end
end

function ZM_ZombieSpawnerUI:populateZombieTypes()
    -- ONLY allow zombie types that are defined in ZM_ZombieHandlerServer.ZombieTypes
    -- These are the only types that have proper configurations and loot tables
    local validZombieTypes = {
        "elite",      -- Elite soldier zombie (ArmyCamoGreen)
        "elite2",     -- Elite soldier zombie (ArmyCamoDesert)
        "screamer1",  -- Screamer type 1
        "screamer2",  -- Screamer type 2
        "psycho1",    -- Psycho type 1
        "psycho2"     -- Psycho type 2
    }

    -- Clear existing items
    self.coordsTypeCombo:clear()
    self.playerTypeCombo:clear()
    self.hordeTypeCombo:clear()

    -- Add only valid zombie types
    for _, zombieType in ipairs(validZombieTypes) do
        self.coordsTypeCombo:addOption(zombieType)
        self.playerTypeCombo:addOption(zombieType)
        self.hordeTypeCombo:addOption(zombieType)
    end

    -- Set default selections (elite as default)
    self.coordsTypeCombo.selected = 1
    self.playerTypeCombo.selected = 1
    self.hordeTypeCombo.selected = 1
end

function ZM_ZombieSpawnerUI:onGetCurrentPos()
    local player = getPlayer()
    if player then
        local square = player:getSquare()
        if square then
            self.xEntry:setText(tostring(square:getX()))
            self.yEntry:setText(tostring(square:getY()))
            self.zEntry:setText(tostring(square:getZ()))
        end
    end
end

function ZM_ZombieSpawnerUI:onSpawnAtCoords()
    local x = tonumber(self.xEntry:getText()) or 0
    local y = tonumber(self.yEntry:getText()) or 0
    local z = tonumber(self.zEntry:getText()) or 0
    local count = tonumber(self.coordsCountEntry:getText()) or 1
    local zombieType = self.coordsTypeCombo:getOptionText(self.coordsTypeCombo.selected) or "elite"

    -- Validate zombie type
    local validTypes = {"elite", "elite2", "screamer1", "screamer2", "psycho1", "psycho2"}
    local isValid = false
    for _, validType in ipairs(validTypes) do
        if zombieType == validType then
            isValid = true
            break
        end
    end

    if not isValid then
        print("Error: Invalid zombie type '" .. tostring(zombieType) .. "'. Only elite, elite2, screamer1, screamer2, psycho1, psycho2 are supported.")
        return
    end

    if ZM_ZombieHandler and ZM_ZombieHandler.spawnZombieAtCoords then
        ZM_ZombieHandler.spawnZombieAtCoords(x, y, z, zombieType, count)
        print(string.format("Spawning %d %s zombie(s) at (%d, %d, %d)", count, zombieType, x, y, z))
    else
        print("Error: ZM_ZombieHandler.spawnZombieAtCoords not available")
    end
end

function ZM_ZombieSpawnerUI:onSpawnAtPlayer()
    local count = tonumber(self.playerCountEntry:getText()) or 1
    local safeRadius = tonumber(self.safeRadiusEntry:getText()) or 0
    local zombieType = self.playerTypeCombo:getOptionText(self.playerTypeCombo.selected) or "elite"

    -- Validate zombie type
    local validTypes = {"elite", "elite2", "screamer1", "screamer2", "psycho1", "psycho2"}
    local isValid = false
    for _, validType in ipairs(validTypes) do
        if zombieType == validType then
            isValid = true
            break
        end
    end

    if not isValid then
        print("Error: Invalid zombie type '" .. tostring(zombieType) .. "'. Only elite, elite2, screamer1, screamer2, psycho1, psycho2 are supported.")
        return
    end

    if ZM_ZombieHandler and ZM_ZombieHandler.consoleSpawnZombie then
        ZM_ZombieHandler.consoleSpawnZombie(zombieType, count, safeRadius)
        print(string.format("Spawning %d %s zombie(s) at player location (safe radius: %d)", count, zombieType, safeRadius))
    else
        print("Error: ZM_ZombieHandler.consoleSpawnZombie not available")
    end
end

function ZM_ZombieSpawnerUI:onSpawnHorde()
    local count = tonumber(self.hordeCountEntry:getText()) or 10
    local radius = tonumber(self.hordeRadiusEntry:getText()) or 5
    local safeRadius = tonumber(self.hordeSafeEntry:getText()) or 0
    local zombieType = self.hordeTypeCombo:getOptionText(self.hordeTypeCombo.selected) or "elite"
    local isTargeted = self.targetCheckbox:isSelected()
    local targetUsername = isTargeted and self.targetEntry:getText() or nil

    -- Validate zombie type
    local validTypes = {"elite", "elite2", "screamer1", "screamer2", "psycho1", "psycho2"}
    local isValid = false
    for _, validType in ipairs(validTypes) do
        if zombieType == validType then
            isValid = true
            break
        end
    end

    if not isValid then
        print("Error: Invalid zombie type '" .. tostring(zombieType) .. "'. Only elite, elite2, screamer1, screamer2, psycho1, psycho2 are supported.")
        return
    end

    if ZM_ZombieHandler and ZM_ZombieHandler.consoleSpawnHorde then
        ZM_ZombieHandler.consoleSpawnHorde(count, radius, isTargeted, targetUsername, zombieType, false, safeRadius)
        local message = string.format("Spawning horde of %d %s zombie(s) (radius: %d, safe: %d)", count, zombieType, radius, safeRadius)
        if isTargeted and targetUsername then
            message = message .. " targeting " .. targetUsername
        end
        print(message)
    else
        print("Error: ZM_ZombieHandler.consoleSpawnHorde not available")
    end
end

function ZM_ZombieSpawnerUI:onTargetToggle()
    if self.targetEntry and self.targetEntry.setEditable then
        self.targetEntry:setEditable(self.targetCheckbox:isSelected())
    end
end

function ZM_ZombieSpawnerUI:onCoordsTypeChange()
    -- Optional: handle zombie type change for coords
end

function ZM_ZombieSpawnerUI:onPlayerTypeChange()
    -- Optional: handle zombie type change for player spawn
end

function ZM_ZombieSpawnerUI:onHordeTypeChange()
    -- Optional: handle zombie type change for horde
end

function ZM_ZombieSpawnerUI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

function ZM_ZombieSpawnerUI:render()
    ISPanel.render(self)
end

-- Global function to open the UI
function openZombieSpawnerUI()
    local player = getPlayer()
    if not player then
        print("Error: No player found")
        return
    end

    -- Check if player is admin
    if not player:isAccessLevel("admin") then
        print("Error: Admin access required")
        return
    end

    local ui = ZM_ZombieSpawnerUI:new(100, 100, 420, 450)
    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)
end

-- -- Keyboard shortcut to open UI (Ctrl + Z)
-- local function onKeyPressed(key)
--     if key == Keyboard.KEY_Z and isCtrlKeyDown() then
--         local player = getPlayer()
--         if player and player:isAccessLevel("admin") then
--             openZombieSpawnerUI()
--         end
--     end
-- end

-- Events.OnKeyPressed.Add(onKeyPressed)

return ZM_ZombieSpawnerUI
