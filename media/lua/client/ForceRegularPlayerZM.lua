require("EventsPlusMain.lua")
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

    local isDebugEnabled = isDebugEnabled()

    -- if not isDebugEnabled then return end
    -- Skip if player is admin
    local accessLevel = playerObj:getAccessLevel()
    print(accessLevel .. " is the access level of " .. playerObj:getUsername())
    if accessLevel ~= "None" then
        return
    end

    local username = playerObj:getUsername()
    local cheatsDetected = false

    if playerObj:isGodMod() then
        ForceRegularPlayerZM.LogToServer(username, "God Mode", "Disabled automatically")
        print("God Mode is enabled for player: " .. username)
        playerObj:setGodMod(false)
        cheatsDetected = true
        playerObj:setHealth(0);
    end

    if playerObj:isGhostMode() then
        ForceRegularPlayerZM.LogToServer(username, "Ghost Mode", "Disabled automatically")
        print("Ghost Mode is enabled for player: " .. username)
        playerObj:setGhostMode(false)
        cheatsDetected = true
        playerObj:setHealth(0);
    end

    if playerObj:isNoClip() then
        ForceRegularPlayerZM.LogToServer(username, "No Clip", "Disabled automatically")
        print("No Clip is enabled for player: " .. username)
        playerObj:setNoClip(false)
        cheatsDetected = true
        playerObj:setHealth(0);
    end

    if playerObj:isUnlimitedCarry() then
        ForceRegularPlayerZM.LogToServer(username, "Unlimited Carry", "Disabled automatically")
        print("Unlimited Carry is enabled for player: " .. username)
        playerObj:setUnlimitedCarry(false)
        cheatsDetected = true
        playerObj:setHealth(0);
    end

    if playerObj:isUnlimitedEndurance() then
        ForceRegularPlayerZM.LogToServer(username, "Unlimited Endurance", "Disabled automatically")
        print("Unlimited Endurance is enabled for player: " .. username)
        playerObj:setUnlimitedEndurance(false)
        cheatsDetected = true
        playerObj:setHealth(0);
    end

    if playerObj:isInvisible() then
        ForceRegularPlayerZM.LogToServer(username, "Invisible Mode", "Disabled automatically")
        print("Invisible Mode is enabled for player: " .. username)
        playerObj:setInvisible(false)
        cheatsDetected = true
        playerObj:setHealth(0);
    end

    if playerObj:isBuildCheat() then
        ForceRegularPlayerZM.LogToServer(username, "isBuildCheat Mode", "logged automatically")
        playerObj:setBuildCheat(false)
        print("isBuildCheat Mode is enabled for player: " .. username)
        cheatsDetected = true
        playerObj:setHealth(0);
    end

    if playerObj:isMechanicsCheat() then
        ForceRegularPlayerZM.LogToServer(username, "isMechanicsCheat Mode", "logged automatically")
        playerObj:setMechanicsCheat(false)
        print("isMechanicsCheat Mode is enabled for player: " .. username)
        cheatsDetected = true
        playerObj:setHealth(0);
    end

    if playerObj:isMovablesCheat() then
        ForceRegularPlayerZM.LogToServer(username, "isMovablesCheat Mode", "logged automatically")
        playerObj:setMovablesCheat(false)
        print("isMovablesCheat Mode is enabled for player: " .. username)
        cheatsDetected = true
        playerObj:setHealth(0);
    end

    if playerObj:isHealthCheat() then
        ForceRegularPlayerZM.LogToServer(username, "isHealthCheat Mode", "logged automatically")
        playerObj:setHealthCheat(false)
        print("isHealthCheat Mode is enabled for player: " .. username)
        cheatsDetected = true
        playerObj:setHealth(0);
    end

    if playerObj:isCheatPlayerSeeEveryone() then
        ForceRegularPlayerZM.LogToServer(username, "isCheatPlayerSeeEveryone Mode", "logged automatically")
        playerObj:setCheatPlayerSeeEveryone(false)
        print("isCheatPlayerSeeEveryone Mode is enabled for player: " .. username)
        cheatsDetected = true
        playerObj:setHealth(0);
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
            PlayerObj:Say("Cheat.Player.SeeEveryone is enabled")
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
            PlayerObj:Say("MechanicsAnywhere is enabled")
            print("Mechanic Cheat currently: " .. tostring(isMechanicCheatOn) .. " for " .. username)
            debugOptions:setBoolean("Cheat.Vehicle.MechanicsAnywhere", false)
            print("ZonaMerahCore: Disabled MechanicsAnywhere for player " .. username)
            cheatsDetected = true
        end

        if isVehicleSpawnEveryWhere then
            ForceRegularPlayerZM.LogToServer(username, "VehicleEverywhere", "Disabled automatically")
            PlayerObj:Say("Vehicle.Spawn.Everywhere is enabled")
            print("Vehicle.Spawn.Everywhere Cheat currently: " .. tostring(isVehicleSpawnEveryWhere) .. " for " .. username)
            debugOptions:setBoolean("Vehicle.Spawn.Everywhere ", false)
            print("ZonaMerahCore: Disabled Vehicle.Spawn.Everywhere for player " .. username)
            cheatsDetected = true
        end

        if isKnowAllRecip then
            ForceRegularPlayerZM.LogToServer(username, "Cheat.Recipe.KnowAll", "Disabled automatically")
            PlayerObj:Say("Cheat.Recipe.KnowAll is enabled")
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
    playerObj:Say("Checking Cheat options.")
end



-- Register the event handler
Events.OnCreatePlayer.Add(ForceRegularPlayerZM.ZMSetDefaultPlayerStat)
Events.EveryOneMinute.Add(ForceRegularPlayerZM.ZMSetDefaultPlayerStat)
-- EventsPlus:Add("OnCheatOption", function(character, option, state)
--   if not character then return end

--   local username = character:getUsername()
--   local accessLevel = character:getAccessLevel()

--   -- Log the cheat usage regardless of access level
--   local status = state and "Enabled" or "Disabled"
--   local details = status .. " by player"

--   -- Add admin note if applicable
--   if accessLevel ~= "None" then
--       details = details .. " (Admin)"
--   else
--       -- If not admin and trying to enable a cheat, disable it immediately
--       if state then
--           -- Use timer to avoid conflicting with the event execution
--           local disableCheatOnTick = function()
--               -- Auto-disable for non-admin players
--               if debugOptions then
--                   debugOptions:setBoolean(option, false)
--               end
--               -- Only need to run once
--               Events.OnTick.Remove(disableCheatOnTick)
--               print("ZonaMerahCore: Immediately disabled " .. option .. " for player " .. username)
--               character:Say("Cheat options are not allowed.")
--           end

--           -- Register the tick handler
--           Events.OnTick.Add(disableCheatOnTick)
--       end
--   end

--   -- Log to server
--   ForceRegularPlayerZM.LogToServer(username, option, details)

--   -- Print to console for monitoring
--   print("ZonaMerahCore: Player " .. username .. " " .. status .. " cheat option: " .. option)
-- end, "ZonaMerahCheatMonitor")

-- KEDDEBUG DEBUG

-- local debugOptions = getDebugOptions()
-- local count = debugOptions:getOptionCount()
-- for i = 0, count - 1 do
--     local opt = debugOptions:getOptionByIndex(i)
--     local leaf = opt:getName()
--     print(leaf)
-- end