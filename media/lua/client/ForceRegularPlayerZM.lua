require("EventsPlusMain.lua")
ForceRegularPlayerZM = ForceRegularPlayerZM or {}
-- overrided 1
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
local gracePeriodEndTime = 0
local gracePeriodActive = false
local isInvisible = false


local function OnCreatePlayer(playerNum, player)
    -- Set flag to skip ghost mode check for 30 seconds after player creation
    skipGhostModeCheckUntil = getTimestampMs() + 30000
    gracePeriodEndTime = getTimestampMs() + 30000
    gracePeriodActive = true

    PlayerFlagHandler.giveFlag("godmod_allow", false)

    -- Enable ghost mode and invisibility for grace period (client side)
    if player then
        -- Request server to send invisibleplayer command
        isInvisible = player:isInvisible()
        -- player:setGhostMode(true)
        -- player:setInvisible(false, true)
        -- ToggleInvisibleHimself()
        -- print("Grace period started for player: " .. player:getUsername() .. " (30 seconds)")
    end
end

local function OnQSystemPostStart(playerNum, player)

end

Events.OnCreatePlayer.Add(OnCreatePlayer)
-- Events.OnQSystemPostStart.Add(OnQSystemPostStart)

function ForceRegularPlayerZM.ZMSetDefaultPlayerStat()
    local playerObj = getPlayer()
    if not playerObj then return end

    local isDebugEnabled = isDebugEnabled()
    local accessLevel = "standard"
    accessLevel = playerObj:getAccessLevel()
    -- print(accessLevel .. " is the access level of " .. playerObj:getUsername())
    if accessLevel ~= "None" then
        return
    end

    local username = playerObj:getUsername()

    if username == "NenekLincah" then
        playerObj:setUnlimitedEndurance(true)
        return
    end



    local cheatsDetected = false

    -- Skip ghost mode check if within grace period
    if getTimestampMs() > skipGhostModeCheckUntil then
        if playerObj:isGhostMode() then
            print("Ghost Mode is enabled for player: " .. username)
            playerObj:setGhostMode(false)
            playerObj:setInvisible(false)
            -- playerObj:Say("Ghost Mode has been disabled.")
            if isInvisible then
                sendClientCommand("ZonaMerahCore", "RequestInvisible", {
                  username = player:getUsername()
                })
            end

            cheatsDetected = true
        end

    else
        print("Skipping ghost mode check for player: " .. username .. " (grace period active)")
    end

    if playerObj:isGodMod() then
        local isGodModAllowed = PlayerFlagHandler.getFlag("godmode_allow")
        if isGodModAllowed then
            return
        end
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
        -- Whitelist: allow Unlimited Carry while Giant Ox buff is active
        local md = playerObj:getModData()
        local carryAllowedUntil = 0
        if md and md.ZM_GiantOxEndMs then
            carryAllowedUntil = tonumber(md.ZM_GiantOxEndMs) or 0
        end

        local allowUnlimitedCarryFlag = false
        if PlayerFlagHandler and PlayerFlagHandler.getFlag then
            allowUnlimitedCarryFlag = PlayerFlagHandler.getFlag("allow_unlimited_carry") == true
        end

        if allowUnlimitedCarryFlag or (carryAllowedUntil > getTimestampMs()) then
            -- Skip disabling Unlimited Carry while whitelisted
            -- print("Unlimited Carry allowed until " .. tostring(carryAllowedUntil) .. " for " .. username)
        else
            ForceRegularPlayerZM.LogToServer(username, "Unlimited Carry", "Disabled automatically")
            print("Unlimited Carry is enabled for player: " .. username)
            playerObj:setUnlimitedCarry(false)
            cheatsDetected = true
        end
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
    else
        print("Skipping invisible check for player: " .. username .. " (grace period active)")
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
            -- PlayerObj:Say("Cheat.Player.SeeEveryone is enabled")
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
            -- PlayerObj:Say("MechanicsAnywhere is enabled")
            print("Mechanic Cheat currently: " .. tostring(isMechanicCheatOn) .. " for " .. username)
            debugOptions:setBoolean("Cheat.Vehicle.MechanicsAnywhere", false)
            print("ZonaMerahCore: Disabled MechanicsAnywhere for player " .. username)
            cheatsDetected = true
        end

        if isVehicleSpawnEveryWhere then
            ForceRegularPlayerZM.LogToServer(username, "VehicleEverywhere", "Disabled automatically")
            -- PlayerObj:Say("Vehicle.Spawn.Everywhere is enabled")
            print("Vehicle.Spawn.Everywhere Cheat currently: " .. tostring(isVehicleSpawnEveryWhere) .. " for " .. username)
            debugOptions:setBoolean("Vehicle.Spawn.Everywhere ", false)
            print("ZonaMerahCore: Disabled Vehicle.Spawn.Everywhere for player " .. username)
            cheatsDetected = true
        end

        if isKnowAllRecip then
            ForceRegularPlayerZM.LogToServer(username, "Cheat.Recipe.KnowAll", "Disabled automatically")
            -- PlayerObj:Say("Cheat.Recipe.KnowAll is enabled")
            print("Cheat.Recipe.KnowAll currently: " .. tostring(isKnowAllRecip) .. " for " .. username)
            debugOptions:setBoolean("Cheat.Recipe.KnowAll ", false)
            print("ZonaMerahCore: Disabled Cheat.Recipe.KnowAll for player " .. username)
            cheatsDetected = true
        end
    end

    playerObj:save()

    if cheatsDetected then
        -- playerObj:Say("Cheat options have been disabled.")
        print("ZonaMerahCore: Disabled all cheat options for player")
    end
end

-- Run every game tick to enforce grace period continuously on client side

-- Display grace period countdown and send update to server every minute
Events.EveryOneMinute.Add(function()
    local playerObj = getPlayer()
    if not playerObj then return end

    local playerTier = PlayerTierHandler.getPlayerTierValue(playerObj) or 1

    if playerObj:getUsername() == "NenekLincah" or playerTier >= 8 then
        sendClientCommand("ZonaMerahCore", "SetEndurance", {
            username = playerObj:getUsername(),
            isAllowed = true
        })
        local stats = playerObj:getStats()
        stats:setLastEndurance(1.0)
        local enduranceStat = CharacterStat.getById("Endurance")
        if enduranceStat then
            stats:add(enduranceStat, 1.0)
        end
    end

    -- Display remaining grace period time and notify server


    -- playerObj:Say("Checking for cheats...")
    ForceRegularPlayerZM.ZMSetDefaultPlayerStat()
end)