PlayerTitleHandler = {}
PlayerTitleHandler.storedTitles = {}

-- Function to get the player's title from the server
function PlayerTitleHandler.getPlayerTitle(player, callback)
    local username = player:getUsername()

    -- Send a request to the server to get the player's title
    sendClientCommand("PlayerTitleHandlerServer", "getTitle", { username = username })
    print("Sent request to server for title")

    -- Listen for the server's response
    local function onServerCommand(module, command, args)
        if module == "PlayerTitleHandlerServer" and command == "sendTitle" and args.username == username then
            local title = args.title or "DEFAULT"
            print("Received title from server: " .. title .. " for " .. username)
            Events.OnServerCommand.Remove(onServerCommand)
            PlayerTitleHandler.storedTitles[username] = title
            callback(title) -- Call the callback function with the title
        end
    end

    Events.OnServerCommand.Add(onServerCommand)
end

-- Function to retrieve the stored title for a player
function PlayerTitleHandler.getStoredTitle(player)
    local username = player:getUsername()
    return PlayerTitleHandler.storedTitles[username] or "DEFAULT"
end

return PlayerTitleHandler