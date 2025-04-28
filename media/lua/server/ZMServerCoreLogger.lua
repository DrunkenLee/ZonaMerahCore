local Commands = {}

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

local onClientCommand = function(module, command, player, args)
    if module == "ZonaMerahCore" and Commands[command] then
        Commands[command](player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)