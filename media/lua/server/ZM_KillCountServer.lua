-- ZM_KillCountServer.lua - Server-side Kill Count Storage
ZM_KillCountServer = ZM_KillCountServer or {}

-- File path for kill count data (tab-delimited leaderboard file)
ZM_KillCountServer.KILLCOUNT_FILE = "ZMLogs/HordeKillLeaderboard.txt"

-- Initialize the kill count system
function ZM_KillCountServer.init()
    print("ZM_KillCountServer: Initializing kill count tracking system")
    ZM_KillCountServer.killCountData = {}
    ZM_KillCountServer.loadKillCountData()
end

-- Load kill count data from HordeKillLeaderboard.txt (tab-delimited format)
function ZM_KillCountServer.loadKillCountData()
    local fileReader = getFileReader(ZM_KillCountServer.KILLCOUNT_FILE, false)
    if fileReader then
        ZM_KillCountServer.killCountData = {}

        -- Skip header line (Rank	Player	SteamID	AllTimeKills)
        local headerLine = fileReader:readLine()

        local playerCount = 0
        local line = fileReader:readLine()

        while line do
            -- Parse tab-delimited format: Rank	Player	SteamID	AllTimeKills
            local rank, playerName, steamID, killCount = line:match("^(%d+)\t([^\t]+)\t([^\t]+)\t(%d+)$")

            if playerName and killCount then
                ZM_KillCountServer.killCountData[playerName] = {
                    killCount = tonumber(killCount) or 0,
                    steamID = steamID,
                    rank = tonumber(rank) or 0,
                    lastUpdated = getGameTime():getWorldAgeHours(),
                    timestamp = os.date("%Y-%m-%d %H:%M:%S")
                }
                playerCount = playerCount + 1
            end

            line = fileReader:readLine()
        end
        fileReader:close()

        print(string.format("ZM_KillCountServer: Loaded %d players from HordeKillLeaderboard.txt", playerCount))
    else
        ZM_KillCountServer.killCountData = {}
        print("ZM_KillCountServer: Could not open HordeKillLeaderboard.txt, starting with empty data")
    end
end

-- Reload data from file (can be called periodically to refresh from updated leaderboard)
function ZM_KillCountServer.reloadKillCountData()
    print("ZM_KillCountServer: Reloading kill count data from HordeKillLeaderboard.txt")
    ZM_KillCountServer.loadKillCountData()
end

-- Get kill count data for all players (read-only from leaderboard file)
function ZM_KillCountServer.getAllKillCountData()
    -- Ensure data is a valid table
    if type(ZM_KillCountServer.killCountData) ~= "table" then
        return {}
    end
    return ZM_KillCountServer.killCountData
end-- Handle client commands
function ZM_KillCountServer.onClientCommand(module, command, player, args)
    if module ~= "ZM_KillCount" then return end

    if command == "requestKillData" then
        print("ZM_KillCountServer: Client requested kill data, reloading from file...")

        -- Reload fresh data from HordeKillLeaderboard.txt
        ZM_KillCountServer.reloadKillCountData()

        local killData = ZM_KillCountServer.getAllKillCountData()

        local playerCount = 0
        for _ in pairs(killData) do
            playerCount = playerCount + 1
        end

        print(string.format("ZM_KillCountServer: Sending %d player records to client", playerCount))
        sendServerCommand(player, "ZM_KillCount", "killCountData", { killData = killData })
    end
end

-- Periodic reload (every 10 minutes to get fresh leaderboard data)
function ZM_KillCountServer.periodicReload()
    ZM_KillCountServer.reloadKillCountData()
    print("ZM_KillCountServer: Periodic reload completed")
end

-- Event handlers
Events.OnServerStarted.Add(ZM_KillCountServer.init)
Events.OnClientCommand.Add(ZM_KillCountServer.onClientCommand)
Events.EveryTenMinutes.Add(ZM_KillCountServer.periodicReload)  -- Reload every 10 min to get fresh data

print("ZM_KillCountServer: Server-side kill count tracking loaded (READ-ONLY from ZMLogs/HordeKillLeaderboard.txt)")