ZM_ZombieHandler = ZM_ZombieHandler or {}

-- Zombie type definitions
ZM_ZombieHandler.ZombieTypes = {
    ["elite"] = {
        health = 1000,
        strength = 100,
        fitness = 4,
        walkType = "WTSprint2",
        canSprint = true,
        outfit = "ArmyCamoGreen",
        profession = "Soldier"
    },
    ["elite2"] = {
        health = 200,
        strength = 100,
        fitness = 4,
        walkType = "sprint1",
        canSprint = true,
        outfit = "ArmyCamoDesert",
        profession = "Soldier"
    },
    ["screamer1"] = {
        health = 180,
        strength = 4,
        fitness = 3,
        walkType = "WTSprint2",
        canSprint = true,
        outfit = "Screamer1",
        profession = "Unemployed"
    },
    ["screamer2"] = {
        health = 200,
        strength = 5,
        fitness = 4,
        walkType = "WTSprint2",
        canSprint = true,
        outfit = "Screamer2",
        profession = "Unemployed"
    },
    ["psycho1"] = {
        health = 180,
        strength = 50,
        fitness = 4,
        walkType = "sprint1",
        canSprint = true,
        outfit = "Psycho1",
        profession = "Unemployed"
    },
    ["psycho2"] = {
        health = 200,
        strength = 60,
        fitness = 4,
        walkType = "sprint2",
        canSprint = true,
        outfit = "Psycho2",
        profession = "Unemployed"
    },
    ["bandit_late"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "Bandit_Late",
        profession = "Unemployed"
    },
    ["bandit_mid"] = {
        health = 140,
        strength = 35,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "Bandit_Mid",
        profession = "Unemployed"
    },
    ["biker"] = {
        health = 160,
        strength = 45,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "Biker",
        profession = "Unemployed"
    },
    ["monster_bride"] = {
        health = 160,
        strength = 45,
        fitness = 3,
        walkType = "sprint2",
        canSprint = true,
        outfit = "CostumeMonsterBride",
        profession = "Unemployed"
    },
    ["nightmares"] = {
        health = 160,
        strength = 45,
        fitness = 3,
        walkType = "sprint2",
        canSprint = false,
        outfit = "StripperNaked",
        profession = "Unemployed"
    }
}

-- Sprint area enforcement (client -> server)
ZM_ZombieHandler.SprintArea = ZM_ZombieHandler.SprintArea or {
    x1 = 838,
    x2 = 3227,
    y1 = 5318,
    y2 = 7468
}
ZM_ZombieHandler.SprintAreaDebug = (ZM_ZombieHandler.SprintAreaDebug ~= false)
ZM_ZombieHandler._sprintAreaCooldown = ZM_ZombieHandler._sprintAreaCooldown or {}
ZM_ZombieHandler._sprintAreaLastIn = ZM_ZombieHandler._sprintAreaLastIn or false
ZM_ZombieHandler._sprintAreaOutfitToType = ZM_ZombieHandler._sprintAreaOutfitToType or nil

local function sprintAreaLog(message)
    if ZM_ZombieHandler.SprintAreaDebug then
        print("[ZM_ZombieHandler] " .. message)
    end
end

local function isInSprintArea(x, y)
    local area = ZM_ZombieHandler.SprintArea
    if not area then return false end
    return x >= area.x1 and x <= area.x2 and y >= area.y1 and y <= area.y2
end

local function buildOutfitToType()
    local map = {}
    for zombieType, data in pairs(ZM_ZombieHandler.ZombieTypes) do
        if data and data.outfit then
            map[data.outfit] = zombieType
        end
    end
    ZM_ZombieHandler._sprintAreaOutfitToType = map
end

local function getZombieTypeFromOutfit(outfit)
    if not outfit then return nil end
    if not ZM_ZombieHandler._sprintAreaOutfitToType then
        buildOutfitToType()
    end
    return ZM_ZombieHandler._sprintAreaOutfitToType[outfit]
end

local function isSprintType(zombieType)
    local data = ZM_ZombieHandler.ZombieTypes[zombieType]
    if not data then return false end
    return data.canSprint == true and (data.walkType == "sprint1" or data.walkType == "sprint2")
end

local function onSprintAreaZombieUpdate(zed)
    if not zed or zed:isDead() then return end
    local player = getPlayer()
    if not player then return end

    local px, py = player:getX(), player:getY()
    local inArea = isInSprintArea(px, py)
    if ZM_ZombieHandler._sprintAreaLastIn ~= inArea then
        ZM_ZombieHandler._sprintAreaLastIn = inArea
        sprintAreaLog("Player " .. (inArea and "entered" or "left") ..
            " sprint area at (" .. math.floor(px) .. "," .. math.floor(py) .. ")")
    end
    if not inArea then return end

    local zx, zy = zed:getX(), zed:getY()
    if not isInSprintArea(zx, zy) then return end

    local outfit = zed:getOutfitName()
    local zombieType = getZombieTypeFromOutfit(outfit)
    if not zombieType or not isSprintType(zombieType) then return end

    local zombieID = zed.getOnlineID and zed:getOnlineID() or nil
    if not zombieID or zombieID == 0 then return end

    local now = getGameTime():getWorldAgeSeconds()
    local lastSent = ZM_ZombieHandler._sprintAreaCooldown[zombieID] or 0
    if (now - lastSent) < 5 then
        return
    end
    ZM_ZombieHandler._sprintAreaCooldown[zombieID] = now

    sendClientCommand("ZM_ZombieHandler", "forceSprintForZombie", {
        zombieID = zombieID,
        zombieType = zombieType,
        outfit = outfit,
        x = zx,
        y = zy,
        z = zed:getZ()
    })

    sprintAreaLog("Requested sprint for zombie id=" .. zombieID ..
        ", type=" .. zombieType .. ", outfit=" .. tostring(outfit))
end

-- This is defined outside any function (global scope)
local soundFunction = function()
    -- Get the stored player reference and counter
    local p = player

    -- Check if function should run at all
    if p:getModData().worldSoundCounter >= 10 then
        return
    end

    if not p or not p:isAlive() then
        Events.EveryOneMinute.Remove(soundFunction)
        print("Player is not alive or not found, removing sound function")
        return
    end

    -- Increment counter
    p:getModData().worldSoundCounter = p:getModData().worldSoundCounter + 1

    if p:getModData().worldSoundCounter % 2 == 0 then
      -- p:Say("You hear a distant sound... (" .. p:getModData().worldSoundCounter .. ")")
    end

    -- Check if we've reached 10 times
    if p:getModData().worldSoundCounter >= 10 then
        -- print("Removing world sound event after 10 triggers")
        Events.EveryOneMinute.Remove(soundFunction)
    end
end

-- Function to spawn zombie at player location
function ZM_ZombieHandler.spawnZombieAtPlayer(zombieType, count, safeRadius)
    local player = getPlayer()
    if not player then
        print("Error: No player found")
        return false
    end

    count = count or 1
    zombieType = zombieType or "elite"
    safeRadius = safeRadius or 0 -- Default to 0 (no safe radius)

    -- Check if this is a Psycho zombie type - use PsychoZed mod spawning
    if zombieType == "psycho1" or zombieType == "psycho2" then
        local fit = (zombieType == "psycho1") and "Psycho1" or "Psycho2"

        for i = 1, count do
            -- Spawn each zombie with slight position offset
            local offsetX = (i - 1) * 2 -- Spread them out slightly
            sendClientCommand('PsychoZed', 'doSpawn', {
                x = player:getX() + 20 + offsetX,
                y = player:getY() + 20,
                z = player:getZ(),
                count = 1,
                fit = fit,
                fChance = 100,
                isDown = false
            })
        end

        print("Spawning " .. count .. " " .. zombieType .. " zombie(s) using PsychoZed mod...")
        return true
    end

    -- Standard zombie spawning for non-Psycho types
    sendClientCommand("ZM_ZombieHandler", "spawnZombieAtPlayer", {
        username = player:getUsername(),
        zombieType = zombieType,
        count = count,
        x = player:getX() + 20,
        y = player:getY() + 20,
        z = player:getZ(),
        safeRadius = safeRadius
    })

    -- player:Say("Requesting " .. count .. " " .. zombieType .. " zombie(s)...")
    return true
end

-- Function to spawn zombie at specific coordinates
function ZM_ZombieHandler.spawnZombieAtCoords(x, y, z, zombieType, count)
    local player = getPlayer()
    if not player then
        print("Error: No player found")
        return false
    end

    count = count or 1
    zombieType = zombieType or "elite"
    z = z or 0

    -- Check if this is a Psycho zombie type - use PsychoZed mod spawning
    if zombieType == "psycho1" or zombieType == "psycho2" then
        local fit = (zombieType == "psycho1") and "Psycho1" or "Psycho2"

        for i = 1, count do
            -- Spawn each zombie with slight position offset
            local offsetX = (i - 1) * 2 -- Spread them out slightly
            sendClientCommand('PsychoZed', 'doSpawn', {
                x = x + offsetX,
                y = y,
                z = z,
                count = 1,
                fit = fit,
                fChance = 100,
                isDown = false
            })
        end

        print("Spawning " .. count .. " " .. zombieType .. " zombie(s) at coordinates using PsychoZed mod...")
        return true
    end

    -- Standard zombie spawning for non-Psycho types
    sendClientCommand("ZM_ZombieHandler", "spawnZombieAtCoords", {
        username = player:getUsername(),
        zombieType = zombieType,
        count = count,
        x = x,
        y = y,
        z = z
    })

    -- player:Say("Requesting " .. count .. " " .. zombieType .. " zombie(s) at coordinates...")
    return true
end

-- Function to spawn horde around player
-- Function to spawn horde around player
function ZM_ZombieHandler.spawnHorde(count, radius, isTargeted, targetUsername, zombieType, addVariety, safeRadius)
    local player = getPlayer()
    if not player then
        print("Error: No player found")
        return false
    end

    count = count or 10
    radius = radius or 5
    isTargeted = isTargeted or false
    zombieType = zombieType or "elite"
    addVariety = addVariety or false
    safeRadius = safeRadius or 0 -- Default to 0 (no safe radius)

    -- Check if this is a Psycho zombie type - use PsychoZed mod spawning
    if zombieType == "psycho1" or zombieType == "psycho2" then
        local fit = (zombieType == "psycho1") and "Psycho1" or "Psycho2"

        -- Spawn horde in a circle around player position
        for i = 1, count do
            local angle = (i / count) * math.pi * 2
            local spawnX = player:getX() + 30 + (math.cos(angle) * radius)
            local spawnY = player:getY() + 30 + (math.sin(angle) * radius)

            sendClientCommand('PsychoZed', 'doSpawn', {
                x = spawnX,
                y = spawnY,
                z = player:getZ(),
                count = 1,
                fit = fit,
                fChance = 100,
                isDown = false
            })
        end

        local message = "Spawning horde of " .. count .. " " .. zombieType .. " zombies using PsychoZed mod..."
        if isTargeted and targetUsername then
            message = message .. " (targeting not supported for PsychoZed zombies)"
        end
        print(message)
        return true
    end

    -- Standard zombie spawning for non-Psycho types
    sendClientCommand("ZM_ZombieHandler", "spawnHorde", {
        username = player:getUsername(),
        count = count,
        radius = radius,
        isTargeted = isTargeted,
        targetUsername = targetUsername,
        zombieType = zombieType,
        addVariety = addVariety,
        x = player:getX() + 30,
        y = player:getY() + 30,
        z = player:getZ(),
        safeRadius = safeRadius
    })

    local message = "Requesting horde of " .. count .. " " .. zombieType .. " zombies..."
    if isTargeted and targetUsername then
        message = message .. " targeting " .. targetUsername
    end
    -- player:Say(message)
    return true
end

-- Function to spawn horde for all online players with random outfits
function ZM_ZombieHandler.spawnHordeForAllPlayers(count, radius, safeRadius)
    local player = getPlayer()
    if not player then
        print("Error: No player found")
        return false
    end

    count = count or 10
    radius = radius or 5
    safeRadius = safeRadius or 0

    sendClientCommand("ZM_ZombieHandler", "spawnHordeForAllPlayers", {
        username = player:getUsername(),
        count = count,
        radius = radius,
        safeRadius = safeRadius
    })

    print("Requesting horde for all online players...")
    return true
end

-- Console wrapper functions
function ZM_ZombieHandler.consoleSpawnZombie(zombieType, count, safeRadius)
    return ZM_ZombieHandler.spawnZombieAtPlayer(zombieType, count, safeRadius)
end
function ZM_ZombieHandler.consoleSpawnHorde(count, radius, isTargeted, targetUsername, zombieType, addVariety, safeRadius)
    return ZM_ZombieHandler.spawnHorde(count, radius, isTargeted, targetUsername, zombieType, addVariety, safeRadius)
end
function ZM_ZombieHandler.consoleSpawnHordeForAllPlayers(count, radius, safeRadius)
    return ZM_ZombieHandler.spawnHordeForAllPlayers(count, radius, safeRadius)
end

-- Function to open the Zombie Spawner UI
function ZM_ZombieHandler.openUI()
    if openZombieSpawnerUI then
        openZombieSpawnerUI()
    else
        print("Error: Zombie Spawner UI not loaded. Make sure ZM_ZombieSpawnerUI.lua is loaded.")
    end
end

-- Function to check zombie types
function ZM_ZombieHandler.listZombieTypes()
    print("Available zombie types:")
    for zombieType, data in pairs(ZM_ZombieHandler.ZombieTypes) do
        print("  " .. zombieType .. " - Health: " .. data.health .. ", Strength: " .. data.strength .. ", Walk: " .. data.walkType)
    end
end

-- Client-side debug functions to trigger server-side checks
function ZM_ZombieHandler.checkLootSettings()
    local player = getPlayer()
    if not player then
        print("Error: No player found")
        return false
    end

    sendClientCommand("ZM_ZombieHandler", "checkLootSettings", {
        username = player:getUsername()
    })
    print("Requesting loot settings check from server...")
    return true
end

function ZM_ZombieHandler.testLootCalculation()
    local player = getPlayer()
    if not player then
        print("Error: No player found")
        return false
    end

    sendClientCommand("ZM_ZombieHandler", "testLootCalculation", {
        username = player:getUsername()
    })
    print("Requesting loot calculation test from server...")
    return true
end

function ZM_ZombieHandler.checkSandboxStatus()
    local player = getPlayer()
    if not player then
        print("Error: No player found")
        return false
    end

    sendClientCommand("ZM_ZombieHandler", "checkSandboxStatus", {
        username = player:getUsername()
    })
    print("Requesting sandbox status check from server...")
    return true
end

-- Find a nearby zombie by online ID (client-side)
function ZM_ZombieHandler.findLocalZombieByOnlineID(onlineID)
    if not onlineID then return nil end
    local player = getPlayer()
    if not player then return nil end
    local localList = player:getLocalList()
    if not localList then return nil end

    for i = 0, localList:size() - 1 do
        local obj = localList:get(i)
        if obj and instanceof(obj, "IsoZombie") then
            if obj:getOnlineID() == onlineID then
                return obj
            end
        end
    end

    return nil
end

Events.OnServerCommand.Add(function(module, command, args)
    if module == "ZM_ZombieHandler" then
        if command == "zombieSpawned" then
            local player = getPlayer()
            if player and args.message then
                -- player:Say(args.message)

                -- Initialize tracking variables
                local pulseCount = 0
                local maxPulses = 5  -- 5 pulses over 5 minutes

                local soundPulser
                soundPulser = function()
                    -- Safety check
                    if not player or not player:isAlive() then
                        if soundPulser then
                            Events.EveryOneMinute.Remove(soundPulser)
                        end
                        print("Player not valid, stopping sound pulse")
                        return
                    end

                    -- Increment pulse count
                    pulseCount = pulseCount + 1

                    -- Make sound
                    addSound(player, player:getX(), player:getY(), player:getZ(), 120, 100)

                    -- Debug info
                    print("Sound pulse #" .. pulseCount .. " of " .. maxPulses)

                    -- Player feedback
                    if pulseCount < maxPulses then
                        -- player:Say("More zombies are being attracted... (" .. pulseCount .. " of " .. maxPulses .. ")")
                    end

                    -- Check if we've reached the maximum
                    if pulseCount >= maxPulses then
                        if soundPulser then
                            Events.EveryOneMinute.Remove(soundPulser)
                        end
                        -- player:Say("The attraction effect has ended")
                        print("Sound pulse sequence complete - reached max pulses")
                    end
                end

                -- Register with EveryOneMinute event
                Events.EveryOneMinute.Add(soundPulser)
                -- print("Started sound pulse sequence (every 1 minute for " .. maxPulses .. " minutes)")
            end
        elseif command == "spawnError" then
            local player = getPlayer()
            if player and args.error then
                -- player:Say("Error: " .. args.error)
            end
        elseif command == "screamer1DamageResisted" then
            local player = getPlayer()
            if player and args.message then
                player:Say(args.message)
            end
        elseif command == "syncZombieHealth" then
            if args and args.zombieID and args.health then
                local zombie = ZM_ZombieHandler.findLocalZombieByOnlineID(args.zombieID)
                if zombie then
                    zombie:setHealth(args.health)
                elseif isDebugEnabled() then
                    print("[ZM_ZombieHandler] syncZombieHealth - zombie not found for ID: " .. tostring(args.zombieID))
                end
            end
        end
    end
end)

Events.EveryOneMinute.Add(function(module, command, args)

end)

return ZM_ZombieHandler
