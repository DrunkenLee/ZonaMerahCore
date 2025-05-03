require "PlayerTitleHandler"

ServerPlayerTitleHandler = {}

function ServerPlayerTitleHandler.savePlayerTitle(player, args)
    if not player or not args.username or not args.title then return end

    local username = args.username
    local title = args.title

    print("[ServerPlayerTitleHandler] Saving title " .. title .. " for player " .. username)

    local filePath = "server-player-titles.ini"
    local data = {}

    local file = getFileReader(filePath, true)
    if file then
        local line = file:readLine()
        while line do
            local user, savedTitle = line:match("([^,]+),([^,]+)")
            if user and user ~= username then
                data[user] = savedTitle
            end
            line = file:readLine()
        end
        file:close()
    end

    data[username] = title

    local fileWriter = getFileWriter(filePath, true, false)
    if fileWriter then
        for user, userTitle in pairs(data) do
            fileWriter:write(user .. "," .. userTitle .. "\n")
        end
        fileWriter:close()
        print("[ServerPlayerTitleHandler] Successfully saved title for " .. username)

        sendServerCommand(player, "PlayerTitleHandler", "titleSaveResponse", {
            success = true,
            message = "Your title has been saved on the server."
        })
    else
        print("[ServerPlayerTitleHandler] Error: Failed to open file for writing: " .. filePath)
        sendServerCommand(player, "PlayerTitleHandler", "titleSaveResponse", {
            success = false,
            message = "Error: Failed to save your title on the server."
        })
    end
end

function ServerPlayerTitleHandler.loadPlayerTitle(player, args)
    if not player then return 0 end

    local username = args and args.username or player:getUsername()

    local filePath = "server-player-titles.ini"
    local file = getFileReader(filePath, true)
    if not file then
        return 0
    end

    local title = 0
    local line = file:readLine()
    while line do
        local user, savedTitle = line:match("([^,]+),([^,]+)")
        if user and user == username then
            title = tonumber(savedTitle) or 0
            break
        end
        line = file:readLine()
    end
    file:close()

    print("[ServerPlayerTitleHandler] Loaded title " .. title .. " for player " .. username)

    sendServerCommand(player, "PlayerTitleHandler", "loadPlayerTitleResponse", {
        username = username,
        title = title
    })

    return title
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "PlayerTitleHandler" then
        if command == "savePlayerTitle" then
            ServerPlayerTitleHandler.savePlayerTitle(player, args)
        elseif command == "loadPlayerTitle" then
            ServerPlayerTitleHandler.loadPlayerTitle(player, args)
        end
    end
end)