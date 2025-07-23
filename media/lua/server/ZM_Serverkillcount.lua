ZMServerKillcountHandler = ZMServerKillcountHandler or {}
ZMServerKillcountHandler.killCounts = {}
ZMServerKillcountHandler.ravenCreekKillCounts = {}

-- Use separate file paths for each type of kill count
ZMServerKillcountHandler.generalKillCountsPath = "ZonaMerah_KillCounts.ini"
ZMServerKillcountHandler.ravenCreekKillCountsPath = "ZonaMerah_RavenCreekKillCounts.ini"

-- Initialize the server-side handler
ZMServerKillcountHandler.init = function()
    -- Load existing kill counts from files
    ZMServerKillcountHandler.loadGeneralKillCounts()
    ZMServerKillcountHandler.loadRavenCreekKillCounts()
    print("ZonaMerah: Initialized server kill count handler")
end

-- Save general kill counts to .ini file
ZMServerKillcountHandler.saveGeneralKillCounts = function()
    local file = getFileWriter(ZMServerKillcountHandler.generalKillCountsPath, false, false)
    if not file then
        print("ERROR: ZonaMerah: Failed to open general kill count file for writing")
        return
    end

    -- Write header
    file:write("[KillCounts]\n")

    -- Write each player's kill count
    for username, count in pairs(ZMServerKillcountHandler.killCounts) do
        file:write(username .. "=" .. tostring(count) .. "\n")
    end

    file:close()
    print("ZonaMerah: Saved general kill counts to " .. ZMServerKillcountHandler.generalKillCountsPath)
end

-- Save RavenCreek kill counts to .ini file
ZMServerKillcountHandler.saveRavenCreekKillCounts = function()
    local file = getFileWriter(ZMServerKillcountHandler.ravenCreekKillCountsPath, false, false)
    if not file then
        print("ERROR: ZonaMerah: Failed to open RavenCreek kill count file for writing")
        return
    end

    -- Write header
    file:write("[RavenCreekKillCounts]\n")

    -- Write each player's RavenCreek kill count
    for username, count in pairs(ZMServerKillcountHandler.ravenCreekKillCounts) do
        file:write(username .. "=" .. tostring(count) .. "\n")
    end

    file:close()
    print("ZonaMerah: Saved RavenCreek kill counts to " .. ZMServerKillcountHandler.ravenCreekKillCountsPath)
end

-- Load general kill counts from .ini file
ZMServerKillcountHandler.loadGeneralKillCounts = function()
    local counts = {}
    local file = getFileReader(ZMServerKillcountHandler.generalKillCountsPath, false)

    if file then
        local line = file:readLine()
        local inKillCountsSection = false

        while line do
            -- Check for section header
            if line == "[KillCounts]" then
                inKillCountsSection = true
            elseif line ~= "" and inKillCountsSection then
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
    print("ZonaMerah: Loaded general kill counts from " .. ZMServerKillcountHandler.generalKillCountsPath)
end

-- Load RavenCreek kill counts from .ini file
ZMServerKillcountHandler.loadRavenCreekKillCounts = function()
    local counts = {}
    local file = getFileReader(ZMServerKillcountHandler.ravenCreekKillCountsPath, false)

    if file then
        local line = file:readLine()
        local inRavenCreekSection = false

        while line do
            -- Check for section header
            if line == "[RavenCreekKillCounts]" then
                inRavenCreekSection = true
            elseif line ~= "" and inRavenCreekSection then
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

    ZMServerKillcountHandler.ravenCreekKillCounts = counts
    print("ZonaMerah: Loaded RavenCreek kill counts from " .. ZMServerKillcountHandler.ravenCreekKillCountsPath)
end

-- Update a player's kill counts
ZMServerKillcountHandler.updateKillCount = function(username, killCount, ravenCreekKillCount)
    if not username then return end

    local needsSave = false
    local needsRavenCreekSave = false

    if killCount then
        ZMServerKillcountHandler.killCounts[username] = killCount
        needsSave = true
    end

    if ravenCreekKillCount then
        ZMServerKillcountHandler.ravenCreekKillCounts[username] = ravenCreekKillCount
        needsRavenCreekSave = true
    end

    -- Only save the files that were updated
    if needsSave then
        ZMServerKillcountHandler.saveGeneralKillCounts()
    end

    if needsRavenCreekSave then
        ZMServerKillcountHandler.saveRavenCreekKillCounts()
    end

    print("ZonaMerah: Updated kill counts for " .. username)
end

-- Handle client commands
ZMServerKillcountHandler.onClientCommand = function(module, command, player, args)
    if module ~= "ZonaMerahCore" then return end

    if command == "sendKillCount" and args and args.username then
        ZMServerKillcountHandler.updateKillCount(args.username, args.killCount, args.ravenCreekKillCount)
    end
end

-- Save kill counts every hour
ZMServerKillcountHandler.onEveryHours = function()
    ZMServerKillcountHandler.saveGeneralKillCounts()
    ZMServerKillcountHandler.saveRavenCreekKillCounts()
end

-- Initialize and register event handlers
Events.OnServerStarted.Add(ZMServerKillcountHandler.init)
Events.OnClientCommand.Add(ZMServerKillcountHandler.onClientCommand)
-- Events.EveryHours.Add(ZMServerKillcountHandler.onEveryHours)