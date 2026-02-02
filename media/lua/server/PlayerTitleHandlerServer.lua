require "PlayerTitleHandler"

ServerPlayerTitleHandler = {}

-- Function to save the player's title to a file
function ServerPlayerTitleHandler.savePlayerTitle(player, args)
    if not player or not args.username or not args.title then return end

    local username = args.username
    local title = args.title

    -- print("[ServerPlayerTitleHandler] Saving title " .. title .. " for player " .. username)

    local filePath = "server-player-titles.ini"
    local data = {}

    -- Read existing data from the file to preserve other players' titles
    local file = getFileReader(filePath, true)
    if file then
        local line = file:readLine()
        while line do
            local user, savedTitle = line:match("([^,]+),([^,]+)")
            if user and user ~= username then -- Skip the current player's entry, we'll update it
                data[user] = savedTitle
            end
            line = file:readLine()
        end
        file:close()
    end

    -- Update the data with the current player's title
    data[username] = title

    -- Write the updated data back to the file
    local fileWriter = getFileWriter(filePath, true, false)
    if fileWriter then
        for user, userTitle in pairs(data) do
            fileWriter:write(user .. "," .. userTitle .. "\n")
        end
        fileWriter:close()
        -- print("[ServerPlayerTitleHandler] Successfully saved title for " .. username)

        -- Send confirmation back to client
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

-- Function to load the player's title from a file
function ServerPlayerTitleHandler.loadPlayerTitle(player, args)
    if not player then
        print("[ServerPlayerTitleHandler] ERROR: No player provided")
        return 0
    end

    -- Use the username from args if provided, otherwise use the player's username
    local username = args and args.username or player:getUsername()
    -- print("[ServerPlayerTitleHandler] Loading title for username: " .. username)

    local filePath = "server-player-titles.ini"
    local file = getFileReader(filePath, true)
    if not file then
        print("[ServerPlayerTitleHandler] ERROR: Could not open file: " .. filePath)
        sendServerCommand(player, "PlayerTitleHandler", "loadPlayerTitleResponse", {
            username = username,
            title = 0
        })
        return 0
    end

    -- print("[ServerPlayerTitleHandler] File opened successfully, reading lines...")
    local title = 0
    local lineNumber = 0
    local line = file:readLine()
    while line do
        lineNumber = lineNumber + 1
        -- print("[ServerPlayerTitleHandler] Line " .. lineNumber .. ": '" .. line .. "'")

        local user, savedTitle = line:match("([^,]+),([^,]+)")
        -- print("[ServerPlayerTitleHandler] Parsed - User: '" .. tostring(user) .. "', SavedTitle: '" .. tostring(savedTitle) .. "'")

        if user and savedTitle then
            -- Trim any whitespace
            user = user:match("^%s*(.-)%s*$")
            savedTitle = savedTitle:match("^%s*(.-)%s*$")
            -- print("[ServerPlayerTitleHandler] After trim - User: '" .. user .. "', SavedTitle: '" .. savedTitle .. "'")

            if user == username then
                title = tonumber(savedTitle) or 0
                -- print("[ServerPlayerTitleHandler] MATCH FOUND! Title: " .. title)
                break
            else
                -- print("[ServerPlayerTitleHandler] No match: '" .. user .. "' != '" .. username .. "'")
            end
        else
            print("[ServerPlayerTitleHandler] WARNING: Failed to parse line " .. lineNumber)
        end

        line = file:readLine()
    end
    file:close()

    -- print("[ServerPlayerTitleHandler] Final result - Loaded title " .. title .. " for player " .. username)

    -- Send response back to client
    sendServerCommand(player, "PlayerTitleHandler", "loadPlayerTitleResponse", {
        username = username,
        title = title
    })

    return title
end

-- Handler for client commands
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "PlayerTitleHandler" then
        if command == "savePlayerTitle" then
            ServerPlayerTitleHandler.savePlayerTitle(player, args)
        elseif command == "loadPlayerTitle" then
            ServerPlayerTitleHandler.loadPlayerTitle(player, args)
        end
    end
end)