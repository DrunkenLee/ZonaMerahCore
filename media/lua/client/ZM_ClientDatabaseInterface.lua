ZMClientDatabaseInterface = ZMClientDatabaseInterface or {}

-- Request to set a user's Steam ID
ZMClientDatabaseInterface.requestSetUserSteamID = function(username, steamID)
    sendClientCommand("ZonaMerahAdmin", "setUserSteamID", {
        username = username,
        steamID = steamID
    })
    print("Sent request to set Steam ID " .. steamID .. " for user " .. username)
end

-- Request list of all users
ZMClientDatabaseInterface.requestAllUsers = function()
    sendClientCommand("ZonaMerahAdmin", "getAllUsers", {})
    print("Requested list of all server users")
end

-- Handle server responses
ZMClientDatabaseInterface.onServerCommand = function(module, command, args)
    if module ~= "ZonaMerahAdmin" then return end

    if command == "commandResult" then
        print(args.message)
    elseif command == "userList" then
        print("Server Users:")
        for _, username in ipairs(args.users) do
            print("- " .. username)
        end
    end
end

-- Register response handler
Events.OnServerCommand.Add(ZMClientDatabaseInterface.onServerCommand)