ZMKillcountHandler = ZMKillcountHandler or {}

-- Initialize kill count for a player
ZMKillcountHandler.initKillCount = function(player)
    if not player then return end
    -- If we're passed an ID, get the IsoPlayer object
    if type(player) == "number" then
        player = getSpecificPlayer(player)
    end

    -- Initialize kill count if it doesn't exist
    local modData = player:getModData()
    if not modData.zmkillcount then
        modData.zmkillcount = 0
    end
end

-- Get the player's kill count
ZMKillcountHandler.getKillCount = function(player)
    if not player then return 0 end
    -- If we're passed an ID, get the IsoPlayer object
    if type(player) == "number" then
        player = getSpecificPlayer(player)
    end

    local modData = player:getModData()
    return modData.zmkillcount or 0
end

-- Set the player's kill count
ZMKillcountHandler.setKillCount = function(player, count)
    if not player then return end
    -- If we're passed an ID, get the IsoPlayer object
    if type(player) == "number" then
        player = getSpecificPlayer(player)
    end

    local modData = player:getModData()
    modData.zmkillcount = count
end

-- Increment the player's kill count
ZMKillcountHandler.incrementKillCount = function(player, amount)
    amount = amount or 1
    if not player then return end
    -- If we're passed an ID, get the IsoPlayer object
    if type(player) == "number" then
        player = getSpecificPlayer(player)
    end

    local modData = player:getModData()
    modData.zmkillcount = (modData.zmkillcount or 0) + amount
end

-- Send the player's kill count to the server
ZMKillcountHandler.sendKillCountToServer = function()
    local player = getSpecificPlayer(0)
    if not player then return end

    -- Get player's username for unique identification on server
    local username = player:getUsername()
    if not username or username == "" then
        username = player:getFullName() -- Fallback for single player
    end

    -- Get current kill count
    local killCount = ZMKillcountHandler.getKillCount(player)

    -- Send to server via client command
    sendClientCommand("ZonaMerahCore", "sendKillCount", {
        username = username,
        killCount = killCount
    })
end

-- Track zombie kills using weapon hits
local function OnWeaponHit(wielder, weapon, zombie, damage)
    -- Only process if all required objects exist and the zombie is actually a zombie
    if not wielder or not zombie or not instanceof(zombie, "IsoZombie") then
        return
    end

    -- Only track player-caused hits
    if not instanceof(wielder, "IsoPlayer") then
        return
    end

    -- Check if this hit would kill the zombie
    local zombieHealth = zombie:getHealth()

    -- If the zombie has 0 or negative health after the hit, it's dead
    if zombieHealth <= 0 then
        -- Award kill to the player who delivered the fatal blow
        ZMKillcountHandler.incrementKillCount(wielder)
    end
end

-- Hook into the OnCreatePlayer event to initialize kill count
-- ZMKillcountHandler.onCreatePlayer = function(playerIndex, player)
--     ZMKillcountHandler.initKillCount(player)
-- end

-- -- Register the event hooks
-- Events.OnWeaponHitXp.Add(OnWeaponHit)
-- Events.OnCreatePlayer.Add(ZMKillcountHandler.onCreatePlayer)
-- Events.OnGameStart.Add(function()
--     local player = getSpecificPlayer(0)
--     if player then
--         ZMKillcountHandler.initKillCount(player)
--     end

--     -- Initial send of kill count
--     ZMKillcountHandler.sendKillCountToServer()
-- end)

-- Send kill count to server every hour
-- Events.EveryHours.Add(ZMKillcountHandler.sendKillCountToServer)



