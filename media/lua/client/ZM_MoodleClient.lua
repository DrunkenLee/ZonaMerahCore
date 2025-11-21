-- ============================================================================
-- ZM_MoodleClient.lua - Moodle Framework Implementation for ZonaMerah Core
-- ============================================================================

-- Based on the MoreSmokes mod implementation pattern
-- Requires Moodle Framework mod to be installed and loaded first

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

require "MF_ISMoodle"

-- Check if Moodle Framework is installed
if not getActivatedMods():contains("MoodleFramework") then
    -- print("[ZonaMerah] Warning: Moodle Framework not installed. Custom moodles will not work.")
    -- print("[ZonaMerah] Make sure 'Moodle Framework' mod is installed and enabled!")
    return
end

ZM_Moodle = ZM_Moodle or {}

-- ============================================================================
-- LOCAL VARIABLES
-- ============================================================================

local isPlayerValid = false

local playerVariables = {
    RunSpeedScale = "RunSpeed",
    RunBlendTime = "RunBlend",
    SneakRunSpeedScale = "SneakRunSpeed",
    SneakRunBlendTime = "SneakRunBlend",
    SprintSpeedScale = "SprintSpeed",
    SprintBlendTime = "SprintBlend",
}

-- ============================================================================
-- LOCAL FUNCTIONS
-- ============================================================================

local function isMoodleFrameworkAvailable()
    return MF and MF.createMoodle and MF.getMoodle
end

local function setThresholds()
    -- Parameters: bad4, bad3, bad2, bad1, good1, good2, good3, good4
    -- nil = not used, numbers = threshold values (0.0 to 1.0)
    MF.getMoodle("Pumped"):setThresholds(nil, nil, nil, nil, 0.2, 0.4, 0.6, 0.8)
    -- print("[ZonaMerah] Pumped moodle thresholds set")
end

local function validPlayer(playerIndex, player)
    -- Validate player (called by OnCreatePlayer event)
    -- This ensures the moodle is only initialized for valid players
    -- @param playerIndex - The player index
    -- @param player - The player object
    if player == getPlayer() then
        isPlayerValid = true
        setThresholds()
        -- print("[ZonaMerah] Pumped moodle initialized for player")
    else
        -- print("[ZonaMerah] Player is not valid")
    end
end

-- ============================================================================
-- MOODLE CREATION (MUST be at top level, not in a function!)
-- ============================================================================

MF.createMoodle("Pumped")

-- ============================================================================
-- PUBLIC FUNCTIONS
-- ============================================================================

local function applySpeedBonus(player, moodleValue)
    -- Apply speed bonus based on moodle level using player variables
    -- Moodle levels: 0.2 = lvl1 (+1%), 0.4 = lvl2 (+2%), 0.6 = lvl3 (+5%), 0.8 = lvl4 (+10%)
    local speedBonus = 1.0 -- Default: no bonus

    if moodleValue >= 0.8 then
        speedBonus = 1.10 -- +10% speed
    elseif moodleValue >= 0.6 then
        speedBonus = 1.05 -- +5% speed
    elseif moodleValue >= 0.4 then
        speedBonus = 1.02 -- +2% speed
    elseif moodleValue >= 0.2 then
        speedBonus = 1.01 -- +1% speed
    end

    -- Store the speed bonus in player mod data
    local playerModData = player:getModData()
    playerModData.ZM_SpeedBonus = speedBonus

    -- Apply speed bonus to player movement variables
    if not player:getWornItems() then return end

    local defaultModifiers = {
        RunSpeed = 1.04,
        RunBlend = 0.35,
        SneakRunSpeed = 0.92,
        SneakRunBlend = 0.50,
        SprintSpeed = 0.96,
        SprintBlend = 0.15,
    }

    local wornItems = player:getWornItems()

    -- Calculate clothing modifiers
    for i = 1, wornItems:size() do
        local item = wornItems:get(i-1):getItem()
        if instanceof(item, "Clothing") and item:getBodyLocation() then
            local itemSM = item:getRunSpeedModifier() or 1
            for key, value in pairs(defaultModifiers) do
                defaultModifiers[key] = value * itemSM
            end
        end
    end

    -- Apply speed bonus on top of clothing modifiers
    for key, value in pairs(defaultModifiers) do
        defaultModifiers[key] = value * speedBonus
    end

    -- Set player variables with combined modifiers
    for playerVariable, modifierKey in pairs(playerVariables) do
        player:setVariable(playerVariable, defaultModifiers[modifierKey])
    end
end

function ZM_Moodle.initializePumpedMoodle()
    print("[ZonaMerah] Initializing Pumped moodle...")
    if not isMoodleFrameworkAvailable() then
        -- print("[ZonaMerah] Warning: Moodle Framework not available. Custom moodles will not work.")
        return false
    end
    -- Set thresholds for when different levels appear
    setThresholds()
    -- Set whether chevron points up (good) or down (bad)
    MF.getMoodle("Pumped"):setChevronIsUp(true)
    -- print("[ZonaMerah] Pumped moodle initialized successfully")
    return true
end

function ZM_Moodle.updatePumpedValue(player, value)
    -- Update the Pumped moodle value for a player
    -- @param player - The player object
    -- @param value - The value to set (0.0 to 1.0)
    if not player then
        -- print("[ZonaMerah] ERROR: No player provided!")
        return false
    end
    if not isPlayerValid then
        -- print("[ZonaMerah] Warning: Player not validated yet. Moodle will not update.")
        return false
    end
    if not isMoodleFrameworkAvailable() then
        -- print("[ZonaMerah] ERROR: Moodle Framework not available!")
        return false
    end
    local pumpedMoodle = MF.getMoodle("Pumped")
    if pumpedMoodle then
        -- Clamp value between 0 and 1
        local clampedValue = math.max(0, math.min(1, value))
        -- Update the moodle
        pumpedMoodle:setValue(clampedValue)
        -- Apply speed bonus based on new moodle value
        applySpeedBonus(player, clampedValue)
        -- print("[ZonaMerah] Pumped moodle updated to: " .. clampedValue)
        return true
    else
        -- print("[ZonaMerah] Error: Failed to get Pumped moodle instance after creation")
        -- print("[ZonaMerah] This might mean Moodle Framework is not working properly")
        return false
    end
end

function ZM_Moodle.getPumpedValue()
    -- Get current Pumped moodle value
    -- @return number - Current moodle value (0.0 to 1.0)
    if not isPlayerValid then
        return 0
    end
    if not isMoodleFrameworkAvailable() then
        return 0
    end
    local pumpedMoodle = MF.getMoodle("Pumped")
    if pumpedMoodle then
        return pumpedMoodle:getValue() or 0
    end
    return 0
end

function ZM_Moodle.debugMoodleStatus()
    -- Debug function to check moodle status
    -- Prints detailed information about the moodle state
    print("=== ZonaMerah Moodle Debug ===")
    print("Moodle Framework loaded: " .. tostring(getActivatedMods():contains("MoodleFramework")))
    print("MF available: " .. tostring(MF ~= nil))
    print("Player valid: " .. tostring(isPlayerValid))
    if MF then
        print("MF.createMoodle exists: " .. tostring(MF.createMoodle ~= nil))
        print("MF.getMoodle exists: " .. tostring(MF.getMoodle ~= nil))
        local pumpedMoodle = MF.getMoodle("Pumped")
        if pumpedMoodle then
            print("Pumped moodle exists: true")
            print("Current value: " .. tostring(pumpedMoodle:getValue()))
            print("Current level: " .. tostring(pumpedMoodle:getLevel()))
        else
            print("Pumped moodle exists: false")
        end
    else
        print("MF does not exist!")
    end
    local player = getPlayer()
    if player then
        print("Player exists: true")
    else
        print("Player exists: false")
    end
    print("==============================")
end

function ZM_Moodle.testMoodle(value)
    -- Manual test function for console
    -- Usage: ZM_Moodle.testMoodle(1) or ZM_Moodle.testMoodle(0.5)
    -- @param value - Optional value to test (default: 1.0)
    value = value or 1.0

    local player = getPlayer()
    if not player then

        return
    end
    -- Ensure moodle is initialized
    if not MF or not MF.getMoodle("Pumped") then

        ZM_Moodle.initializePumpedMoodle()
    end
    -- Update the value
    local result = ZM_Moodle.updatePumpedValue(player, value)
    if result then

    else

        if not isPlayerValid then

        end
    end
    -- Show debug info
    ZM_Moodle.debugMoodleStatus()
end

function ZM_Moodle.onEveryOneMinute()
    -- Update pumped moodle based on recent zombie kills (called every minute)
    -- Example logic: You can customize this based on your mod's needs
    local player = getPlayer()
    if not player or not isPlayerValid then
        return
    end
    -- Get player's mod data
    local modData = player:getModData()
    -- Initialize kill tracking if needed
    if not modData.ZM_RecentKills then
        modData.ZM_RecentKills = 0
    end
    -- Initialize decay counter (for 3x slower decay)
    if not modData.ZM_DecayCounter then
        modData.ZM_DecayCounter = 0
    end
    -- Increment decay counter
    modData.ZM_DecayCounter = modData.ZM_DecayCounter + 1
    -- Decay recent kills every 3 minutes instead of every 1 (3x longer duration)
    if modData.ZM_DecayCounter >= 3 then
        modData.ZM_DecayCounter = 0
        modData.ZM_RecentKills = math.max(0, modData.ZM_RecentKills - 1)
    end
    -- Calculate pumped value based on recent kills
    -- Formula: 50 kills = max pumped level (1.0)
    local pumpedValue = math.min(1.0, modData.ZM_RecentKills / 50)
    -- Update the moodle
    ZM_Moodle.updatePumpedValue(player, pumpedValue)
end

function ZM_Moodle.onZombieKilled(zombie)
    -- Track zombie kills to increase pumped level
    -- @param zombie - The zombie that was killed
    local player = getPlayer()
    if not player or not isPlayerValid then
        return
    end
    -- Get player's mod data
    local modData = player:getModData()
    if not modData.ZM_RecentKills then
        modData.ZM_RecentKills = 0
    end
    -- Increase recent kill count
    modData.ZM_RecentKills = modData.ZM_RecentKills + 1
    -- Update moodle immediately
    local pumpedValue = math.min(1.0, modData.ZM_RecentKills / 50)
    ZM_Moodle.updatePumpedValue(player, pumpedValue)
end


Events.OnCreatePlayer.Add(validPlayer)
Events.EveryOneMinute.Add(ZM_Moodle.onEveryOneMinute)
Events.OnZombieDead.Add(ZM_Moodle.onZombieKilled)

-- Re-apply speed modifiers when clothing changes
local function onClothingUpdated(player)
    if not isPlayerValid then return end
    -- Reapply the current moodle value to recalculate speed with new clothing
    local pumpedValue = ZM_Moodle.getPumpedValue()
    if pumpedValue > 0 then
        applySpeedBonus(player, pumpedValue)
    end
end

Events.OnClothingUpdated.Add(onClothingUpdated)

print("[ZonaMerah] Moodle client module loaded successfully")

return ZM_Moodle