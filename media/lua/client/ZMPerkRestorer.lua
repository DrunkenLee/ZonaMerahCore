-- Client-side perk restorer code
ZMPerkRestorer = ZMPerkRestorer or {}

-- Request perk restoration from server
ZMPerkRestorer.requestRestorePerks = function(targetUsername, sourceUsername)
    -- If target not specified, use current player
    if not targetUsername then
        local player = getSpecificPlayer(0)
        targetUsername = player:getUsername()
    end

    -- Send request to server
    sendClientCommand("ZonaMerahCore", "restorePerks", {
        targetUsername = targetUsername,
        sourceUsername = sourceUsername
    })

    print("Sent perk restoration request for " .. targetUsername)
end

-- Handle server response
ZMPerkRestorer.onServerCommand = function(module, command, args)
    if module ~= "ZonaMerahCore" then return end

    if command == "restorePerksResult" then
        if args.success then
            print("Perk restoration successful: " .. args.message)
        else
            print("Perk restoration failed: " .. args.message)
        end
    end
end

-- Register event handlers
Events.OnServerCommand.Add(ZMPerkRestorer.onServerCommand)

-- Function to restore perks from perkLog.txt to a specific player
ZMPerkRestorer = ZMPerkRestorer or {}

-- Parse the perk log file and extract latest perk levels for a player
ZMPerkRestorer.getPerkDataForPlayer = function(playerUsername)
    local perkData = {}
    local latestHoursSurvived = 0
    local foundPlayer = false

    -- Define path to perk log
    local logPath = "./perkLog.txt"

    -- Read the log file
    local file = getFileReader(logPath, false)
    if not file then
        print("ERROR: Could not open perk log file at " .. logPath)
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
            local perkChange = line:match("%[Level Changed%]%[(%w+)%]%[(%d+)%]")
            if perkChange then
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
        print("WARNING: No data found for player " .. playerUsername)
        return nil
    end

    return perkData
end

-- Apply perk levels to a player
ZMPerkRestorer.applyPerksToPlayer = function(player, perkData)
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
            print("Applied " .. perkName .. " level " .. level .. " to " .. player:getFullName())
        else
            print("WARNING: Unknown perk name: " .. perkName)
        end
    end

    print("Successfully applied " .. appliedCount .. " perks to " .. player:getFullName())
    return true
end

-- Main function to restore perks from log file to a player
ZMPerkRestorer.restorePerksFromLog = function(player, playerUsername)
    if not player then return false end

    -- If username not provided, use player's username or full name
    if not playerUsername then
        playerUsername = player:getUsername()
        if not playerUsername or playerUsername == "" then
            playerUsername = player:getFullName()
        end
    end

    -- Get perk data for this player
    local perkData = ZMPerkRestorer.getPerkDataForPlayer(playerUsername)
    if not perkData then
        print("ERROR: Could not retrieve perk data for " .. playerUsername)
        return false
    end

    -- Apply perks to player
    return ZMPerkRestorer.applyPerksToPlayer(player, perkData)
end


