-- ZM_KillCountClient.lua - Client-side Kill Count Tracking
require "PlayerTitleHandler"  -- access title levels (1=VIP,2=VVIP,3=MVP)

ZM_KillCountClient = ZM_KillCountClient or {}

-- Configurable kill bonuses granted by title (these are artificial baseline kills to subtract)
ZM_KillCountClient.TitleKillBonus = ZM_KillCountClient.TitleKillBonus or {
    [1] = 4001,   -- VIP
    [2] = 8001,   -- VVIP
    [3] = 8001    -- MVP
}

-- Helper: get adjusted (real) kills excluding title bonus
function ZM_KillCountClient.getAdjustedKills()
    local player = getPlayer()
    if not player then return 0, 0, 0 end
    local raw = player:getZombieKills() or 0
    local titleLevel = 0
    if PlayerTitleHandler and PlayerTitleHandler.getPlayerTitle then
        titleLevel = tonumber(PlayerTitleHandler.getPlayerTitle(player)) or 0
    end
    local bonus = ZM_KillCountClient.TitleKillBonus[titleLevel] or 0
    local adjusted = raw - bonus
    if adjusted < 0 then adjusted = 0 end
    return adjusted, raw, bonus
end

-- Initialize the kill count system
function ZM_KillCountClient.init()
    local player = getPlayer()
    if not player then return end

    -- Initialize local kill count tracking
    if not player:getModData().ZM_KillCountTracking then
        player:getModData().ZM_KillCountTracking = {
            lastReportedKills = 0, -- adjusted kills last sent
            sessionKills = 0
        }
    end

    -- Report kills on player login to ensure data is up to date
    ZM_KillCountClient.reportKillCount()
end

-- Get current player kill count (raw, INCLUDING bonus). Prefer using getAdjustedKills() elsewhere.
function ZM_KillCountClient.getPlayerKills()
    local player = getPlayer()
    if not player then return 0 end
    return player:getZombieKills() or 0
end

-- Report kill count to server (adjusted, excluding VIP/VVIP/MVP bonus)
function ZM_KillCountClient.reportKillCount()
    local player = getPlayer()
    if not player then return end

    local adjustedKills, rawKills, bonus = ZM_KillCountClient.getAdjustedKills()
    local playerName = player:getUsername()

    if not playerName or playerName == "" then
        print("ZM_KillCountClient: Cannot report kills - no username")
        return
    end

    -- Send adjusted kill count to server
    sendClientCommand("ZM_KillCount", "reportKills", {
        username = playerName,
        killCount = adjustedKills,
        timestamp = getGameTime():getWorldAgeHours()
    })

    -- Update tracking data
    local modData = player:getModData().ZM_KillCountTracking
    if modData then
        modData.lastReportedKills = adjustedKills
    end

    print(string.format("ZM_KillCountClient: Reported %d adjusted kills (raw=%d, bonus=%d) for %s", adjustedKills, rawKills, bonus, playerName))
end

-- Handle server responses
function ZM_KillCountClient.onServerCommand(module, command, args)
    if module ~= "ZM_KillCount" then return end

    if command == "killCountUpdated" then
        -- Server confirmed kill count update
        print("ZM_KillCountClient: Kill count update confirmed by server")
    elseif command == "killCountData" then
        -- Received kill count data from server
        if args and args.killData then
            -- Store the data for UI display (already adjusted server values)
            ZM_KillCountClient.serverKillData = args.killData
            local playerCount = 0
            for _ in pairs(args.killData) do playerCount = playerCount + 1 end
            print("ZM_KillCountClient: DEBUG - Received kill count data from server, " .. playerCount .. " players")
        else
            print("ZM_KillCountClient: DEBUG - Received killCountData command but no data in args")
        end
    end
end

-- Request kill count data from server
function ZM_KillCountClient.requestKillCountData()
    print("ZM_KillCountClient: DEBUG - Requesting kill count data from server...")
    sendClientCommand("ZM_KillCount", "requestKillData", {})
    print("ZM_KillCountClient: DEBUG - Request sent to server")
end

-- Report kills when player is about to disconnect
function ZM_KillCountClient.onPlayerDisconnect()
    print("ZM_KillCountClient: Player disconnecting, reporting final kill count")
    ZM_KillCountClient.reportKillCount()
end

-- Report kills when player dies (to capture any kills before death)
-- function ZM_KillCountClient.onPlayerDeath(player)
--     if player == getPlayer() then
--         print("ZM_KillCountClient: Player died, reporting kill count")
--         ZM_KillCountClient.reportKillCount()
--     end
-- end

-- Periodic check every 10 minutes (more frequent than hourly)
function ZM_KillCountClient.periodicReport()
    ZM_KillCountClient.reportKillCount()
end

-- Event handlers
Events.OnCreatePlayer.Add(ZM_KillCountClient.init)
Events.EveryTenMinutes.Add(ZM_KillCountClient.periodicReport)  -- Report every 10 min
Events.OnServerCommand.Add(ZM_KillCountClient.onServerCommand)

print("ZM_KillCountClient: Client-side kill count tracking loaded (VIP bonus excluded, auto-save on disconnect/death)")