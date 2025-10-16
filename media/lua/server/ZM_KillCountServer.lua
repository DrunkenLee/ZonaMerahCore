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
                print("ZM_KillCountServer: Loaded kill count data from file")
            else
                ZM_KillCountServer.killCountData = {}
                print("ZM_KillCountServer: Kill count file corrupted or not a table, starting fresh")
            end
        else
            ZM_KillCountServer.killCountData = {}
            print("ZM_KillCountServer: Kill count file empty, starting fresh")
        end
    else
        ZM_KillCountServer.killCountData = {}
        print("ZM_KillCountServer: No existing kill count file found, starting fresh")
    end
end

-- Save kill count data to file
function ZM_KillCountServer.saveKillCountData()
    local fileWriter = getFileWriter(ZM_KillCountServer.KILLCOUNT_FILE, true, false)
    if fileWriter then
        local jsonString = ZM_KillCountServer.toJSON(ZM_KillCountServer.killCountData)
        fileWriter:write(jsonString)
        fileWriter:close()
        print("ZM_KillCountServer: Saved kill count data to file")
    else
        print("ZM_KillCountServer: ERROR - Could not open kill count file for writing")
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
        print("ZM_KillCountServer: Error parsing JSON, starting fresh")
        return {}
    end
end

-- Convert data to JSON string
function ZM_KillCountServer.toJSON(data)
    local jsonParts = {}
    if type(data) ~= "table" then
        print("ZM_KillCountServer: toJSON called with non-table, returning empty object")
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
        print("ZM_KillCountServer: Invalid username provided")
        return
    end

    if not ZM_KillCountServer.killCountData[username] then
        ZM_KillCountServer.killCountData[username] = {}
    end

    ZM_KillCountServer.killCountData[username].killCount = killCount or 0
    ZM_KillCountServer.killCountData[username].lastUpdated = getGameTime():getWorldAgeHours()
    ZM_KillCountServer.killCountData[username].timestamp = os.date("%Y-%m-%d %H:%M:%S")

    print("ZM_KillCountServer: Updated kill count for " .. username .. " to " .. killCount)

    -- Save to file
    ZM_KillCountServer.saveKillCountData()
end

-- Get kill count data for all players
function ZM_KillCountServer.getAllKillCountData()
    return ZM_KillCountServer.killCountData
end

-- Handle client commands
function ZM_KillCountServer.onClientCommand(module, command, player, args)
    if module ~= "ZM_KillCount" then return end

    if command == "reportKills" then
        if args and args.username and args.killCount then
            ZM_KillCountServer.updatePlayerKillCount(args.username, args.killCount, args.timestamp)
            -- Confirm to client
            sendServerCommand(player, "ZM_KillCount", "killCountUpdated", {})
        end
    elseif command == "requestKillData" then
        -- Send all kill count data to requesting client
        local killData = ZM_KillCountServer.getAllKillCountData()
        sendServerCommand(player, "ZM_KillCount", "killCountData", { killData = killData })
    end
end

-- Periodic save (every hour)
function ZM_KillCountServer.periodicSave()
    ZM_KillCountServer.saveKillCountData()
    print("ZM_KillCountServer: Periodic save completed")
end

-- Event handlers
Events.OnServerStarted.Add(ZM_KillCountServer.init)
Events.OnClientCommand.Add(ZM_KillCountServer.onClientCommand)
Events.EveryHours.Add(ZM_KillCountServer.periodicSave)

print("ZM_KillCountServer: Server-side kill count tracking loaded")