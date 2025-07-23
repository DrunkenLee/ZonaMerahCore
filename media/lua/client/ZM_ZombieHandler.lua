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
        outfit = "ArmyCamoGreen",
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
        health = 60,
        strength = 1,
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

-- Function to spawn zombie at player location
function ZM_ZombieHandler.spawnZombieAtPlayer(zombieType, count)
    local player = getPlayer()
    if not player then
        print("Error: No player found")
        return false
    end

    count = count or 1
    zombieType = zombieType or "normal"

    -- Send request to server
    sendClientCommand("ZM_ZombieHandler", "spawnZombieAtPlayer", {
        username = player:getUsername(),
        zombieType = zombieType,
        count = count,
        x = player:getX(),
        y = player:getY(),
        z = player:getZ()
    })

    player:Say("Requesting " .. count .. " " .. zombieType .. " zombie(s)...")
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

    player:Say("Requesting " .. count .. " " .. zombieType .. " zombie(s) at coordinates...")
    return true
end

-- Function to spawn horde around player
function ZM_ZombieHandler.spawnHorde(count, radius, isTargeted, targetUsername, zombieType, addVariety)
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

    sendClientCommand("ZM_ZombieHandler", "spawnHorde", {
        username = player:getUsername(),
        count = count,
        radius = radius,
        isTargeted = isTargeted,
        targetUsername = targetUsername,
        zombieType = zombieType,
        addVariety = addVariety,
        x = player:getX(),
        y = player:getY(),
        z = player:getZ()
    })

    local message = "Requesting horde of " .. count .. " " .. zombieType .. " zombies..."
    if isTargeted and targetUsername then
        message = message .. " targeting " .. targetUsername
    end
    player:Say(message)
    return true
end

-- Console wrapper functions
function ZM_ZombieHandler.consoleSpawnZombie(zombieType, count)
    return ZM_ZombieHandler.spawnZombieAtPlayer(zombieType, count)
end

function ZM_ZombieHandler.consoleSpawnHorde(count, radius, isTargeted, targetUsername, zombieType, addVariety)
    return ZM_ZombieHandler.spawnHorde(count, radius, isTargeted, targetUsername, zombieType, addVariety)
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
                player:Say(args.message)
            end
        elseif command == "spawnError" then
            local player = getPlayer()
            if player and args.error then
                player:Say("Error: " .. args.error)
            end
        end
    end
end)

-- Hook into player context menu
-- Events.OnFillInventoryObjectContextMenu.Add(ZM_ZombieHandler.addZombieSpawnMenu)

return ZM_ZombieHandler