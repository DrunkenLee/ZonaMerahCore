ForceRegularPlayerZM = ForceRegularPlayerZM or {}

-- Create a client-side wrapper for server logging
function ForceRegularPlayerZM.LogToServer(username, cheatType, details)
    -- Send log event to server
    sendClientCommand("ZonaMerahCore", "LogCheat", {
        username = username,
        cheatType = cheatType,
        details = details
    })
end

function ForceRegularPlayerZM.ZMSetDefaultPlayerStat()
    local playerObj = getPlayer()
    if not playerObj then return end

    -- Skip if player is admin
    local accessLevel = playerObj:getAccessLevel()
    print(accessLevel .. " is the access level of " .. playerObj:getUsername())
    if accessLevel ~= "None" then
        print("ZonaMerahCore: Skipping cheat check for admin " .. playerObj:getUsername())
        return
    end

    local username = playerObj:getUsername()
    local cheatsDetected = false

    if playerObj:isGodMod() then
        ForceRegularPlayerZM.LogToServer(username, "God Mode", "Disabled automatically")
        print("God Mode is enabled for player: " .. username)
        playerObj:setGodMod(false)
        cheatsDetected = true
    end

    if playerObj:isGhostMode() then
        ForceRegularPlayerZM.LogToServer(username, "Ghost Mode", "Disabled automatically")
        print("Ghost Mode is enabled for player: " .. username)
        playerObj:setGhostMode(false)
        cheatsDetected = true
    end

    if playerObj:isNoClip() then
        ForceRegularPlayerZM.LogToServer(username, "No Clip", "Disabled automatically")
        print("No Clip is enabled for player: " .. username)
        playerObj:setNoClip(false)
        cheatsDetected = true
    end

    if playerObj:isUnlimitedCarry() then
        ForceRegularPlayerZM.LogToServer(username, "Unlimited Carry", "Disabled automatically")
        print("Unlimited Carry is enabled for player: " .. username)
        playerObj:setUnlimitedCarry(false)
        cheatsDetected = true
    end

    if playerObj:isUnlimitedEndurance() then
        ForceRegularPlayerZM.LogToServer(username, "Unlimited Endurance", "Disabled automatically")
        print("Unlimited Endurance is enabled for player: " .. username)
        playerObj:setUnlimitedEndurance(false)
        cheatsDetected = true
    end

    if playerObj:isInvisible() then
        ForceRegularPlayerZM.LogToServer(username, "Invisible Mode", "Disabled automatically")
        print("Invisible Mode is enabled for player: " .. username)
        playerObj:setInvisible(false)
        cheatsDetected = true
    end

    if debugOptions then
        local isCheatUnlimitedAmmoOn = debugOptions:getBoolean("Cheat.Player.UnlimitedAmmo")
        local isCheatStartInvisibleOn = debugOptions:getBoolean("Cheat.Player.StartInvisible")
        local isCheatSeeEveryoneOn = debugOptions:getBoolean("Cheat.Player.SeeEveryone")
        local isFastMovementOn = debugOptions:getBoolean("Cheat.Player.FastMovement")
        local isMechanicCheatOn = debugOptions:getBoolean("Cheat.VehicleOG.MechanicsAnywhere")
        local isVehicleSpawnEveryWhere = debugOptions:getBoolean("Vehicle.Spawn.Everywhere")
        local isKnowAllRecip = debugOptions:getBoolean("Cheat.Recipe.KnowAll")

        -- playerObj:Say(isKnowAllRecip and "Cheat.Recipe.KnowAll is enabled" or "Cheat.Recipe.KnowAll is disabled")
        -- playerObj:Say(isMechanicCheatOn and "Mechanic Cheat is enabled" or "Mechanic Cheat is disabled")

        if isCheatUnlimitedAmmoOn then
            ForceRegularPlayerZM.LogToServer(username, "Unlimited Ammo", "Disabled automatically")
            debugOptions:setBoolean("Cheat.Player.UnlimitedAmmo", false)
            print("ZonaMerahCore: Disabled Unlimited Ammo for player " .. username)
            cheatsDetected = true
        end

        if isCheatStartInvisibleOn then
            ForceRegularPlayerZM.LogToServer(username, "Start Invisible", "Disabled automatically")
            debugOptions:setBoolean("Cheat.Player.StartInvisible", false)
            print("ZonaMerahCore: Disabled Start Invisible for player " .. username)
            cheatsDetected = true
        end

        if isCheatSeeEveryoneOn then
            ForceRegularPlayerZM.LogToServer(username, "See Everyone", "Disabled automatically")
            debugOptions:setBoolean("Cheat.Player.SeeEveryone", false)
            print("ZonaMerahCore: Disabled See Everyone for player " .. username)
            cheatsDetected = true
        end

        if isFastMovementOn then
            ForceRegularPlayerZM.LogToServer(username, "Fast Movement", "Disabled automatically")
            debugOptions:setBoolean("Cheat.Player.FastMovement", false)
            print("ZonaMerahCore: Disabled Fast Movement for player " .. username)
            cheatsDetected = true
        end

        if isMechanicCheatOn then
            ForceRegularPlayerZM.LogToServer(username, "MechanicsEverywhere", "Disabled automatically")
            print("Mechanic Cheat currently: " .. tostring(isMechanicCheatOn) .. " for " .. username)
            debugOptions:setBoolean("Cheat.Vehicle.MechanicsAnywhere", false)
            print("ZonaMerahCore: Disabled MechanicsAnywhere for player " .. username)
            cheatsDetected = true
        end

        if isVehicleSpawnEveryWhere then
            ForceRegularPlayerZM.LogToServer(username, "VehicleEverywhere", "Disabled automatically")
            print("Vehicle.Spawn.Everywhere Cheat currently: " .. tostring(isVehicleSpawnEveryWhere) .. " for " .. username)
            debugOptions:setBoolean("Vehicle.Spawn.Everywhere ", false)
            print("ZonaMerahCore: Disabled Vehicle.Spawn.Everywhere for player " .. username)
            cheatsDetected = true
        end

        if isKnowAllRecip then
            ForceRegularPlayerZM.LogToServer(username, "Cheat.Recipe.KnowAll", "Disabled automatically")
            print("Cheat.Recipe.KnowAll currently: " .. tostring(isKnowAllRecip) .. " for " .. username)
            debugOptions:setBoolean("Cheat.Recipe.KnowAll ", false)
            print("ZonaMerahCore: Disabled Cheat.Recipe.KnowAll for player " .. username)
            cheatsDetected = true
        end
    end

    playerObj:save()

    if cheatsDetected then
        playerObj:Say("Cheat options have been disabled.")
        print("ZonaMerahCore: Disabled all cheat options for player")
    end
end

-- Register the event handler
Events.OnCreatePlayer.Add(ForceRegularPlayerZM.ZMSetDefaultPlayerStat)
Events.EveryHours.Add(ForceRegularPlayerZM.ZMSetDefaultPlayerStat)





-- KEDDEBUG DEBUG

-- local debugOptions = getDebugOptions()
-- local count = debugOptions:getOptionCount()
-- for i = 0, count - 1 do
--     local opt = debugOptions:getOptionByIndex(i)
--     local leaf = opt:getName()
--     print(leaf)
-- end