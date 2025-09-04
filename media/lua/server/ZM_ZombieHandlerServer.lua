ZM_ZombieHandlerServer = ZM_ZombieHandlerServer or {}

-- Zombie type definitions (same as client)
ZM_ZombieHandlerServer.ZombieTypes = {
    ["normal"] = {
        health = 150,
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
        health = 150,
        strength = 1,
        fitness = 2,
        walkType = "shamble",
        canSprint = false,
        outfit = "Naked",
        profession = "Unemployed"
    },
    ["elite"] = {
        health = 200,
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

function ZM_ZombieHandlerServer.addItemsToZombie(zombie, zombieType)
    if not zombie then return end

    -- Safety check for SandBoxVars
    if not SandBoxVars then
        print("SandBoxVars not available, using default loot settings")
        -- Use hardcoded defaults when sandbox vars aren't available
        local defaultLootTables = {
            ["elite"] = {
                {item = "Base.Axe", quantity = 1, chance = 100}
            },
            ["boss"] = {
                {item = "Base.Katana", quantity = 1, chance = 100}
            },
            ["tank"] = {
                {item = "Base.Sledgehammer", quantity = 1, chance = 60}
            }
        }

        local lootTable = defaultLootTables[zombieType]
        if lootTable then
            zombie:getModData().ZM_LootTable = {}
            zombie:getModData().ZM_ZombieType = zombieType

            for _, lootItem in ipairs(lootTable) do
                if ZombRand(100) < lootItem.chance then
                    table.insert(zombie:getModData().ZM_LootTable, lootItem)
                    print("Added " .. lootItem.item .. " to " .. zombieType .. " loot table (default settings)")
                end
            end
        end
        return
    end

    -- Check if zombie loot is enabled in sandbox settings
    local lootEnabled = SandBoxVars.ZMZombieLootEnabled
    if lootEnabled == nil then
        lootEnabled = true -- Default to true if not set
    end

    if not lootEnabled then
        print("Zombie loot disabled in sandbox settings")
        return
    end

    local lootMultiplier = SandBoxVars.ZMZombieLootMultiplier or 1.0

    -- Function to parse comma-separated strings
    local function parseCommaString(str, default)
        if not str or str == "" then return default end
        local result = {}
        for item in string.gmatch(str, "([^,]+)") do
            table.insert(result, string.gsub(item, "^%s*(.-)%s*$", "%1")) -- trim whitespace
        end
        return result
    end

    -- Function to parse comma-separated numbers
    local function parseCommaNumbers(str, default)
        if not str or str == "" then return default end
        local result = {}
        for item in string.gmatch(str, "([^,]+)") do
            local num = tonumber(string.gsub(item, "^%s*(.-)%s*$", "%1"))
            table.insert(result, num or 1)
        end
        return result
    end

    -- Build dynamic loot tables from sandbox settings
    local lootTables = {}

    -- Elite zombie loot
    local eliteItems = parseCommaString(SandBoxVars.ZMEliteLootItems, {"Base.Axe", "Base.9mmClip", "Base.Bullets9mm"})
    local eliteQuantities = parseCommaNumbers(SandBoxVars.ZMEliteLootQuantities, {1, 2, 15})
    local eliteChances = parseCommaNumbers(SandBoxVars.ZMEliteLootChances, {100, 80, 90})

    print("DEBUG: Elite chances parsed from sandbox: " .. table.concat(eliteChances, ", "))

    lootTables["elite"] = {}
    for i, item in ipairs(eliteItems) do
        local finalChance = eliteChances[i] or 100
        table.insert(lootTables["elite"], {
            item = item,
            quantity = math.max(1, math.floor((eliteQuantities[i] or 1) * lootMultiplier)),
            chance = finalChance
        })
        print("DEBUG: Elite item " .. item .. " assigned chance " .. finalChance)
    end

    -- Boss zombie loot
    local bossItems = parseCommaString(SandBoxVars.ZMBossLootItems, {"Base.Katana", "Base.ShotgunShells", "Base.FirstAidKit"})
    local bossQuantities = parseCommaNumbers(SandBoxVars.ZMBossLootQuantities, {1, 10, 1})
    local bossChances = parseCommaNumbers(SandBoxVars.ZMBossLootChances, {100, 90, 70})

    lootTables["boss"] = {}
    for i, item in ipairs(bossItems) do
        table.insert(lootTables["boss"], {
            item = item,
            quantity = math.max(1, math.floor((bossQuantities[i] or 1) * lootMultiplier)),
            chance = bossChances[i] or 100
        })
    end

    -- Tank zombie loot
    local tankItems = parseCommaString(SandBoxVars.ZMTankLootItems, {"Base.Sledgehammer", "Base.Pills"})
    local tankQuantities = parseCommaNumbers(SandBoxVars.ZMTankLootQuantities, {1, 2})
    local tankChances = parseCommaNumbers(SandBoxVars.ZMTankLootChances, {60, 50})

    lootTables["tank"] = {}
    for i, item in ipairs(tankItems) do
        table.insert(lootTables["tank"], {
            item = item,
            quantity = math.max(1, math.floor((tankQuantities[i] or 1) * lootMultiplier)),
            chance = tankChances[i] or 100
        })
    end

    local lootTable = lootTables[zombieType]
    if not lootTable then return end

    -- Store loot data directly on the zombie object
    zombie:getModData().ZM_LootTable = {}
    zombie:getModData().ZM_ZombieType = zombieType

    -- Determine what loot this zombie will drop
    for _, lootItem in ipairs(lootTable) do
        local chance = lootItem.chance or 100
        print("DEBUG: Item " .. lootItem.item .. " has chance " .. chance .. " for " .. zombieType)

        -- Ensure chance is never negative and handle 0 case explicitly
        if chance <= 0 then
            print("Skipped " .. lootItem.item .. " for " .. zombieType .. " (chance: " .. chance .. "% - disabled)")
        elseif chance >= 100 then
            -- 100% chance - always add
            table.insert(zombie:getModData().ZM_LootTable, lootItem)
            print("Added " .. lootItem.item .. " to " .. zombieType .. " loot table (chance: " .. chance .. "% - guaranteed)")
        else
            -- Roll for chance (1 to 100)
            local roll = ZombRand(1, 101) -- 1-100 inclusive
            if roll <= chance then
                table.insert(zombie:getModData().ZM_LootTable, lootItem)
                print("Added " .. lootItem.item .. " to " .. zombieType .. " loot table (chance: " .. chance .. "%, rolled: " .. roll .. ")")
            else
                print("Failed to add " .. lootItem.item .. " to " .. zombieType .. " loot table (chance: " .. chance .. "%, rolled: " .. roll .. ")")
            end
        end
    end

    print("Prepared loot for " .. zombieType .. " zombie (loot enabled: " .. tostring(lootEnabled) .. ", multiplier: " .. lootMultiplier .. ")")
end

ZM_ZombieHandlerServer.checkLootSettings = function()
    print("=== Zona Merah Zombie Loot Settings ===")
    print("Loot Enabled: " .. tostring(SandBoxVars.ZMZombieLootEnabled))
    print("Loot Multiplier: " .. (SandBoxVars.ZMZombieLootMultiplier or "default"))
    print("")
    print("Elite Items: " .. (SandBoxVars.ZMEliteLootItems or "default"))
    print("Elite Quantities: " .. (SandBoxVars.ZMEliteLootQuantities or "default"))
    print("Elite Chances: " .. (SandBoxVars.ZMEliteLootChances or "default"))
    print("")
    print("Boss Items: " .. (SandBoxVars.ZMBossLootItems or "default"))
    print("Boss Quantities: " .. (SandBoxVars.ZMBossLootQuantities or "default"))
    print("Boss Chances: " .. (SandBoxVars.ZMBossLootChances or "default"))
    print("")
    print("Tank Items: " .. (SandBoxVars.ZMTankLootItems or "default"))
    print("Tank Quantities: " .. (SandBoxVars.ZMTankLootQuantities or "default"))
    print("Tank Chances: " .. (SandBoxVars.ZMTankLootChances or "default"))
    print("=====================================")
end

-- Zombie death handler
ZM_ZombieHandlerServer.onZombieDeath = function(zombie)
    if not zombie then return end

    local modData = zombie:getModData()
    if modData and modData.ZM_LootTable then
        local square = zombie:getSquare()
        if square then
            for _, lootItem in ipairs(modData.ZM_LootTable) do
                for i = 1, (lootItem.quantity or 1) do
                    square:AddWorldInventoryItem(lootItem.item, 0, 0, 0)
                end
                print("Dropped " .. lootItem.item .. " from " .. (modData.ZM_ZombieType or "unknown") .. " zombie")
            end
        end
    end
end

Events.OnZombieDead.Add(ZM_ZombieHandlerServer.onZombieDeath)

-- Function to create and configure a zombie
function ZM_ZombieHandlerServer.createZombie(square, zombieType)
    if not square then return nil end

    local zombieData = ZM_ZombieHandlerServer.ZombieTypes[zombieType]
    if not zombieData then
        print("Error: Unknown zombie type: " .. tostring(zombieType))
        return nil
    end

    local x, y, z = square:getX(), square:getY(), square:getZ()

    addZombiesInOutfit(
        x, y, z, 1,  -- coordinates and count
        zombieData.outfit or "Random",  -- outfit
        0.5,  -- femChance
        zombieData.isCrawler or false,  -- isCrawler
        false,  -- isFallOnFront
        false,  -- isFakeDead
        false,  -- isKnockedDown
        1.0
    )

    local zombies = square:getMovingObjects()
    local zombie = nil

    for i = zombies:size() - 1, 0, -1 do
        local obj = zombies:get(i)
        if instanceof(obj, "IsoZombie") then
            zombie = obj
            break
        end
    end

    if not zombie then
        print("Error: Could not find spawned zombie")
        return nil
    end

    zombie:setHealth(zombieData.health)
    if zombie:getStats() then

    end

    -- Configure movement
    if zombie.setWalkType then
        zombie:setWalkType(zombieData.walkType)
    end
    if zombie.setCanSprint then
        zombie:setCanSprint(zombieData.canSprint)
    end
    if zombie.setCanWalk then
        zombie:setCanWalk(true)
    end
    if zombie.setCanAttack then
        zombie:setCanAttack(true)
    end
    if zombie.setUseless then
        zombie:setUseless(false)
    end
    if zombie.makeInactive then
        zombie:makeInactive(false)
    end

    -- Additional configuration for special types
    if zombieType == "boss" then
        if zombie:getBodyDamage() then
            zombie:getBodyDamage():setOverallBodyHealth(zombieData.health)
            zombie:getBodyDamage():setInfectionLevel(0)
        end
    elseif zombieType == "tank" then
        if zombie:getBodyDamage() then
            zombie:getBodyDamage():setOverallBodyHealth(zombieData.health * 1.5)
        end
    end

    -- ADD THIS LINE - Call the function to add loot to the zombie
    ZM_ZombieHandlerServer.addItemsToZombie(zombie, zombieType)

    return zombie
end

-- Add this function to check if any player is within the safe radius
function ZM_ZombieHandlerServer.isPlayerNearby(x, y, z, radius)
    if not radius or radius <= 0 then return false end

    for i = 0, getOnlinePlayers():size() - 1 do
        local player = getOnlinePlayers():get(i)
        if player and not player:isDead() then
            local px, py, pz = player:getX(), player:getY(), player:getZ()
            if pz == z then
                local dist = math.sqrt((px - x)^2 + (py - y)^2)
                if dist <= radius then
                    return true
                end
            end
        end
    end
    return false
end

-- Function to spawn zombie at player location
function ZM_ZombieHandlerServer.spawnZombieAtPlayer(player, args)
    -- Add admin check
    if not player:isAccessLevel("admin") then
        sendServerCommand(player, "ZM_ZombieHandler", "spawnError", {
            error = "Only admins can spawn zombies"
        })
        return
    end

    local zombieType = args.zombieType or "normal"
    local count = math.min(args.count or 1, 50) -- Limit to 50 zombies max
    local safeRadius = args.safeRadius or 0
    local spawnedCount = 0
    local failedCount = 0

    for i = 1, count do
        -- Try up to 5 times to find a valid spawn location outside safeRadius
        local maxAttempts = 5
        local validSquareFound = false

        for attempt = 1, maxAttempts do
            -- Get random square around player
            local radius = math.max(5, safeRadius) -- Use at least 5 tiles radius for spawning
            local angle = ZombRand(0, 360) * math.pi / 180
            local distance = safeRadius + ZombRand(5, radius)

            local x = args.x + math.cos(angle) * distance
            local y = args.y + math.sin(angle) * distance
            local square = getCell():getGridSquare(x, y, args.z or 0)

            -- Check if square is valid and no player is within safeRadius
            if square and not ZM_ZombieHandlerServer.isPlayerNearby(x, y, args.z or 0, safeRadius) then
                local zombie = ZM_ZombieHandlerServer.createZombie(square, zombieType)
                if zombie then
                    spawnedCount = spawnedCount + 1
                    validSquareFound = true
                    break
                end
            end
        end

        if not validSquareFound then
            failedCount = failedCount + 1
        end
    end

    local message = "Spawned " .. spawnedCount .. " " .. zombieType .. " zombie(s)!"
    if failedCount > 0 then
        message = message .. " (" .. failedCount .. " failed due to safe radius constraints)"
    end

    sendServerCommand(player, "ZM_ZombieHandler", "zombieSpawned", {
        message = message
    })

    print("[ZM_ZombieHandler] " .. player:getUsername() .. " spawned " .. spawnedCount .. " " .. zombieType .. " zombies")
end

-- Function to spawn zombie at specific coordinates
function ZM_ZombieHandlerServer.spawnZombieAtCoords(player, args)
    if not player:isAccessLevel("admin") then
        sendServerCommand(player, "ZM_ZombieHandler", "spawnError", {
            error = "Only admins can spawn zombies"
        })
        return
    end

    local zombieType = args.zombieType or "normal"
    local count = math.min(args.count or 1, 50)
    local spawnedCount = 0

    for i = 1, count do
        local x = args.x + ZombRand(-1, 1)
        local y = args.y + ZombRand(-1, 1)
        local square = getCell():getGridSquare(x, y, args.z or 0)

        if square  then
            local zombie = ZM_ZombieHandlerServer.createZombie(square, zombieType)
            if zombie then
                spawnedCount = spawnedCount + 1
            end
        end
    end

    sendServerCommand(player, "ZM_ZombieHandler", "zombieSpawned", {
        message = "Spawned " .. spawnedCount .. " " .. zombieType .. " zombie(s) at coordinates!"
    })
end

-- Modify the spawnHorde function to use safeRadius
function ZM_ZombieHandlerServer.spawnHorde(player, args)
    if not player:isAccessLevel("admin") then
        sendServerCommand(player, "ZM_ZombieHandler", "spawnError", {
            error = "Only admins can spawn zombies"
        })
        return
    end

    local count = math.min(args.count or 10, 100) -- Limit to 100 zombies max for horde
    local radius = args.radius or 5
    local safeRadius = args.safeRadius or 0
    local isTargeted = args.isTargeted or false
    local targetUsername = args.targetUsername
    local targetPlayer = nil
    local spawnedCount = 0
    local failedCount = 0
    local zombieType = args.zombieType or "horde"

    -- Validate zombie type
    if not ZM_ZombieHandlerServer.ZombieTypes[zombieType] then
        sendServerCommand(player, "ZM_ZombieHandler", "spawnError", {
            error = "Invalid zombie type: " .. tostring(zombieType)
        })
        return
    end

    -- Find target player if targeting is enabled
    if isTargeted and targetUsername then
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            if p:getUsername() == targetUsername then
                targetPlayer = p
                break
            end
        end

        if not targetPlayer then
            sendServerCommand(player, "ZM_ZombieHandler", "spawnError", {
                error = "Target player '" .. targetUsername .. "' not found online"
            })
            return
        end
    end

    -- Try to spawn each zombie
    for i = 1, count do
        -- Try up to 5 times to find a valid spawn location
        local maxAttempts = 5
        local validSquareFound = false

        for attempt = 1, maxAttempts do
            -- Calculate spawn position
            local angle = ZombRand(0, 360) * math.pi / 180
            local distance = safeRadius + ZombRand(1, radius - safeRadius)
            if distance < 1 then distance = 1 end -- Ensure minimum distance

            local x = args.x + math.cos(angle) * distance
            local y = args.y + math.sin(angle) * distance
            local square = getCell():getGridSquare(x, y, args.z or 0)

            -- Check if square is valid and outside safeRadius
            if square and not ZM_ZombieHandlerServer.isPlayerNearby(x, y, args.z or 0, safeRadius) then
                -- Determine zombie type (possibly with variety)
                local currentZombieType = zombieType
                local addVariety = args.addVariety or false

                if addVariety and zombieType == "horde" then
                    -- Mix of zombie types for variety
                    if ZombRand(100) < 15 then -- 15% chance for special zombies
                        local specialTypes = {"elite", "elite", "elite"}
                        currentZombieType = specialTypes[ZombRand(#specialTypes) + 1]
                    end
                end

                -- Create the zombie
                local zombie = ZM_ZombieHandlerServer.createZombie(square, currentZombieType)
                if zombie then
                    spawnedCount = spawnedCount + 1
                    validSquareFound = true

                    -- Set zombie target if targeting is enabled
                    if isTargeted and targetPlayer then
                        zombie:setTarget(targetPlayer)
                        -- zombie:setTargetSeenTime(108000)
                        zombie:setStaggerBack(false)
                        zombie:pathToCharacter(targetPlayer)
                        zombie:setBecomeCrawler(false)
                        zombie:setFallOnFront(false)
                        zombie:setKnockedDown(false)

                        if zombie:getStats() then
                            zombie:getStats():setAnger(1.0)
                            zombie:getStats():setStress(1.0)
                        end
                    end

                    break
                end
            end
        end

        if not validSquareFound then
            failedCount = failedCount + 1
        end
    end

    -- Report results
    local message = "Spawned horde of " .. spawnedCount .. " " .. zombieType .. " zombies!"
    if failedCount > 0 then
        message = message .. " (" .. failedCount .. " failed due to safe radius constraints)"
    end

    if isTargeted and targetPlayer then
        message = message .. " Targeting: " .. targetPlayer:getUsername()
    end

    sendServerCommand(player, "ZM_ZombieHandler", "zombieSpawned", {
        message = message
    })

    print("[ZM_ZombieHandler] " .. player:getUsername() .. " spawned horde of " .. spawnedCount .. " " .. zombieType .. " zombies" ..
          (isTargeted and targetPlayer and (" targeting " .. targetPlayer:getUsername()) or ""))
end

-- Function to spawn boss zombie with minions
function ZM_ZombieHandlerServer.spawnBossWithMinions(player, args)
    if not player:isAccessLevel("admin") then
        sendServerCommand(player, "ZM_ZombieHandler", "spawnError", {
            error = "Only admins can spawn zombies"
        })
        return
    end

    local spawnedCount = 0

    -- Spawn boss at center
    local bossSquare = getCell():getGridSquare(args.x, args.y, args.z or 0)
    if bossSquare then
        local boss = ZM_ZombieHandlerServer.createZombie(bossSquare, "boss")
        if boss then
            spawnedCount = spawnedCount + 1

            -- Spawn minions around boss
            for i = 1, 6 do
                local x = args.x + ZombRand(-3, 3)
                local y = args.y + ZombRand(-3, 3)
                local square = getCell():getGridSquare(x, y, args.z or 0)

                if square  then
                    local minionType = (i <= 2) and "elite" or "runner"
                    local minion = ZM_ZombieHandlerServer.createZombie(square, minionType)
                    if minion then
                        spawnedCount = spawnedCount + 1
                    end
                end
            end
        end
    end

    sendServerCommand(player, "ZM_ZombieHandler", "zombieSpawned", {
        message = "Spawned boss zombie with " .. (spawnedCount - 1) .. " minions!"
    })
end

-- Command handler
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ZM_ZombieHandler" then
        if command == "spawnZombieAtPlayer" then
            ZM_ZombieHandlerServer.spawnZombieAtPlayer(player, args)
        elseif command == "spawnZombieAtCoords" then
            ZM_ZombieHandlerServer.spawnZombieAtCoords(player, args)
        elseif command == "spawnHorde" then
            ZM_ZombieHandlerServer.spawnHorde(player, args)
        elseif command == "spawnBossWithMinions" then
            ZM_ZombieHandlerServer.spawnBossWithMinions(player, args)
        end
    end
end)

return ZM_ZombieHandlerServer