ZMServerPerkRestorer = ZMServerPerkRestorer or {}

-- Initialize the server perk restorer
ZMServerPerkRestorer.init = function()
    print("ZonaMerah: Initialized server perk restorer")
end

-- Parse the perk log file and extract latest perk levels for a player
ZMServerPerkRestorer.getPerkDataForPlayer = function(playerUsername)
    local perkData = {}
    local latestHoursSurvived = 0
    local foundPlayer = false

    -- Define path to perk log (server-side path)
    local logPath = "./perkLog.txt"

    -- Read the log file
    local file = getFileReader(logPath, false)
    if not file then
        print("ERROR: ZonaMerah: Could not open perk log file at " .. logPath)
        return nil
    end

    local line = file:readLine()
    while line do
        -- Check if line contains data for the target player
        if line:find("%[" .. playerUsername .. "%]") then
            foundPlayer = true

            -- Check if this is a full perk dump line
            if line:find("Hours Survived:") then
                local hoursSurvived = tonumber(line:match("Hours Survived: (%d+)"))

                -- Process only if this is the most recent entry
                if hoursSurvived and hoursSurvived > latestHoursSurvived then
                    latestHoursSurvived = hoursSurvived

                    -- Extract all perk levels
                    local perksSegment = line:match("%[(.-)%]%[Hours Survived:")
                    if perksSegment then
                        -- Parse individual perks (Perk=Level format)
                        for perk, level in perksSegment:gmatch("(%w+)=(%d+)") do
                            perkData[perk] = tonumber(level)
                        end
                    end
                end
            end

            -- Process individual perk change lines
            if line:find("%[Level Changed%]") then
                local perk, level = line:match("%[Level Changed%]%[(%w+)%]%[(%d+)%]")
                if perk and level then
                    perkData[perk] = tonumber(level)
                end
            end
        end

        line = file:readLine()
    end

    file:close()

    if not foundPlayer then
        print("WARNING: ZonaMerah: No data found for player " .. playerUsername)
        return nil
    end

    return perkData
end

-- Apply perk levels to a player
ZMServerPerkRestorer.applyPerksToPlayer = function(player, perkData)
    if not player or not perkData then return false end

    -- Convert perk names to Perks objects
    local perkNameMap = {
        Cooking = Perks.Cooking,
        Fitness = Perks.Fitness,
        Strength = Perks.Strength,
        Blunt = Perks.Blunt,
        Axe = Perks.Axe,
        Sprinting = Perks.Sprinting,
        Lightfoot = Perks.Lightfoot,
        Nimble = Perks.Nimble,
        Sneak = Perks.Sneaking,
        Woodwork = Perks.Woodwork,
        Aiming = Perks.Aiming,
        Reloading = Perks.Reloading,
        Farming = Perks.Farming,
        Fishing = Perks.Fishing,
        Trapping = Perks.Trapping,
        PlantScavenging = Perks.PlantScavenging,
        Doctor = Perks.Doctor,
        Electricity = Perks.Electricity,
        MetalWelding = Perks.MetalWelding,
        Mechanics = Perks.Mechanics,
        Spear = Perks.Spear,
        Maintenance = Perks.Maintenance,
        SmallBlade = Perks.SmallBlade,
        LongBlade = Perks.LongBlade,
        SmallBlunt = Perks.SmallBlunt,
        Tailoring = Perks.Tailoring,
        Cleaning = Perks.Cleaning,
        Dancing = Perks.Dancing,
        Meditation = Perks.Meditation,
        Music = Perks.Music
    }

    -- Apply each perk level
    local appliedCount = 0
    for perkName, level in pairs(perkData) do
        local perkObj = perkNameMap[perkName]
        if perkObj then
            -- Set the perk level using the correct method
            player:getXp():setXPToLevel(perkObj, level)
            appliedCount = appliedCount + 1
            print("ZonaMerah: Applied " .. perkName .. " level " .. level .. " to " .. player:getUsername())
        else
            print("WARNING: ZonaMerah: Unknown perk name: " .. perkName)
        end
    end

    print("ZonaMerah: Successfully applied " .. appliedCount .. " perks to " .. player:getUsername())
    return true
end

-- Handle client command to restore perks
ZMServerPerkRestorer.onClientCommand = function(module, command, player, args)
    if module ~= "ZonaMerahCore" then return end

    -- Handle restore perks command
    if command == "restorePerks" then
        -- Validate arguments
        if not args or not args.targetUsername then
            print("ERROR: ZonaMerah: Missing target username for perk restoration")
            return
        end

        -- Check if player has permission (admin or same player)
        local isAdmin = player:getAccessLevel() ~= "None"
        local isSelf = player:getUsername() == args.targetUsername

        if not isAdmin and not isSelf then
            print("WARNING: ZonaMerah: Player " .. player:getUsername() ..
                  " attempted to restore perks for " .. args.targetUsername .. " without permission")
            return
        end

        -- Get the target player
        local targetPlayer = nil
        for i=0, getNumActivePlayers()-1 do
            local p = getSpecificPlayer(i)
            if p and p:getUsername() == args.targetUsername then
                targetPlayer = p
                break
            end
        end

        if not targetPlayer then
            print("ERROR: ZonaMerah: Target player " .. args.targetUsername .. " not found")
            sendServerCommand(player, "ZonaMerahCore", "restorePerksResult", { success = false, message = "Player not found" })
            return
        end

        -- Get perk data
        local sourceUsername = args.sourceUsername or args.targetUsername
        local perkData = ZMServerPerkRestorer.getPerkDataForPlayer(sourceUsername)

        if not perkData then
            print("ERROR: ZonaMerah: No perk data found for " .. sourceUsername)
            sendServerCommand(player, "ZonaMerahCore", "restorePerksResult", { success = false, message = "No perk data found" })
            return
        end

        -- Apply perks to target player
        local success = ZMServerPerkRestorer.applyPerksToPlayer(targetPlayer, perkData)

        -- Send result back to client
        sendServerCommand(player, "ZonaMerahCore", "restorePerksResult", {
            success = success,
            message = success and "Perks restored successfully" or "Failed to restore perks"
        })
    end
end

-- Register event handlers
Events.OnServerStarted.Add(ZMServerPerkRestorer.init)
Events.OnClientCommand.Add(ZMServerPerkRestorer.onClientCommand)