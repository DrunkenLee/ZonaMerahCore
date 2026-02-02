-- ZM_KillCountClient.lua - Client-side Kill Count Tracking (READ-ONLY)
-- This client now only displays data from server's HordeKillLeaderboard.txt
-- No local kill tracking or reporting is performed

ZM_KillCountClient = ZM_KillCountClient or {}

-- Initialize the kill count system
function ZM_KillCountClient.init()
    local player = getPlayer()
    if not player then return end

    print("ZM_KillCountClient: Client initialized (read-only mode)")
end

-- Handle server responses
function ZM_KillCountClient.onServerCommand(module, command, args)
    if module ~= "ZM_KillCount" then return end

    if command == "killCountData" then
        -- Received kill count data from server (read from HordeKillLeaderboard.txt)
        if args and args.killData then
            -- Store the data for UI display
            ZM_KillCountClient.serverKillData = args.killData
            local playerCount = 0
            for _ in pairs(args.killData) do playerCount = playerCount + 1 end
            print("ZM_KillCountClient: Received kill count data from server, " .. playerCount .. " players")
        else
            print("ZM_KillCountClient: Received killCountData command but no data in args")
        end
    end
end

-- Request kill count data from server
function ZM_KillCountClient.requestKillCountData()
    print("ZM_KillCountClient: Requesting kill count data from server...")
    sendClientCommand("ZM_KillCount", "requestKillData", {})
    print("ZM_KillCountClient: Request sent to server")
end

-- Event handlers
Events.OnCreatePlayer.Add(ZM_KillCountClient.init)
Events.OnServerCommand.Add(ZM_KillCountClient.onServerCommand)

print("ZM_KillCountClient: Client-side kill count tracking loaded (READ-ONLY from server's HordeKillLeaderboard.txt)")