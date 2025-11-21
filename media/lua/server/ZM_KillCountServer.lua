-- ZM_KillCountServer.lua - Server-side Kill Count Storage
ZM_KillCountServer = ZM_KillCountServer or {}

-- File path for kill count data
ZM_KillCountServer.KILLCOUNT_FILE = "killcount.json"

-- Initialize the kill count system
function ZM_KillCountServer.init()
    print("ZM_KillCountServer: Initializing kill count tracking system")
    ZM_KillCountServer.killCountData = {}
    ZM_KillCountServer.loadKillCountData()
end

-- Load kill count data from file
function ZM_KillCountServer.loadKillCountData()
    local fileReader = getFileReader(ZM_KillCountServer.KILLCOUNT_FILE, false)
    if fileReader then
        local content = ""
        local line = fileReader:readLine()
        while line do
            content = content .. line
            line = fileReader:readLine()
        end
        fileReader:close()

        if content and content ~= "" then
            local parsed = ZM_KillCountServer.parseJSON(content)
            if type(parsed) == "table" then
                ZM_KillCountServer.killCountData = parsed
                local playerCount = 0
                for username, data in pairs(parsed) do
                    playerCount = playerCount + 1
                    --print(string.format("  - Loaded: %s with %d kills", username, data.killCount or 0))
                end
                --print(string.format("ZM_KillCountServer: Loaded kill count data from file (%d players)", playerCount))
            else
                ZM_KillCountServer.killCountData = {}
                --print("ZM_KillCountServer: Kill count file corrupted or not a table, starting fresh")
            end
        else
            ZM_KillCountServer.killCountData = {}
            --print("ZM_KillCountServer: Kill count file empty, starting fresh")
        end
    else
        ZM_KillCountServer.killCountData = {}
        --print("ZM_KillCountServer: No existing kill count file found, starting fresh")
    end
end

-- Save kill count data to file
function ZM_KillCountServer.saveKillCountData()
    -- Ensure killCountData is initialized
    if type(ZM_KillCountServer.killCountData) ~= "table" then
        --print("ZM_KillCountServer: ERROR - killCountData is not a table, initializing")
        ZM_KillCountServer.killCountData = {}
    end

    -- Merge current in-memory data with file data to preserve offline players
    local fileData = ZM_KillCountServer.getAllKillCountDataFromFile()

    -- Ensure fileData is a valid table
    if type(fileData) ~= "table" then
        --print("ZM_KillCountServer: WARNING - fileData is not a table, using empty table")
        fileData = {}
    end

    -- Merge: file data first, then overlay in-memory updates
    local mergedData = {}

    -- Start with file data (includes offline players)
    for username, data in pairs(fileData) do
        if type(data) == "table" then
            mergedData[username] = data
        end
    end

    -- Overlay in-memory data (online players with fresh updates)
    for username, data in pairs(ZM_KillCountServer.killCountData) do
        if type(data) == "table" then
            mergedData[username] = data
        end
    end    -- Create backup before saving
    local backupFile = ZM_KillCountServer.KILLCOUNT_FILE .. ".backup"
    local originalReader = getFileReader(ZM_KillCountServer.KILLCOUNT_FILE, false)
    if originalReader then
        local backupWriter = getFileWriter(backupFile, true, false)
        if backupWriter then
            local line = originalReader:readLine()
            while line do
                backupWriter:write(line)
                line = originalReader:readLine()
            end
            backupWriter:close()
            --print("ZM_KillCountServer: Created backup of kill count data")
        end
        originalReader:close()
    end

    -- Count players before save
    local playerCount = 0
    for _ in pairs(mergedData) do
        playerCount = playerCount + 1
    end

    local fileWriter = getFileWriter(ZM_KillCountServer.KILLCOUNT_FILE, true, false)
    if fileWriter then
        local jsonString = ZM_KillCountServer.toJSON(mergedData)
        fileWriter:write(jsonString)
        fileWriter:close()
        --print(string.format("ZM_KillCountServer: Saved kill count data to file (%d players, including offline)", playerCount))
    else
        --print("ZM_KillCountServer: ERROR - Could not open kill count file for writing")
    end
end

-- Basic JSON parsing (for simple data structures)
function ZM_KillCountServer.parseJSON(jsonString)
    local data = {}

    -- Handle empty or invalid input
    if not jsonString or jsonString == "" or jsonString == "{}" then
        return data
    end

    -- Try to parse manually
    local success, result = pcall(function()
        -- Remove outer braces and whitespace
        local content = jsonString:gsub("^%s*{%s*", ""):gsub("%s*}%s*$", "")

        if content == "" then return {} end

        -- Split by commas that are not inside quotes or braces
        local entries = {}
        local current = ""
        local inQuotes = false
        local braceCount = 0

        for i = 1, #content do
            local char = content:sub(i, i)
            if char == '"' and (i == 1 or content:sub(i-1, i-1) ~= '\\') then
                inQuotes = not inQuotes
            elseif not inQuotes then
                if char == '{' then
                    braceCount = braceCount + 1
                elseif char == '}' then
                    braceCount = braceCount - 1
                elseif char == ',' and braceCount == 0 then
                    table.insert(entries, current)
                    current = ""
                else
                    current = current .. char
                end
            else
                current = current .. char
            end
        end

        if current ~= "" then
            table.insert(entries, current)
        end

        -- Parse each entry
        for _, entry in ipairs(entries) do
            local key, value = entry:match('"([^"]+)"%s*:%s*{([^}]+)}')
            if key and value then
                data[key] = {}
                -- Parse the inner object
                for subEntry in value:gmatch('([^,]+)') do
                    local subKey, subValue = subEntry:match('"([^"]+)"%s*:%s*([^,]+)')
                    if subKey and subValue then
                        -- Remove quotes from string values
                        subValue = subValue:gsub('^"', ''):gsub('"$', '')
                        -- Try to convert to number if possible
                        local numValue = tonumber(subValue)
                        data[key][subKey] = numValue or subValue
                    end
                end
            end
        end

        return data
    end)

    if success then
        return result
    else
        --print("ZM_KillCountServer: Error parsing JSON, starting fresh")
        return {}
    end
end

-- Convert data to JSON string
function ZM_KillCountServer.toJSON(data)
    local jsonParts = {}
    if type(data) ~= "table" then
        --print("ZM_KillCountServer: toJSON called with non-table, returning empty object")
        return "{}"
    end
    for username, playerData in pairs(data) do
        local playerJson = string.format('"%s":{"killCount":%d,"lastUpdated":%d,"timestamp":"%s"}',
            username,
            playerData.killCount or 0,
            playerData.lastUpdated or 0,
            playerData.timestamp or ""
        )
        table.insert(jsonParts, playerJson)
    end
    return "{" .. table.concat(jsonParts, ",") .. "}"
end

-- Update player kill count
function ZM_KillCountServer.updatePlayerKillCount(username, killCount, timestamp)
    if not username or username == "" then
        --print("ZM_KillCountServer: Invalid username provided")
        return
    end

    -- Ensure killCountData is initialized
    if type(ZM_KillCountServer.killCountData) ~= "table" then
        --print("ZM_KillCountServer: ERROR - killCountData is not a table, initializing")
        ZM_KillCountServer.killCountData = {}
    end

    -- Ensure we have the latest data from file (merge offline players)
    -- This prevents data loss if server was restarted
    if not ZM_KillCountServer.killCountData[username] then
        -- Check if player exists in file but not in memory
        local fileData = ZM_KillCountServer.getAllKillCountDataFromFile()
        if type(fileData) == "table" and fileData[username] then
            ZM_KillCountServer.killCountData[username] = fileData[username]
            --print(string.format("ZM_KillCountServer: Restored player %s from file", username))
        end
    end

    -- Count players before update
    local playerCountBefore = 0
    for _ in pairs(ZM_KillCountServer.killCountData) do
        playerCountBefore = playerCountBefore + 1
    end

    if not ZM_KillCountServer.killCountData[username] then
        ZM_KillCountServer.killCountData[username] = {}
        --print(string.format("ZM_KillCountServer: Adding NEW player %s (total players: %d -> %d)", username, playerCountBefore, playerCountBefore + 1))
    else
        local oldKills = ZM_KillCountServer.killCountData[username].killCount or 0
        --print(string.format("ZM_KillCountServer: Updating EXISTING player %s (%d -> %d kills)", username, oldKills, killCount))
    end

    ZM_KillCountServer.killCountData[username].killCount = killCount or 0
    ZM_KillCountServer.killCountData[username].lastUpdated = getGameTime():getWorldAgeHours()
    ZM_KillCountServer.killCountData[username].timestamp = os.date("%Y-%m-%d %H:%M:%S")

    -- Count players after update
    local playerCountAfter = 0
    for _ in pairs(ZM_KillCountServer.killCountData) do
        playerCountAfter = playerCountAfter + 1
    end

    --print(string.format("ZM_KillCountServer: Updated %s to %d kills (total players: %d)", username, killCount, playerCountAfter))

    -- Save to file
    ZM_KillCountServer.saveKillCountData()
end

-- Get kill count data for all players (in-memory)
function ZM_KillCountServer.getAllKillCountData()
    return ZM_KillCountServer.killCountData
end

-- Get kill count data directly from file (includes offline players)
function ZM_KillCountServer.getAllKillCountDataFromFile()
    local fileReader = getFileReader(ZM_KillCountServer.KILLCOUNT_FILE, false)
    if fileReader then
        local content = ""
        local line = fileReader:readLine()
        while line do
            content = content .. line
            line = fileReader:readLine()
        end
        fileReader:close()

        --print("ZM_KillCountServer: DEBUG - File content length: " .. #content)

        if content and content ~= "" then
            --print("ZM_KillCountServer: DEBUG - File content: " .. content)
            local parsed = ZM_KillCountServer.parseJSON(content)
            if type(parsed) == "table" then
                local playerCount = 0
                for username, data in pairs(parsed) do
                    playerCount = playerCount + 1
                    print(string.format("ZM_KillCountServer: DEBUG - Parsed from file: %s = %d kills", username, data.killCount or 0))
                end
                -- print(string.format("ZM_KillCountServer: Loaded %d players from file for UI display", playerCount))
                return parsed
            else
                -- print("ZM_KillCountServer: DEBUG - parseJSON did not return a table, type: " .. type(parsed))
            end
        else
            -- print("ZM_KillCountServer: DEBUG - File content is empty or nil")
        end
    else
        -- print("ZM_KillCountServer: DEBUG - Could not open file for reading")
    end

    -- Fallback to in-memory data if file read fails, ensure it's a valid table
    --print("ZM_KillCountServer: Could not read from file, using in-memory data")
    if type(ZM_KillCountServer.killCountData) == "table" then
        local inMemCount = 0
        for _ in pairs(ZM_KillCountServer.killCountData) do
            inMemCount = inMemCount + 1
        end
        --print("ZM_KillCountServer: DEBUG - Returning in-memory data with " .. inMemCount .. " players")
        return ZM_KillCountServer.killCountData
    else
        --print("ZM_KillCountServer: WARNING - In-memory data is not a table, returning empty table")
        return {}
    end
end-- Handle client commands
function ZM_KillCountServer.onClientCommand(module, command, player, args)
    --print(string.format("ZM_KillCountServer: DEBUG - Received command: module='%s', command='%s'", tostring(module), tostring(command)))

    if module ~= "ZM_KillCount" then return end

    if command == "reportKills" then
        --print("ZM_KillCountServer: DEBUG - Processing reportKills command")
        if args and args.username and args.killCount then
            ZM_KillCountServer.updatePlayerKillCount(args.username, args.killCount, args.timestamp)
            -- Confirm to client
            sendServerCommand(player, "ZM_KillCount", "killCountUpdated", {})
        end
    elseif command == "requestKillData" then
        --print("ZM_KillCountServer: DEBUG - Processing requestKillData command")

        -- TEMPORARY FIX: Send in-memory data directly (file reading has issues)
        -- Will fix file reading separately
        local killData = ZM_KillCountServer.killCountData or {}

        local playerCount = 0
        for username, data in pairs(killData) do
            playerCount = playerCount + 1
            --print(string.format("ZM_KillCountServer: DEBUG - Preparing to send: %s = %d kills", username, data.killCount or 0))
        end
        --print(string.format("ZM_KillCountServer: Sending %d player records to client", playerCount))
        sendServerCommand(player, "ZM_KillCount", "killCountData", { killData = killData })
        --print("ZM_KillCountServer: DEBUG - sendServerCommand completed")
    end
end

-- Periodic save (every 10 minutes for safety)
function ZM_KillCountServer.periodicSave()
    ZM_KillCountServer.saveKillCountData()
    --print("ZM_KillCountServer: Periodic save completed")
end

-- Save data when player disconnects
function ZM_KillCountServer.onPlayerDisconnect(player)
    if player then
        local username = player:getUsername()
        --print("ZM_KillCountServer: Player " .. (username or "Unknown") .. " disconnecting, saving data")
        ZM_KillCountServer.saveKillCountData()
    end
end

-- Save data when server shuts down
function ZM_KillCountServer.onServerShutdown()
    --print("ZM_KillCountServer: Server shutting down, saving all data")
    ZM_KillCountServer.saveKillCountData()
end

-- Event handlers
Events.OnServerStarted.Add(ZM_KillCountServer.init)
Events.OnClientCommand.Add(ZM_KillCountServer.onClientCommand)
Events.EveryTenMinutes.Add(ZM_KillCountServer.periodicSave)      -- Save every 10 min
-- Events.OnPlayerDisconnect.Add(ZM_KillCountServer.onPlayerDisconnect) -- Save on disconnect
-- Events.OnServerShutdown.Add(ZM_KillCountServer.onServerShutdown)     -- Save on shutdown

--print("ZM_KillCountServer: Server-side kill count tracking loaded (auto-save on disconnect/shutdown)")