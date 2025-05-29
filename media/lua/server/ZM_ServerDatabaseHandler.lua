ZMDatabaseHandler = ZMDatabaseHandler or {}

-- Initialize function to set up database access
ZMDatabaseHandler.init = function()
    -- Make sure we're on the server
    if not isServer() then return end

    -- Check if we can access the ServerWorldDatabase
    if ServerWorldDatabase and ServerWorldDatabase.instance then
        print("ZonaMerah: Successfully connected to ServerWorldDatabase")
    else
        print("ZonaMerah: Failed to access ServerWorldDatabase")
    end
end

-- Register for server startup event
Events.OnServerStarted.Add(ZMDatabaseHandler.init)

-- User and Steam ID management
ZMDatabaseHandler.setUserSteamID = function(username, steamID)
    if not isServer() then return false end
    if ServerWorldDatabase.instance then
        ServerWorldDatabase.instance:setUserSteamID(username, steamID)
        return true
    end
    return false
end

-- Get a user's Steam ID
ZMDatabaseHandler.getUserSteamID = function(username)
    if not isServer() then return nil end
    if ServerWorldDatabase.instance then
        return ServerWorldDatabase.instance:getUserSteamID(username)
    end
    return nil
end

-- Add a faction
ZMDatabaseHandler.addFaction = function(factionName, owner, tag, colorR, colorG, colorB)
    if not isServer() then return false end
    if ServerWorldDatabase.instance then
        ServerWorldDatabase.instance:addFaction(factionName, owner, tag, colorR, colorG, colorB)
        return true
    end
    return false
end

-- Get all server users
ZMDatabaseHandler.getAllUsers = function()
    if not isServer() then return {} end
    if ServerWorldDatabase.instance then
        local users = ServerWorldDatabase.instance:getAllUsers()
        local result = {}
        for i = 0, users:size()-1 do
            table.insert(result, users:get(i))
        end
        return result
    end
    return {}
end