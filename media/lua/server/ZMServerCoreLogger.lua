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

-- Register server command handlers
local onClientCommand = function(module, command, player, args)
    if module == "ZonaMerahCore" and Commands[command] then
        Commands[command](player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)