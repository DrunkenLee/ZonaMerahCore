-- Server command handler for ZonaMerahCore cheat detection

local Commands = {}

-- Simple function to handle cheat logging from clients
Commands.LogCheat = function(player, args)
    local username = args.username
    local cheatType = args.cheatType
    local details = args.details or ""

    -- Format timestamp for log
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")

    -- Print directly to server console
    print(timestamp .. " [ZM-CHEAT-DETECTED] Player '" .. username ..
          "' used cheat '" .. cheatType .. "' - " .. details)
end

Commands.ZMServerCoreLogger = function(player, args)
    local logType = args.logType or "Info"
    local message = args.message or ""

    -- Format timestamp for log
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")

    -- Print log message to server console
    print(string.format("%s [ZonaMerahCore][%s] %s", timestamp, logType, message))
end

-- Handle custom command execution
Commands.CustomExecute = function(player, args)

    print("Player " .. player:getUsername() .. " requested to execute custom commands")

    local commands = {}
    local file = getFileReader("custom_command.ini", false)
    if file then
        local line = file:readLine()
        while line do
            if line and line ~= "" and not line:match("^%s*;") then -- Skip comments and empty lines
                table.insert(commands, line)
            end
            line = file:readLine()
        end
        file:close()

        -- Send commands back to the client for execution
        sendServerCommand(player, "ZonaMerahCore", "ExecuteCommands", {commands = commands})
        print("Sent " .. #commands .. " commands to player " .. player:getUsername())
    else
        print("Could not find custom_command.ini file")
    end
end

Commands.SendMessageZM = function(player, args)
    local message = args.message or ""
    if message ~= "" then
        -- Send broadcast to all online players
        local onlinePlayers = getOnlinePlayers()
        for i = 0, onlinePlayers:size() - 1 do
            local targetPlayer = onlinePlayers:get(i)
            if targetPlayer then
                sendServerCommand(targetPlayer, "ZonaMerahCore", "Broadcast", {message = message})
            end
        end

        print("[ZonaMerahCore] - Broadcast sent to all " .. onlinePlayers:size() .. " online players by " .. player:getUsername() .. ": " .. message)
    end
end

Commands.SendMessageZmToPlayers = function(player, args)
    local message = args.message or ""
    if message ~= "" then
        -- Send broadcast to all online players
        local usernames = args.usernames or {}
        for _, username in ipairs(usernames) do
            local targetPlayer = getPlayerByUsername(username)
            if targetPlayer then
                sendServerCommand(targetPlayer, "ZonaMerahCore", "BroadcastToPlayers", {message = message})

                print("[ZonaMerahCore] - BroadcastToPlayers sent to " .. targetPlayer:getUsername() .. ": " .. message)
            else
                print("[ZonaMerahCore] - Could not find player with username: " .. username)
            end
        end
    end
end

-- Register server command handlers
local onClientCommand = function(module, command, player, args)
    if module == "ZonaMerahCore" and Commands[command] then
        Commands[command](player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)