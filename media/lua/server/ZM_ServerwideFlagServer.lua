ZMServerwideFlagHandler = ZMServerwideFlagHandler or {}
ZMServerwideFlagHandler.flags = {}

-- File path for storing serverwide flags
ZMServerwideFlagHandler.flagsFilePath = "ZonaMerah_ServerFlags.ini"

-- Default flags that will be created if file doesn't exist
ZMServerwideFlagHandler.defaultFlags = {
    supplyRunAvailableFlag = 0,
    expeditionRunAvailableFlag = 0,
    eventActiveFlag = 0,
    maintenanceModeFlag = 0,
    specialEventFlag = 0,
    pvpEnabledFlag = 0,
    tradingEnabledFlag = 1,
    questSystemEnabledFlag = 1,
    serverMessage = "Welcome to ZonaMerah",
    eventDescription = ""
}

-- Initialize the server-side flag handler
ZMServerwideFlagHandler.init = function()
    ZMServerwideFlagHandler.loadFlags()
    print("ZonaMerah: Initialized serverwide flag handler")

    -- Send initial flags to all connected players
    ZMServerwideFlagHandler.broadcastAllFlags()
end

-- Save flags to .ini file
ZMServerwideFlagHandler.saveFlags = function()
    local file = getFileWriter(ZMServerwideFlagHandler.flagsFilePath, false, false)
    if not file then
        print("ERROR: ZonaMerah: Failed to open serverwide flags file for writing")
        return false
    end

    -- Write header
    file:write("[ServerFlags]\n")

    -- Write each flag
    for flagName, value in pairs(ZMServerwideFlagHandler.flags) do
        if type(value) == "string" then
            -- Escape quotes and wrap in quotes for strings
            local escapedValue = string.gsub(tostring(value), '"', '\\"')
            file:write(flagName .. '="' .. escapedValue .. '"\n')
        else
            file:write(flagName .. "=" .. tostring(value) .. "\n")
        end
    end

    file:close()
    print("ZonaMerah: Saved serverwide flags to " .. ZMServerwideFlagHandler.flagsFilePath)
    return true
end

-- Load flags from .ini file
ZMServerwideFlagHandler.loadFlags = function()
    local flags = {}
    local file = getFileReader(ZMServerwideFlagHandler.flagsFilePath, false)

    if file then
        local line = file:readLine()
        local inFlagsSection = false

        while line do
            -- Check for section header
            if line == "[ServerFlags]" then
                inFlagsSection = true
            elseif line ~= "" and inFlagsSection and not line:match("^%s*;") then -- Skip comments
                -- Parse flagName=value line (support both quoted strings and numbers)
                local flagName, quotedValue = line:match('(.+)="(.*)"')
                if flagName and quotedValue then
                    -- String value (quoted)
                    local unescapedValue = string.gsub(quotedValue, '\\"', '"')
                    flags[flagName] = unescapedValue
                else
                    -- Try numeric value
                    local flagName2, numValue = line:match("(.+)=(%d+)")
                    if flagName2 and numValue then
                        flags[flagName2] = tonumber(numValue)
                    else
                        -- Try boolean or other unquoted string
                        local flagName3, anyValue = line:match("(.+)=(.*)")
                        if flagName3 and anyValue then
                            -- Try to convert to number first, then keep as string
                            local numVal = tonumber(anyValue)
                            if numVal then
                                flags[flagName3] = numVal
                            else
                                flags[flagName3] = anyValue
                            end
                        end
                    end
                end
            end
            line = file:readLine()
        end
        file:close()
        print("ZonaMerah: Loaded serverwide flags from " .. ZMServerwideFlagHandler.flagsFilePath)
    else
        print("ZonaMerah: Serverwide flags file not found, creating with defaults")
        flags = ZMServerwideFlagHandler.defaultFlags
    end

    -- Ensure all default flags exist
    for flagName, defaultValue in pairs(ZMServerwideFlagHandler.defaultFlags) do
        if flags[flagName] == nil then
            flags[flagName] = defaultValue
            print("ZonaMerah: Added missing flag: " .. flagName .. " = " .. defaultValue)
        end
    end

    ZMServerwideFlagHandler.flags = flags

    -- Save to ensure file exists with all flags
    ZMServerwideFlagHandler.saveFlags()
end

-- Get a flag value
ZMServerwideFlagHandler.getFlag = function(flagName)
    return ZMServerwideFlagHandler.flags[flagName]
end

-- Set a flag value
ZMServerwideFlagHandler.setFlag = function(flagName, value, saveImmediately)
    if not flagName then return false end

    -- Keep the original value type instead of converting to boolean
    local oldValue = ZMServerwideFlagHandler.flags[flagName]
    ZMServerwideFlagHandler.flags[flagName] = value

    print("ZonaMerah: Set flag " .. flagName .. " = " .. tostring(value) .. " (type: " .. type(value) .. ") (was " .. tostring(oldValue) .. ")")

    if saveImmediately ~= false then
        ZMServerwideFlagHandler.saveFlags()
    end

    ZMServerwideFlagHandler.broadcastFlag(flagName, value)

    return true
end

-- Get flag with default value
ZMServerwideFlagHandler.getFlagWithDefault = function(flagName, defaultValue)
    local value = ZMServerwideFlagHandler.flags[flagName]
    return value ~= nil and value or defaultValue
end

-- Get flag as boolean
ZMServerwideFlagHandler.getFlagBool = function(flagName)
    local value = ZMServerwideFlagHandler.getFlag(flagName)
    if type(value) == "number" then
        return value == 1
    elseif type(value) == "string" then
        return string.lower(value) == "true" or value == "1"
    elseif type(value) == "boolean" then
        return value
    end
    return false
end

-- Get flag as string
ZMServerwideFlagHandler.getFlagString = function(flagName, defaultValue)
    local value = ZMServerwideFlagHandler.getFlag(flagName)
    if value ~= nil then
        return tostring(value)
    end
    return defaultValue or ""
end

-- Get flag as number
ZMServerwideFlagHandler.getFlagNumber = function(flagName, defaultValue)
    local value = ZMServerwideFlagHandler.getFlag(flagName)
    if type(value) == "number" then
        return value
    elseif type(value) == "string" then
        return tonumber(value) or (defaultValue or 0)
    end
    return defaultValue or 0
end

ZMServerwideFlagHandler.toggleFlag = function(flagName, saveImmediately)
    local currentValue = ZMServerwideFlagHandler.getFlag(flagName)
    local newValue

    -- Handle different data types for toggling
    if type(currentValue) == "number" then
        newValue = (currentValue == 0) and 1 or 0
    elseif type(currentValue) == "string" then
        local boolValue = ZMServerwideFlagHandler.getFlagBool(flagName)
        newValue = boolValue and 0 or 1
    elseif type(currentValue) == "boolean" then
        newValue = not currentValue
    else
        newValue = 1 -- Default to 1 if flag doesn't exist
    end

    return ZMServerwideFlagHandler.setFlag(flagName, newValue, saveImmediately)
end


ZMServerwideFlagHandler.getAllFlags = function()
    return ZMServerwideFlagHandler.flags
end


ZMServerwideFlagHandler.broadcastFlag = function(flagName, value)
    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            sendServerCommand(player, "ZMServerwideFlagHandler", "updateFlag", {
                flagName = flagName,
                value = value
            })
        end
    end
end


ZMServerwideFlagHandler.broadcastAllFlags = function(specificPlayer)
    local flagData = {
        flags = ZMServerwideFlagHandler.flags
    }

    if specificPlayer then
        sendServerCommand(specificPlayer, "ZMServerwideFlagHandler", "updateAllFlags", flagData)
    else
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player then
                sendServerCommand(player, "ZMServerwideFlagHandler", "updateAllFlags", flagData)
            end
        end
    end
end

-- Handle client commands
ZMServerwideFlagHandler.onClientCommand = function(module, command, player, args)
    if module ~= "ZMServerwideFlagHandler" then return end

    if command == "requestFlags" then
        ZMServerwideFlagHandler.broadcastAllFlags(player)

    elseif command == "setFlag" and args and args.flagName then
        ZMServerwideFlagHandler.setFlag(args.flagName, args.value, true)

    elseif command == "getFlag" and args and args.flagName then
        local value = ZMServerwideFlagHandler.getFlag(args.flagName)
        sendServerCommand(player, "ZMServerwideFlagHandler", "flagValue", {
            flagName = args.flagName,
            value = value
        })
    end
end

ZMServerwideFlagHandler.onPlayerConnect = function(player)
    ZMServerwideFlagHandler.broadcastAllFlags(player)
end

ZMServerwideFlagHandler.consoleSetFlag = function(flagName, value)
    if not flagName then
        print("Usage: ZMServerwideFlagHandler.consoleSetFlag('flagName', value)")
        return
    end
    return ZMServerwideFlagHandler.setFlag(flagName, value, true)
end

ZMServerwideFlagHandler.consoleGetFlag = function(flagName)
    if not flagName then
        print("Usage: ZMServerwideFlagHandler.consoleGetFlag('flagName')")
        return
    end
    local value = ZMServerwideFlagHandler.getFlag(flagName)
    print("Flag " .. flagName .. " = " .. tostring(value) .. " (type: " .. type(value) .. ")")
    return value
end

ZMServerwideFlagHandler.consoleToggleFlag = function(flagName)
    if not flagName then
        print("Usage: ZMServerwideFlagHandler.consoleToggleFlag('flagName')")
        return
    end
    return ZMServerwideFlagHandler.toggleFlag(flagName, true)
end

ZMServerwideFlagHandler.consoleListFlags = function()
    print("=== Serverwide Flags ===")
    for flagName, value in pairs(ZMServerwideFlagHandler.flags) do
        print(flagName .. " = " .. tostring(value) .. " (type: " .. type(value) .. ")")
    end
    print("========================")
end

-- Initialize and register event handlers
Events.OnServerStarted.Add(ZMServerwideFlagHandler.init)
Events.OnClientCommand.Add(ZMServerwideFlagHandler.onClientCommand)

return ZMServerwideFlagHandler