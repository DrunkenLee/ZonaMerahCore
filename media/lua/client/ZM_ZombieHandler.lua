ZM_ZombieHandler = ZM_ZombieHandler or {}

-- Zombie type definitions
ZM_ZombieHandler.ZombieTypes = {
    ["normal"] = {
        health = 100,
        strength = 1,
        fitness = 1,
        walkType = "shamble",
        canSprint = false,
        outfit = "Naked",
        profession = "Unemployed"
    },
    ["runner"] = {
        health = 80,
        strength = 2,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "Survivalist",
        profession = "Survivalist"
    },
    ["tank"] = {
        health = 200,
        strength = 5,
        fitness = 2,
        walkType = "shamble",
        canSprint = false,
        outfit = "Police",
        profession = "Police"
    },
    ["sprinter"] = {
        health = 150,
        strength = 3,
        fitness = 5,
        walkType = "sprint2",
        canSprint = true,
        outfit = "Police",
        profession = "Soldier"
    },
    ["boss"] = {
        health = 200,
        strength = 8,
        fitness = 6,
        walkType = "sprint1",
        canSprint = true,
        outfit = "Police",
        profession = "Police"
    },
    ["horde"] = {
        health = 100,
        strength = 3,
        fitness = 2,
        walkType = "shamble",
        canSprint = false,
        outfit = "Naked",
        profession = "Unemployed"
    },
    ["elite"] = {
        health = 150,
        strength = 6,
        fitness = 4,
        walkType = "sprint1",
        canSprint = true,
        outfit = "ArmyCamoGreen",
        profession = "Soldier"
    },
    ["crawler"] = {
        health = 50,
        strength = 1,
        fitness = 1,
        walkType = "crawl",
        canSprint = false,
        outfit = "Injured",
        profession = "Unemployed",
        isCrawler = true
    }
}

-- Day Psycho at player location
function spawnDayPsycho()
    local sq = getPlayer():getCurrentSquare()
    sendClientCommand('PsychoZed', 'doSpawn', {x = sq:getX() + 30, y = sq:getY() + 30, z = sq:getZ(), count = 1, fit = 'Psycho1', fChance = 100, isDown = false})
    print("Spawning Day Psycho (Psycho1)")
end

-- Night Psycho at player location
function spawnNightPsycho()
    local sq = getPlayer():getCurrentSquare()
    sendClientCommand('PsychoZed', 'doSpawn', {x = sq:getX() + 30, y = sq:getY() + 30, z = sq:getZ(), count = 1, fit = 'Psycho2', fChance = 100, isDown = false})
    print("Spawning Night Psycho (Psycho2)")
end

-- Knocked down Day Psycho
function spawnDayPsychoDown()
    local sq = getPlayer():getCurrentSquare()
    sendClientCommand('PsychoZed', 'doSpawn', {x = sq:getX() + 30, y = sq:getY() + 30, z = sq:getZ(), count = 1, fit = 'Psycho1', fChance = 100, isDown = true})
    print("Spawning knocked down Day Psycho")
end

-- At specific coordinates
function spawnPsychoAt(x, y, z, psychoType, isDown)
    psychoType = psychoType or 'Psycho1'
    isDown = isDown or false
    z = z or 0
    sendClientCommand('PsychoZed', 'doSpawn', {x = x, y = y, z = z, count = 1, fit = psychoType, fChance = 100, isDown = isDown})
    print("Spawning " .. psychoType .. " at " .. x .. ", " .. y .. ", " .. z)
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
    zombieType = zombieType or "normal"
    safeRadius = safeRadius or 0 -- Default to 0 (no safe radius)

    -- Send request to server
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
    zombieType = zombieType or "normal"
    z = z or 0

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
    zombieType = zombieType or "horde"
    addVariety = addVariety or false
    safeRadius = safeRadius or 0 -- Default to 0 (no safe radius)

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

-- Function to check zombie types
function ZM_ZombieHandler.listZombieTypes()
    print("Available zombie types:")
    for zombieType, data in pairs(ZM_ZombieHandler.ZombieTypes) do
        print("  " .. zombieType .. " - Health: " .. data.health .. ", Strength: " .. data.strength .. ", Walk: " .. data.walkType)
    end
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