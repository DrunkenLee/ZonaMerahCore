PlayerTitleHandlerServer = {}

local titles = {"DEFAULT", "VIP", "VVIP"}

-- Function to get or assign a title to a player
function PlayerTitleHandlerServer.getOrAssignTitle(player)
    local username = player:getUsername()
    local title = PlayerTitleHandlerServer.loadTitleFromFile(username)

    if not title then
        title = titles[1] -- Assign default title if no title found
        PlayerTitleHandlerServer.saveTitleToFile(username, title)
    end

    player:Say("Your title is: " .. title)
    return title
end

-- Function to save the player's title to a file
function PlayerTitleHandlerServer.saveTitleToFile(username, title)
    local filePath = "server-titles.ini"
    local data = {}

    -- Read existing data from file if it exists
    local file = getFileReader(filePath, true)
    if file then
        local line = file:readLine()
        while line do
            local user, savedTitle = line:match("([^,]+),([^,]+)")
            data[user] = savedTitle
            line = file:readLine()
        end
        file:close()
    end

    -- Update data with new title
    data[username] = title

    -- Write updated data back to file
    local fileWriter = getFileWriter(filePath, true, false)
    if fileWriter then
        for user, savedTitle in pairs(data) do
            fileWriter:write(string.format("%s,%s\n", user, savedTitle))
        end
        fileWriter:close()
    else
        error("Failed to open file for writing: " .. filePath)
    end
end

-- Function to load the player's title from a file
function PlayerTitleHandlerServer.loadTitleFromFile(username)
    local filePath = "server-titles.ini"
    local file = getFileReader(filePath, true)
    if not file then
        -- print("[ZonaMerahCore] File not found: " .. filePath)
        return nil
    end

    local data = {}
    local line = file:readLine()
    while line do
        local user, savedTitle = line:match("([^,]+),([^,]+)")
        if user and savedTitle then
            data[user] = savedTitle
            -- print("[ZonaMerahCore] Loaded title for user: " .. user .. " -> " .. savedTitle)
        else
            -- print("[ZonaMerahCore] Failed to parse line: " .. line)
        end
        line = file:readLine()
    end
    file:close()

    local title = data[username]
    if title then
        -- print("[ZonaMerahCore] Title found for user " .. username .. ": " .. title)
    else
        -- print("[ZonaMerahCore] No title found for user " .. username)
    end

    return title
end

-- Function to set a player's title dynamically
function PlayerTitleHandlerServer.setPlayerTitle(admin, targetPlayer, title)
    PlayerTitleHandlerServer.saveTitleToFile(targetPlayer:getUsername(), title)
    targetPlayer:Say("Your title has been updated to: " .. title)
    if admin then
        admin:Say("Successfully set " .. targetPlayer:getUsername() .. "'s title to " .. title)
    end
end

-- Hook into the context menu event for admins to set player titles
Events.OnFillWorldObjectContextMenu.Add(function(playerIndex, context)
    local admin = getSpecificPlayer(playerIndex)
    if not admin or not admin:isAccessLevel("admin") then return end

    local submenu = context:getNew(context) -- Create a submenu
    context:addSubMenu(
        context:addOption("Set Player Title"),
        submenu
    )
    local players = getOnlinePlayers()
    -- Add each connected player to the submenu
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        local username = player:getUsername()
        local subSubMenu = submenu:getNew(submenu)
        submenu:addSubMenu(
            submenu:addOption("Set Title for " .. username),
            subSubMenu
        )
        for _, title in ipairs(titles) do
            subSubMenu:addOption(
                "Set " .. username .. " to " .. title,
                admin,
                function()
                    PlayerTitleHandlerServer.setPlayerTitle(admin, player, title)
                end
            )
        end
    end
end)

-- Function to handle client requests for player titles
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "PlayerTitleHandlerServer" and command == "getTitle" then
        local username = args.username
        local title = PlayerTitleHandlerServer.loadTitleFromFile(username)
        sendServerCommand(player, "PlayerTitleHandlerServer", "sendTitle", { username = username, title = title })
        -- print("[ZonaMerahCore] Sent title to " .. username .. ": " .. title)
    end
end)


-- local function PrintOnlinePlayers()
--     local players = getOnlinePlayers()
--     for i = 0, players:size() - 1 do
--         local player = players:get(i)
--         local username = player:getUsername()
--         local title = PlayerTitleHandlerServer.loadTitleFromFile(username)
--         if title == "VIP" then
--           GlobalMethods.addPlayerPoints(username, 15)
--           -- print("[ZonaMerahCore] Added 15 points to VIP " .. username)
--         elseif title == "VVIP" then
--           GlobalMethods.addPlayerPoints(username, 30)
--           -- print("[ZonaMerahCore] Added 30 points to VVIP " .. username)
--         end
--     end
-- end

-- Events.EveryHours.Add(PrintOnlinePlayers)

return PlayerTitleHandlerServer