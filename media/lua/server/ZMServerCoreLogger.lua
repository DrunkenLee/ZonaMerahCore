-- Server command handler for ZonaMerahCore cheat detection

local Commands = {}

local function sendFullHealResponse(player, success, message)
    if not player then return end

    sendServerCommand(player, "ZonaMerahCore", "FullHealResponse", {
        success = success == true,
        message = message or ""
    })
end

local function sendFullCureResponse(player, success, message)
    if not player then return end

    sendServerCommand(player, "ZonaMerahCore", "FullCureResponse", {
        success = success == true,
        message = message or ""
    })
end

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

Commands.NotifyClaimedVehicleDismantleAttempt = function(player, args)
    if not player then return end

    args = args or {}

    local username = player:getUsername() or tostring(args.username or "unknown")
    local owner = tostring(args.owner or "unknown")
    local vehicleName = tostring(args.vehicleName or args.scriptName or "vehicle")
    local vehicleId = tostring(args.vehicleId or "unknown")
    local x = tostring(args.x or "?")
    local y = tostring(args.y or "?")
    local z = tostring(args.z or "?")

    local message = string.format(
        "%s attempted to dismantle claimed AVCS vehicle '%s' (ID: %s, owner: %s) at %s,%s,%s.",
        username,
        vehicleName,
        vehicleId,
        owner,
        x, y, z
    )

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    print(string.format("%s [ZonaMerahCore][Security] %s", timestamp, message))

    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers then return end

    for i = 0, onlinePlayers:size() - 1 do
        local targetPlayer = onlinePlayers:get(i)
        if targetPlayer then
            sendServerCommand(targetPlayer, "ZonaMerahCore", "Broadcast", { message = message })
        end
    end
end

-- Full-heal request from client. Healing is always executed on the server.
Commands.RequestFullHeal = function(player, args)
    if not player then return end

    local username = player:getUsername()
    local bodyDamage = player:getBodyDamage()

    if not bodyDamage then
        local errorMessage = "Full heal failed: bodyDamage is unavailable for '" .. username .. "'."
        print("[ZonaMerahCore] " .. errorMessage)
        sendFullHealResponse(player, false, errorMessage)
        return
    end

    -- Use documented BodyDamage / BodyPart methods only.
    bodyDamage:RestoreToFullHealth()

    local bodyParts = bodyDamage:getBodyParts()
    if bodyParts then
        for i = 0, bodyParts:size() - 1 do
            local part = bodyParts:get(i)
            if part then
                part:RestoreToFullHealth()
            end
        end
    end

    -- Clear common lingering medical states after restoring health.
    if bodyDamage.setInfected then bodyDamage:setInfected(false) end
    if bodyDamage.setIsFakeInfected then bodyDamage:setIsFakeInfected(false) end
    if bodyDamage.setHasACold then bodyDamage:setHasACold(false) end
    if bodyDamage.setCatchACold then bodyDamage:setCatchACold(0.0) end
    if bodyDamage.setColdStrength then bodyDamage:setColdStrength(0.0) end
    if bodyDamage.setInfectionTime then bodyDamage:setInfectionTime(0.0) end
    if bodyDamage.setInfectionGrowthRate then bodyDamage:setInfectionGrowthRate(0.0) end
    if bodyDamage.setInfectionMortalityDuration then bodyDamage:setInfectionMortalityDuration(0.0) end
    if bodyDamage.calculateOverallHealth then bodyDamage:calculateOverallHealth() end
    if bodyDamage.setOverallBodyHealth then bodyDamage:setOverallBodyHealth(100.0) end

    local health = 0.0
    if bodyDamage.getOverallBodyHealth then
        health = bodyDamage:getOverallBodyHealth() or 0.0
    end

    local successMessage = string.format(
        "Full heal completed for '%s' (overall health: %.1f%%).",
        username,
        health
    )

    print("[ZonaMerahCore] " .. successMessage)
    sendFullHealResponse(player, true, successMessage)
end

-- Full-cure request from client. This targets bites and zombie infection explicitly.
Commands.RequestFullCure = function(player, args)
    if not player then return end

    local username = player:getUsername()
    local bodyDamage = player:getBodyDamage()

    if not bodyDamage then
        local errorMessage = "Full cure failed: bodyDamage is unavailable for '" .. username .. "'."
        print("[ZonaMerahCore] " .. errorMessage)
        sendFullCureResponse(player, false, errorMessage)
        return
    end

    -- Keep parity with full-heal first, then force-clear bite/zombie infection state.
    bodyDamage:RestoreToFullHealth()

    local bodyParts = bodyDamage:getBodyParts()
    local curedBiteCount = 0
    if bodyParts then
        for i = 0, bodyParts:size() - 1 do
            local part = bodyParts:get(i)
            if part then
                if part.getBiteTime and part:getBiteTime() > 0 then
                    curedBiteCount = curedBiteCount + 1
                end

                if part.RestoreToFullHealth then part:RestoreToFullHealth() end
                if part.SetBitten then part:SetBitten(false, false) end
                if part.setBiteTime then part:setBiteTime(0.0) end
                if part.SetInfected then part:SetInfected(false) end
                if part.SetFakeInfected then part:SetFakeInfected(false) end
                if part.DisableFakeInfection then part:DisableFakeInfection() end
                if part.setWoundInfectionLevel then part:setWoundInfectionLevel(0.0) end
            end

            -- BodyDamage also exposes SetBitten(index, bitten, infected).
            if bodyDamage.SetBitten then
                bodyDamage:SetBitten(i, false, false)
            end
        end
    end

    -- Clear global infection/cold progression values on BodyDamage.
    if bodyDamage.setInfected then bodyDamage:setInfected(false) end
    if bodyDamage.setIsFakeInfected then bodyDamage:setIsFakeInfected(false) end
    if bodyDamage.setInfectionGrowthRate then bodyDamage:setInfectionGrowthRate(0.0) end
    if bodyDamage.setInfectionTime then bodyDamage:setInfectionTime(0.0) end
    if bodyDamage.setInfectionMortalityDuration then bodyDamage:setInfectionMortalityDuration(0.0) end
    if bodyDamage.setCatchACold then bodyDamage:setCatchACold(0.0) end
    if bodyDamage.setHasACold then bodyDamage:setHasACold(false) end
    if bodyDamage.setColdStrength then bodyDamage:setColdStrength(0.0) end
    if bodyDamage.calculateOverallHealth then bodyDamage:calculateOverallHealth() end
    if bodyDamage.setOverallBodyHealth then bodyDamage:setOverallBodyHealth(100.0) end

    local health = 0.0
    if bodyDamage.getOverallBodyHealth then
        health = bodyDamage:getOverallBodyHealth() or 0.0
    end

    local successMessage = string.format(
        "Full cure completed for '%s' (bites cleared: %d, overall health: %.1f%%).",
        username,
        curedBiteCount,
        health
    )
    print("[ZonaMerahCore] " .. successMessage)
    sendFullCureResponse(player, true, successMessage)
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
    args = args or {}
    if module == "ZonaMerahCore" and Commands[command] then
        Commands[command](player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)
