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

local skipGhostModeCheckUntil = 0

local function OnCreatePlayer(playerNum, player)
    -- Set flag to skip ghost mode check for 1 minute (real time) after player creation
    skipGhostModeCheckUntil = getTimestampMs() + 60000 -- 60 seconds from now
    -- player:Say("You are now in Ghost Mode.")
    -- player:setGhostMode(true)
    -- player:setInvisible(true)
end

Events.OnCreatePlayer.Add(OnCreatePlayer)

function ForceRegularPlayerZM.ZMSetDefaultPlayerStat()
    local playerObj = getPlayer()
    if not playerObj then return end

    local isDebugEnabled = isDebugEnabled()

    -- if not isDebugEnabled then return end
    -- Skip if player is admin
    local accessLevel = "standard"
    accessLevel = playerObj:getAccessLevel()
    print(accessLevel .. " is the access level of " .. playerObj:getUsername())
    if accessLevel ~= "None" then
        return
    end

    local username = playerObj:getUsername()

    if username == "BlondeDanger" then
        return
    end

    local cheatsDetected = false

    -- Skip ghost mode check if within 1 minute of player creation
    if getTimestampMs() > skipGhostModeCheckUntil then
        if playerObj:isGhostMode() then
            -- ForceRegularPlayerZM.LogToServer(username, "Ghost Mode", "Disabled automatically")
            print("Ghost Mode is enabled for player: " .. username)
            playerObj:setGhostMode(false)
            playerObj:Say("Ghost Mode has been disabled.")
            cheatsDetected = true
        end
    else
        print("Skipping ghost mode check for player: " .. username .. " until next minute")
    end

    if playerObj:isGodMod() then
        ForceRegularPlayerZM.LogToServer(username, "God Mode", "Disabled automatically")
        print("God Mode is enabled for player: " .. username)
        playerObj:setGodMod(false)
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

    -- Check Unlimited Endurance, but skip if player tier is Godlike
    local skipUnlimitedEndurance = false
    if PlayerTierHandler and PlayerTierHandler.getPlayerTier then

    end

    if playerObj:isUnlimitedEndurance() then

        local tierValue = PlayerTierHandler.getPlayerTierValue(playerObj) or 1
        if tierValue == 8 then
          return
        end

        local tier = PlayerTierHandler.getPlayerTier(playerObj)
        if tier == "Godlike" then
            return
        end

        ForceRegularPlayerZM.LogToServer(username, "Unlimited Endurance", "Disabled automatically")
        print("Unlimited Endurance is enabled for player: " .. username)
        playerObj:setUnlimitedEndurance(false)
        cheatsDetected = true
    end

    if getTimestampMs() > skipGhostModeCheckUntil then
        if playerObj:isInvisible() then
            ForceRegularPlayerZM.LogToServer(username, "Invisible Mode", "Disabled automatically")
            print("Invisible Mode is enabled for player: " .. username)
            playerObj:setInvisible(false)
            cheatsDetected = true
        end
    end

    if playerObj:isBuildCheat() then
        ForceRegularPlayerZM.LogToServer(username, "isBuildCheat Mode", "logged automatically")
        playerObj:setBuildCheat(false)
        print("isBuildCheat Mode is enabled for player: " .. username)
        cheatsDetected = true
    end

    if playerObj:isMechanicsCheat() then
        ForceRegularPlayerZM.LogToServer(username, "isMechanicsCheat Mode", "logged automatically")
        playerObj:setMechanicsCheat(false)
        print("isMechanicsCheat Mode is enabled for player: " .. username)
        cheatsDetected = true
    end

    if playerObj:isMovablesCheat() then
        ForceRegularPlayerZM.LogToServer(username, "isMovablesCheat Mode", "logged automatically")
        playerObj:setMovablesCheat(false)
        print("isMovablesCheat Mode is enabled for player: " .. username)
        cheatsDetected = true
    end

    if playerObj:isHealthCheat() then
        ForceRegularPlayerZM.LogToServer(username, "isHealthCheat Mode", "logged automatically")
        playerObj:setHealthCheat(false)
        print("isHealthCheat Mode is enabled for player: " .. username)
        cheatsDetected = true
    end

    if playerObj:isCheatPlayerSeeEveryone() then
        ForceRegularPlayerZM.LogToServer(username, "isCheatPlayerSeeEveryone Mode", "logged automatically")
        playerObj:setCheatPlayerSeeEveryone(false)
        print("isCheatPlayerSeeEveryone Mode is enabled for player: " .. username)
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
end

Events.EveryOneMinute.Add(function()
  if ZombRand(100) < 20 then -- 10% chance
      ForceRegularPlayerZM.ZMSetDefaultPlayerStat()
  end
end)