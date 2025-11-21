ZM_ZombieHandler = ZM_ZombieHandler or {}

-- Zombie type definitions
ZM_ZombieHandler.ZombieTypes = {
    ["elite"] = {
        health = 200,
        strength = 100,
        fitness = 4,
        walkType = "sprint1",
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
        walkType = "sprint1",
        canSprint = true,
        outfit = "Screamer1",
        profession = "Unemployed"
    },
    ["screamer2"] = {
        health = 200,
        strength = 5,
        fitness = 4,
        walkType = "sprint2",
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
    }
}


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

-- Console wrapper functions
function ZM_ZombieHandler.consoleSpawnZombie(zombieType, count, safeRadius)
    return ZM_ZombieHandler.spawnZombieAtPlayer(zombieType, count, safeRadius)
end
function ZM_ZombieHandler.consoleSpawnHorde(count, radius, isTargeted, targetUsername, zombieType, addVariety, safeRadius)
    return ZM_ZombieHandler.spawnHorde(count, radius, isTargeted, targetUsername, zombieType, addVariety, safeRadius)
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

-- Add zombie spawn options to player context menu
function ZM_ZombieHandler.addZombieSpawnMenu(playerIndex, context)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    -- Only show for admins
    if not player:isAccessLevel("admin") then return end

    local zombieMenu = context:addOption("Zombie Spawner")
    local zombieSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(zombieMenu, zombieSubMenu)

    -- Add single zombie spawns
    for zombieType, _ in pairs(ZM_ZombieHandler.ZombieTypes) do
        zombieSubMenu:addOption(
            "Spawn " .. zombieType .. " zombie",
            player,
            function()
                ZM_ZombieHandler.spawnZombieAtPlayer(zombieType, 1)
            end
        )
    end

    -- Add separator
    zombieSubMenu:addOption("─────────────────")

    -- Add horde options
    zombieSubMenu:addOption(
        "Spawn Small Horde (5)",
        player,
        function()
            ZM_ZombieHandler.spawnHorde(5, 3)
        end
    )

    zombieSubMenu:addOption(
        "Spawn Medium Horde (15)",
        player,
        function()
            ZM_ZombieHandler.spawnHorde(15, 5)
        end
    )

    zombieSubMenu:addOption(
        "Spawn Large Horde (30)",
        player,
        function()
            ZM_ZombieHandler.spawnHorde(30, 8)
        end
    )
end

-- Handle server responses
Events.OnServerCommand.Add(function(module, command, args)
    if module == "ZM_ZombieHandler" then
        if command == "zombieSpawned" then
            local player = getPlayer()
            if player and args.message then
                -- player:Say(args.message)

                -- Initialize tracking variables
                local pulseCount = 0
                local maxPulses = 5  -- 5 pulses over 5 minutes

                -- Make initial sound immediately
                MakeWorldSound(player, 120, 100)
                -- player:Say("Zombies are being attracted to this area!")

                -- Create a named function we can reference for removal
                local soundPulser = nil
                soundPulser = function()
                    -- Safety check
                    if not player or not player:isAlive() then
                        Events.EveryOneMinute.Remove(soundPulser)
                        print("Player not valid, stopping sound pulse")
                        return
                    end

                    -- Increment pulse count
                    pulseCount = pulseCount + 1

                    -- Make sound
                    MakeWorldSound(player, 120, 100)

                    -- Debug info
                    print("Sound pulse #" .. pulseCount .. " of " .. maxPulses)

                    -- Player feedback
                    if pulseCount < maxPulses then
                        -- player:Say("More zombies are being attracted... (" .. pulseCount .. " of " .. maxPulses .. ")")
                    end

                    -- Check if we've reached the maximum
                    if pulseCount >= maxPulses then
                        Events.EveryOneMinute.Remove(soundPulser)
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
        end
    end
end)

return ZM_ZombieHandler