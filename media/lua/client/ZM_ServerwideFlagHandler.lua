ZMServerwideFlagHandler = ZMServerwideFlagHandler or {}
ZMServerwideFlagHandler.flags = {}

-- Initialize client-side handler
ZMServerwideFlagHandler.init = function()
    -- Request flags from server
    ZMServerwideFlagHandler.requestFlags()
    print("ZonaMerah: Initialized client-side serverwide flag handler")
end

-- Request all flags from server
ZMServerwideFlagHandler.requestFlags = function()
    sendClientCommand("ZMServerwideFlagHandler", "requestFlags", {})
end

-- Get a flag value (client-side cache)
ZMServerwideFlagHandler.getFlag = function(flagName)
    return ZMServerwideFlagHandler.flags[flagName]
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

-- Get flag with default value
ZMServerwideFlagHandler.getFlagWithDefault = function(flagName, defaultValue)
    local value = ZMServerwideFlagHandler.flags[flagName]
    return value ~= nil and value or defaultValue
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

-- Check if flag exists
ZMServerwideFlagHandler.hasFlag = function(flagName)
    return ZMServerwideFlagHandler.flags[flagName] ~= nil
end

-- Get all flags
ZMServerwideFlagHandler.getAllFlags = function()
    return ZMServerwideFlagHandler.flags
end

-- Set flag (admin only - sends to server)
ZMServerwideFlagHandler.setFlag = function(flagName, value)
    if not flagName then return false end
    print('ZonaMerah: Setting flag ' .. flagName .. ' to ' .. tostring(value))
    sendClientCommand("ZMServerwideFlagHandler", "setFlag", {
        flagName = flagName,
        value = value
    })
    return true
end

ZMServerwideFlagHandler.toggleFlag = function(flagName)
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

    return ZMServerwideFlagHandler.setFlag(flagName, newValue)
end

-- Request specific flag from server
ZMServerwideFlagHandler.requestFlag = function(flagName)
    sendClientCommand("ZMServerwideFlagHandler", "getFlag", {
        flagName = flagName
    })
end

-- Add these properties to track pending callbacks
ZMServerwideFlagHandler.pendingCallbacks = {}
ZMServerwideFlagHandler.requestId = 0

-- Direct on-demand flag request (no caching)
ZMServerwideFlagHandler.requestFlagDirect = function(flagName, callback)
    -- Generate unique request ID
    ZMServerwideFlagHandler.requestId = ZMServerwideFlagHandler.requestId + 1
    local requestId = ZMServerwideFlagHandler.requestId

    -- Store callback with request ID
    ZMServerwideFlagHandler.pendingCallbacks[requestId] = callback

    -- Send request to server
    sendClientCommand("ZMServerwideFlagHandler", "getFlagDirect", {
        flagName = flagName,
        requestId = requestId
    })
end

-- On-demand boolean flag request (no caching)
ZMServerwideFlagHandler.getFlagBoolDirect = function(flagName, callback)
    print("ZonaMerah DEBUG: Requesting flag directly: " .. flagName)
    ZMServerwideFlagHandler.requestFlagDirect(flagName, function(value)
        local result = false
        print("ZonaMerah DEBUG: Raw value received for " .. flagName .. ": " .. tostring(value) ..
              " (type: " .. type(value) .. ")")

        if type(value) == "number" then
            result = value == 1
            print("ZonaMerah DEBUG: Number value " .. value .. " converted to boolean: " .. tostring(result))
        elseif type(value) == "string" then
            result = string.lower(value) == "true" or value == "1"
            print("ZonaMerah DEBUG: String value '" .. value .. "' converted to boolean: " .. tostring(result))
        elseif type(value) == "boolean" then
            result = value
            print("ZonaMerah DEBUG: Boolean value passed through: " .. tostring(result))
        else
            print("ZonaMerah DEBUG: Unknown value type, defaulting to false")
        end

        callback(result)
    end)
end

-- On-demand string flag request (no caching)
ZMServerwideFlagHandler.getFlagStringDirect = function(flagName, defaultValue, callback)
    -- If callback is not provided but defaultValue is a function, use it as callback
    if type(defaultValue) == "function" and callback == nil then
        callback = defaultValue
        defaultValue = ""
    end

    print("ZonaMerah DEBUG: Requesting string flag directly: " .. flagName)
    ZMServerwideFlagHandler.requestFlagDirect(flagName, function(value)
        local result = defaultValue or ""

        print("ZonaMerah DEBUG: Raw value received for " .. flagName .. ": " .. tostring(value) ..
              " (type: " .. type(value) .. ")")

        -- Convert any value to string if it exists
        if value ~= nil then
            result = tostring(value)
            print("ZonaMerah DEBUG: Value converted to string: '" .. result .. "'")
        else
            print("ZonaMerah DEBUG: Value is nil, using default: '" .. result .. "'")
        end

        callback(result)
    end)
end

-- Handle server commands
ZMServerwideFlagHandler.onServerCommand = function(module, command, args)
    if module ~= "ZMServerwideFlagHandler" then return end

    if command == "updateFlag" and args then
        -- Update single flag
        ZMServerwideFlagHandler.flags[args.flagName] = args.value
        print("ZonaMerah: Updated flag " .. args.flagName .. " = " .. tostring(args.value))

        -- Trigger event for mods that want to react to flag changes
        triggerEvent("OnServerwideFlagChanged", args.flagName, args.value)

    elseif command == "updateAllFlags" and args and args.flags then
        -- Update all flags
        ZMServerwideFlagHandler.flags = args.flags
        print("ZonaMerah: Updated all serverwide flags")

        -- Trigger event for all flags updated
        triggerEvent("OnServerwideFlagsUpdated", args.flags)

    elseif command == "flagValue" and args then
        -- Response to specific flag request
        ZMServerwideFlagHandler.flags[args.flagName] = args.value
        print("ZonaMerah: Received flag " .. args.flagName .. " = " .. tostring(args.value))

    elseif command == "error" and args then
        local player = getPlayer()
        if player and args.message then
            player:Say("Error: " .. args.message)
        end
    elseif command == "flagDirectResponse" and args and args.requestId and args.flagName then
        local callback = ZMServerwideFlagHandler.pendingCallbacks[args.requestId]
        if callback then
            -- Execute callback with value and remove from pending list
            callback(args.value)
            ZMServerwideFlagHandler.pendingCallbacks[args.requestId] = nil
        end
    end
end

-- Console functions for testing
ZMServerwideFlagHandler.consoleGetFlag = function(flagName)
    if not flagName then
        print("Usage: ZMServerwideFlagHandler.consoleGetFlag('flagName')")
        return
    end
    local value = ZMServerwideFlagHandler.getFlag(flagName)
    print("Flag " .. flagName .. " = " .. tostring(value) .. " (type: " .. type(value) .. ")")
    return value
end

ZMServerwideFlagHandler.consoleSetFlag = function(flagName, value)
    if not flagName then
        print("Usage: ZMServerwideFlagHandler.consoleSetFlag('flagName', value)")
        return
    end
    sendClientCommand("ZMServerwideFlagHandler", "setFlag", {
    flagName = flagName,
    value = value
    })
end

ZMServerwideFlagHandler.consoleListFlags = function()
    print("=== Client-side Serverwide Flags ===")
    for flagName, value in pairs(ZMServerwideFlagHandler.flags) do
        print(flagName .. " = " .. tostring(value) .. " (type: " .. type(value) .. ")")
    end
    print("====================================")
end

-- Console function for direct flag requests
ZMServerwideFlagHandler.consoleRequestFlagDirect = function(flagName)
    if not flagName then
        print("Usage: ZMServerwideFlagHandler.consoleRequestFlagDirect('flagName')")
        return
    end

    print("ZonaMerah: Requesting flag '" .. flagName .. "' directly from server...")
    ZMServerwideFlagHandler.getFlagBoolDirect(flagName, function(result)
        print("ZonaMerah RESULT: Flag '" .. flagName .. "' = " .. tostring(result))
    end)
end

-- Console function for direct string flag requests
ZMServerwideFlagHandler.consoleRequestFlagStringDirect = function(flagName, defaultValue)
    if not flagName then
        print("Usage: ZMServerwideFlagHandler.consoleRequestFlagStringDirect('flagName', 'defaultValue')")
        return
    end

    print("ZonaMerah: Requesting string flag '" .. flagName .. "' directly from server...")
    ZMServerwideFlagHandler.getFlagStringDirect(flagName, defaultValue or "", function(result)
        print("ZonaMerah RESULT: Flag '" .. flagName .. "' = '" .. result .. "'")
    end)
end

-- Auto-request flags when player connects
ZMServerwideFlagHandler.onPlayerConnect = function()
    ZMServerwideFlagHandler.requestFlags()
end

Events.OnGameStart.Add(ZMServerwideFlagHandler.init)
Events.OnServerCommand.Add(ZMServerwideFlagHandler.onServerCommand)
Events.OnConnected.Add(ZMServerwideFlagHandler.onPlayerConnect)

return ZMServerwideFlagHandler