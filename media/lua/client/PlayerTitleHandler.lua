PlayerTitleHandler = PlayerTitleHandler or {}
local titlesValue = {1, 2, 3}

PlayerTitleHandler.REQUEST_COOLDOWN_MS = 30000
PlayerTitleHandler._lastTitleRequestAt = 0

local function nowMs()
    if getTimestampMs then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

-- 1 = VIP, 2 = VVIP, 3 = MVP
function PlayerTitleHandler.assignPlayerTitle(player, title)
    if not player then
        return
    end

    local modData = player:getModData()
    local username = player:getUsername()
    local safeTitle = tonumber(title) or 0

    modData.PlayerTitle = safeTitle

    sendClientCommand("PlayerTitleHandler", "savePlayerTitle", {
        username = username,
        title = safeTitle
    })

    player:Say("Your grade has been upgraded successfully: " .. safeTitle)
end

function PlayerTitleHandler.requestPlayerTitle(player, forceRequest)
    if not player or not isClient or not isClient() then
        return
    end

    local now = nowMs()
    if not forceRequest then
        local elapsed = now - (PlayerTitleHandler._lastTitleRequestAt or 0)
        if elapsed >= 0 and elapsed < PlayerTitleHandler.REQUEST_COOLDOWN_MS then
            return
        end
    end

    PlayerTitleHandler._lastTitleRequestAt = now
    sendClientCommand("PlayerTitleHandler", "loadPlayerTitle", {
        username = player:getUsername()
    })
end

function PlayerTitleHandler.getPlayerTitle(player)
    if not player then
        return 0
    end

    local modData = player:getModData()
    local cachedTitle = tonumber(modData.PlayerTitle)
    if cachedTitle ~= nil then
        return cachedTitle
    end

    modData.PlayerTitle = 0
    PlayerTitleHandler.requestPlayerTitle(player, false)
    return 0
end

Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "PlayerTitleHandler" then
        return
    end

    if command == "loadPlayerTitleResponse" then
        local player = getPlayer()
        if player and player:getUsername() == args.username then
            local modData = player:getModData()
            local title = tonumber(args.title) or 0
            modData.PlayerTitle = title

            if PlayerTierHandler and PlayerTierHandler.updatePlayerTier then
                PlayerTierHandler.updatePlayerTier(player, false)
                if PlayerTierHandler.syncTierSnapshot then
                    PlayerTierHandler.syncTierSnapshot(player, true)
                end
            end
        end
    end
end)

Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
    local player = playerObj or getSpecificPlayer(playerIndex) or getPlayer()
    if player then
        PlayerTitleHandler.requestPlayerTitle(player, true)
    end
end)

Events.EveryTenMinutes.Add(function()
    if not isClient or not isClient() then
        return
    end

    local player = getPlayer()
    if player then
        PlayerTitleHandler.requestPlayerTitle(player, false)
    end
end)

return PlayerTitleHandler
