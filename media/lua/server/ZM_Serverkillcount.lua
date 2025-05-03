ZMServerKillcountHandler = ZMServerKillcountHandler or {}
ZMServerKillcountHandler.killCounts = {}
ZMServerKillcountHandler.iniFilePath = "ZonaMerah_KillCounts.ini"

-- Initialize the server-side handler
ZMServerKillcountHandler.init = function()
    -- Load existing kill counts from file
    ZMServerKillcountHandler.loadKillCounts()
    print("ZonaMerah: Initialized server kill count handler")
end

-- Save kill counts to .ini file
ZMServerKillcountHandler.saveKillCounts = function()
    local file = getFileWriter(ZMServerKillcountHandler.iniFilePath, true, false)
    if not file then
        print("ERROR: ZonaMerah: Failed to open kill count file for writing")
        return
    end

    -- Write header
    file:write("[KillCounts]\n")

    -- Write each player's kill count
    for username, count in pairs(ZMServerKillcountHandler.killCounts) do
        file:write(username .. "=" .. tostring(count) .. "\n")
    end

    file:close()
    print("ZonaMerah: Saved kill counts to " .. ZMServerKillcountHandler.iniFilePath)
end

-- Load kill counts from .ini file
ZMServerKillcountHandler.loadKillCounts = function()
    local counts = {}
    local file = getFileReader(ZMServerKillcountHandler.iniFilePath, false)

    if file then
        local line = file:readLine()
        local inKillCountsSection = false

        while line do
            -- Check for section header
            if line == "[KillCounts]" then
                inKillCountsSection = true
            elseif inKillCountsSection and line ~= "" then
                -- Parse username=count line
                local username, count = line:match("(.+)=(%d+)")
                if username and count then
                    counts[username] = tonumber(count)
                end
            end
            line = file:readLine()
        end
        file:close()
    end

    ZMServerKillcountHandler.killCounts = counts
    print("ZonaMerah: Loaded kill counts from " .. ZMServerKillcountHandler.iniFilePath)
end

-- Update a player's kill count
ZMServerKillcountHandler.updateKillCount = function(username, killCount)
    if not username or not killCount then return end

    ZMServerKillcountHandler.killCounts[username] = killCount
    print("ZonaMerah: Updated kill count for " .. username .. " to " .. tostring(killCount))
end

-- Handle client commands
ZMServerKillcountHandler.onClientCommand = function(module, command, player, args)
    if module ~= "ZonaMerahCore" then return end

    if command == "sendKillCount" and args and args.username and args.killCount then
        ZMServerKillcountHandler.updateKillCount(args.username, args.killCount)
    end
end

-- Save kill counts every hour
ZMServerKillcountHandler.onEveryHours = function()
    ZMServerKillcountHandler.saveKillCounts()
end

-- Initialize and register event handlers
Events.OnServerStarted.Add(ZMServerKillcountHandler.init)
Events.OnClientCommand.Add(ZMServerKillcountHandler.onClientCommand)
Events.EveryHours.Add(ZMServerKillcountHandler.onEveryHours)