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

-- Load flags from .ini file
ZMServerwideFlagHandler.loadFlags = function()
    local flags = {}
    print("ZonaMerah: Attempting to load flags from " .. ZMServerwideFlagHandler.flagsFilePath)
    local file = getFileReader(ZMServerwideFlagHandler.flagsFilePath, true)

    if file then
        print("ZonaMerah: Successfully opened flag file")
        local line = file:readLine()
        local inServerFlagsSection = false

        while line do
            -- Trim whitespace
            line = line:gsub("^%s*(.-)%s*$", "%1")

            -- Skip empty lines and comments
            if line ~= "" and not line:match("^;") then
                -- Check for section headers
                local sectionName = line:match("^%[(.+)%]$")
                if sectionName then
                    print("ZonaMerah DEBUG: Found section: " .. sectionName)
                    inServerFlagsSection = (sectionName == "ServerFlags")
                elseif inServerFlagsSection then
                    -- Parse key=value pairs
                    local flagName, value = line:match("^([^=]+)=(.*)$")
                    if flagName and value then
                        flagName = flagName:gsub("^%s*(.-)%s*$", "%1")
                        value = value:gsub("^%s*(.-)%s*$", "%1")

                        -- Convert value to appropriate type
                        if value == "true" then
                            value = true
                        elseif value == "false" then
                            value = false
                        elseif tonumber(value) ~= nil then
                            value = tonumber(value)
                        end

                        flags[flagName] = value
                        print("ZonaMerah DEBUG: Loaded flag " .. flagName .. " = " .. tostring(value) ..
                              " (type: " .. type(value) .. ")")
                    end
                end
            end
            line = file:readLine()
        end
        file:close()
    else
        print("ZonaMerah WARNING: Could not open flag file at " .. ZMServerwideFlagHandler.flagsFilePath)
        print("ZonaMerah: Using default flags")
        flags = ZMServerwideFlagHandler.defaultFlags
    end

    -- Ensure all default flags exist
    for flagName, defaultValue in pairs(ZMServerwideFlagHandler.defaultFlags) do
        if flags[flagName] == nil then
            flags[flagName] = defaultValue
            print("ZonaMerah DEBUG: Using default value for " .. flagName .. " = " .. tostring(defaultValue))
        end
    end

    ZMServerwideFlagHandler.flags = flags

    -- Print all loaded flags
    print("ZonaMerah: All loaded flags:")
    for name, value in pairs(ZMServerwideFlagHandler.flags) do
        print("  " .. name .. " = " .. tostring(value) .. " (type: " .. type(value) .. ")")
    end

    return flags
end

-- Save flags to .ini file
ZMServerwideFlagHandler.saveFlags = function()
    local file = getFileWriter(ZMServerwideFlagHandler.flagsFilePath, true, false)  -- Added 'true' parameter
    if not file then
        print("ZonaMerah: ERROR - Could not open flag file for writing: " .. ZMServerwideFlagHandler.flagsFilePath)
        return false
    end

    -- Write header
    file:write("[ServerFlags]\n")

    -- Write each flag
    for flagName, value in pairs(ZMServerwideFlagHandler.flags) do
        file:write(flagName .. "=" .. tostring(value) .. "\n")
    end

    file:close()
    print("ZonaMerah: Saved serverwide flags to " .. ZMServerwideFlagHandler.flagsFilePath)
    return true
end

-- Get a flag value with auto-reload
ZMServerwideFlagHandler.getFlag = function(flagName)
    -- Reload flags from file every time to ensure fresh values
    ZMServerwideFlagHandler.loadFlags()

    local value = ZMServerwideFlagHandler.flags[flagName]
    print("ZonaMerah DEBUG: Getting flag " .. flagName .. ", value = " .. tostring(value) ..
          " (type: " .. type(value) .. ")")

    return value
end

-- Set a flag value with auto-reload
ZMServerwideFlagHandler.setFlag = function(flagName, value, saveImmediately)
    if not flagName then return false end

    -- Reload flags first to ensure we have the latest values
    ZMServerwideFlagHandler.loadFlags()

    -- Keep the original value type instead of converting to boolean
    local oldValue = ZMServerwideFlagHandler.flags[flagName]
    ZMServerwideFlagHandler.flags[flagName] = value

    print("ZonaMerah: Set flag " .. flagName .. " = " .. tostring(value) ..
          " (type: " .. type(value) .. ") (was " .. tostring(oldValue) .. ")")

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
local originalOnClientCommand = ZMServerwideFlagHandler.onClientCommand
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
    elseif command == "getFlagDirect" and args and args.flagName and args.requestId then
        local value = ZMServerwideFlagHandler.getFlag(args.flagName)

        print(fileExists("Lua/ZonaMerah_ServerFlags.ini"))
        print(fileExists("ZonaMerah_KillCounts.ini"))
        print("Direct flag request for " .. args.flagName .. ": " .. tostring(value))
        sendServerCommand(player, "ZMServerwideFlagHandler", "flagDirectResponse", {
            flagName = args.flagName,
            value = value,
            requestId = args.requestId
        })
    else
        -- Call original handler for other commands
        originalOnClientCommand(module, command, player, args)
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