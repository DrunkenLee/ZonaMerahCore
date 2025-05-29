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
    if not modData.zmkillcountNEW then
        modData.zmkillcountNEW = 0
    end
    -- Initialize RavenCreek kill count if it doesn't exist
    if not modData.zmKillCountRavenCreek then
        modData.zmKillCountRavenCreek = 0
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
    return modData.zmkillcountNEW or 0
end

-- Set the player's kill count
ZMKillcountHandler.setKillCount = function(player, count)
    if not player then return end
    -- If we're passed an ID, get the IsoPlayer object
    if type(player) == "number" then
        player = getSpecificPlayer(player)
    end

    local modData = player:getModData()
    modData.zmkillcountNEW = count
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
    modData.zmkillcountNEW = (modData.zmkillcountNEW or 0) + amount
end

-- Get the player's RavenCreek kill count
ZMKillcountHandler.getRavenCreekKillCount = function(player)
    if not player then return 0 end
    -- If we're passed an ID, get the IsoPlayer object
    if type(player) == "number" then
        player = getSpecificPlayer(player)
    end

    local modData = player:getModData()
    return modData.zmKillCountRavenCreek or 0
end

-- Set the player's RavenCreek kill count
ZMKillcountHandler.setRavenCreekKillCount = function(player, count)
    if not player then return end
    -- If we're passed an ID, get the IsoPlayer object
    if type(player) == "number" then
        player = getSpecificPlayer(player)
    end

    local modData = player:getModData()
    modData.zmKillCountRavenCreek = count
end

-- Increment the player's RavenCreek kill count
ZMKillcountHandler.incrementRavenCreekKillCount = function(player, amount)
    amount = amount or 1
    if not player then return end
    -- If we're passed an ID, get the IsoPlayer object
    if type(player) == "number" then
        player = getSpecificPlayer(player)
    end

    local modData = player:getModData()
    modData.zmKillCountRavenCreek = (modData.zmKillCountRavenCreek or 0) + amount
end

-- Check if a position is within RavenCreek area
ZMKillcountHandler.isInRavenCreek = function(x, y)
    local minX, maxX = 3008, 4364
    local minY, maxY = 10990, 13555

    return x >= minX and x <= maxX and y >= minY and y <= maxY
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

    local zombieHealth = zombie:getHealth()

    if zombieHealth <= 0 then
        -- Increment general kill count
        ZMKillcountHandler.incrementKillCount(wielder)

        -- Check if the kill happened in RavenCreek
        local zombieX = wielder:getX()
        local zombieY = wielder:getY()

        if ZMKillcountHandler.isInRavenCreek(zombieX, zombieY) then
            ZMKillcountHandler.incrementRavenCreekKillCount(wielder)
        end
    end
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

    -- Get current kill counts
    local killCount = ZMKillcountHandler.getKillCount(player)
    local ravenCreekKillCount = ZMKillcountHandler.getRavenCreekKillCount(player)

    -- Send to server via client command
    sendClientCommand("ZonaMerahCore", "sendKillCount", {
        username = username,
        killCount = killCount,
        ravenCreekKillCount = ravenCreekKillCount
    })
end

-- Hook into the OnCreatePlayer event to initialize kill count
ZMKillcountHandler.onCreatePlayer = function(playerIndex, player)
    ZMKillcountHandler.initKillCount(player)
end

-- -- Register the event hooks
Events.OnWeaponHitXp.Add(OnWeaponHit)
Events.OnCreatePlayer.Add(ZMKillcountHandler.onCreatePlayer)
Events.OnGameStart.Add(function()
    local player = getSpecificPlayer(0)
    if player then
        ZMKillcountHandler.initKillCount(player)
    end

    -- Initial send of kill count
    ZMKillcountHandler.sendKillCountToServer()
end)

-- Send kill count to server every hour
Events.EveryHours.Add(ZMKillcountHandler.sendKillCountToServer)


Events.OnGameStart.Add(function()
    local player = getSpecificPlayer(0)
    if player then
        Events.OnTick.Add(function()
            local inventory = getPlayerInventory(0)
            if inventory then
                inventory.title = "Zona Merah Inventory"
                Events.OnTick.Remove(this)
            end
        end)
    end
end)