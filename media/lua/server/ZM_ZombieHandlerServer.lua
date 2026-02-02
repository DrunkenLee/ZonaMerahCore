ZM_ZombieHandlerServer = ZM_ZombieHandlerServer or {}

-- NOTE: Using PZ's built-in round() function which returns Integer type
-- Do NOT define custom round() as it returns Double type causing spawn errors

-- Safe accessor for sandbox variables (works even early in server start)
local function getSandboxVar(name, default)
    if SandboxVars and SandboxVars[name] ~= nil then
        return SandboxVars[name]
    end
    if getSandboxOptions then
        local so = getSandboxOptions()
        if so and so.getOptionByName then
            local opt = so:getOptionByName(name)
            if opt and opt.getValue then
                local v = opt:getValue()
                if v ~= nil then return v end
            end
        end
    end
    return default
end

-- Zombie type definitions (same as client)
ZM_ZombieHandlerServer.ZombieTypes = {
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
        health = 150,
        strength = 20,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "Screamer1",
        profession = "Unemployed"
    },
    ["screamer2"] = {
        health = 150,
        strength = 20,
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

function ZM_ZombieHandlerServer.addItemsToZombie(zombie, zombieType)
    if not zombie then return end

    -- Check if zombie loot is enabled in sandbox settings FIRST
    local lootEnabled = getSandboxVar("ZMZombieLootEnabled", true)

    if not lootEnabled then
        -- print("Zombie loot disabled in sandbox settings - no loot will be added")
        return
    end

    local lootMultiplier = getSandboxVar("ZMZombieLootMultiplier", 1.0)
    -- Safe conversion to number for Kahlua
    if type(lootMultiplier) == "string" then
        -- Manual parsing to avoid tonumber bugs
        local str = string.gsub(lootMultiplier, "^%s*(.-)%s*$", "%1")
        if string.match(str, "^%d*%.?%d*$") and str ~= "" and str ~= "." then
            if not string.find(str, "%.") then
                -- Integer
                local num = 0
                for i = 1, string.len(str) do
                    local digit = string.byte(str, i) - 48
                    if digit >= 0 and digit <= 9 then
                        num = num * 10 + digit
                    end
                end
                lootMultiplier = num
            else
                -- Decimal - use default
                lootMultiplier = 1.0
            end
        else
            lootMultiplier = 1.0
        end
    elseif type(lootMultiplier) ~= "number" then
        lootMultiplier = 1.0
    end

    -- Function to parse comma-separated strings
    local function parseCommaString(str, default)
        if not str or str == "" then return default end
        local result = {}
        for item in string.gmatch(str, "([^,]+)") do
            result[#result + 1] = string.gsub(item, "^%s*(.-)%s*$", "%1") -- trim whitespace
        end
        return result
    end

    -- Function to parse comma-separated numbers (Kahlua-safe)
    local function parseCommaNumbers(str, default)
        if not str or str == "" then return default end
        local result = {}
        for item in string.gmatch(str, "([^,]+)") do
            local trimmed = string.gsub(item, "^%s*(.-)%s*$", "%1")
            local num = nil

            -- Safe number parsing for Kahlua
            if trimmed and trimmed ~= "" then
                -- Check if it's a valid number pattern
                if string.match(trimmed, "^%-?%d*%.?%d*$") then
                    -- Manual conversion to avoid Kahlua tonumber bugs
                    local isNegative = string.sub(trimmed, 1, 1) == "-"
                    local cleanNum = isNegative and string.sub(trimmed, 2) or trimmed

                    if cleanNum and cleanNum ~= "" and cleanNum ~= "." then
                        -- Simple integer parsing
                        if not string.find(cleanNum, "%.") then
                            num = 0
                            for i = 1, string.len(cleanNum) do
                                local digit = string.byte(cleanNum, i) - 48
                                if digit >= 0 and digit <= 9 then
                                    num = num * 10 + digit
                                end
                            end
                            if isNegative then num = -num end
                        else
                            -- For decimals, fall back to 1
                            num = 1
                        end
                    end
                end
            end

            result[#result + 1] = (num or 1)
        end
        return result
    end

    -- Function to select random items from loot table based on max items setting
    local function selectRandomLoot(lootTable, maxItems)
        if not lootTable or #lootTable == 0 or maxItems <= 0 then
            return {}
        end

        local availableItems = {}

        -- First, roll chances for all items to see which are available
        for _, lootItem in ipairs(lootTable) do
            local chance = lootItem.chance or 100
            if chance <= 0 then
                -- Skip items with 0% chance
            elseif chance >= 100 then
                -- 100% chance - always available
                availableItems[#availableItems + 1] = lootItem
            else
                -- Roll for chance (1 to 100)
                local roll = ZombRand(1, 101) -- 1-100 inclusive
                if roll <= chance then
                    availableItems[#availableItems + 1] = lootItem
                end
            end
        end

        -- If we have more available items than maxItems, randomly select
        if #availableItems > maxItems then
            local selectedItems = {}
            local tempItems = {}

            -- Copy available items to temp array
            for i, item in ipairs(availableItems) do
                tempItems[i] = item
            end

            -- Randomly select maxItems from available items
            for i = 1, maxItems do
                if #tempItems > 0 then
                    local randomIndex = ZombRand(1, #tempItems + 1) -- 1 to length inclusive
                    selectedItems[#selectedItems + 1] = tempItems[randomIndex]

                    -- Remove selected item from temp array
                    for j = randomIndex, #tempItems - 1 do
                        tempItems[j] = tempItems[j + 1]
                    end
                    tempItems[#tempItems] = nil
                end
            end

            return selectedItems
        end

        -- Return all available items if we have maxItems or fewer
        return availableItems
    end

    -- Build dynamic loot tables from sandbox settings
    local lootTables = {}

    -- Elite zombie loot
    local eliteItems = parseCommaString(getSandboxVar("ZMEliteLootItems", nil), {""})
    local eliteQuantities = parseCommaNumbers(getSandboxVar("ZMEliteLootQuantities", nil), {1, 2, 15})
    local eliteChances = parseCommaNumbers(getSandboxVar("ZMEliteLootChances", nil), {100, 80, 90})
    local eliteMaxItems = getSandboxVar("ZMEliteMaxItems", 3)

    -- print("DEBUG: Elite chances parsed from sandbox: " .. table.concat(eliteChances, ", "))

    local eliteLootTable = {}
    for i, item in ipairs(eliteItems) do
        local finalChance = eliteChances[i] or 100
        eliteLootTable[#eliteLootTable + 1] = {
            item = item,
            quantity = math.max(1, math.floor((eliteQuantities[i] or 1) * lootMultiplier)),
            chance = finalChance
        }
        -- print("DEBUG: Elite item " .. item .. " assigned chance " .. finalChance)
    end
    lootTables["elite"] = eliteLootTable
    lootTables["elite2"] = eliteLootTable -- Same loot for elite2

    -- Screamer1 zombie loot
    local screamer1Items = parseCommaString(getSandboxVar("ZMScreamer1LootItems", nil), {"RMWeapons.SoulThread", "RMWeapons.OblivionCore", "RMWeapons.PhoenixFeather", "RMWeapons.CelestialFragment", "RMWeapons.ApocalypseRelic", "RMWeapons.HeartOfRedZone"})
    local screamer1Quantities = parseCommaNumbers(getSandboxVar("ZMScreamer1LootQuantities", nil), {1, 2, 30})
    local screamer1Chances = parseCommaNumbers(getSandboxVar("ZMScreamer1LootChances", nil), {75, 85, 95})
    local screamer1MaxItems = getSandboxVar("ZMScreamer1MaxItems", 2)

    local screamer1LootTable = {}
    for i, item in ipairs(screamer1Items) do
        screamer1LootTable[#screamer1LootTable + 1] = {
            item = item,
            quantity = math.max(1, math.floor((screamer1Quantities[i] or 1) * lootMultiplier)),
            chance = screamer1Chances[i] or 100
        }
    end
    lootTables["screamer1"] = screamer1LootTable

    -- Screamer2 zombie loot
    local screamer2Items = parseCommaString(getSandboxVar("ZMScreamer2LootItems", nil), {"RMWeapons.SoulThread", "RMWeapons.OblivionCore", "RMWeapons.PhoenixFeather", "RMWeapons.CelestialFragment", "RMWeapons.ApocalypseRelic", "RMWeapons.HeartOfRedZone"})
    local screamer2Quantities = parseCommaNumbers(getSandboxVar("ZMScreamer2LootQuantities", nil), {1, 2, 25})
    local screamer2Chances = parseCommaNumbers(getSandboxVar("ZMScreamer2LootChances", nil), {80, 90, 95})
    local screamer2MaxItems = getSandboxVar("ZMScreamer2MaxItems", 2)

    local screamer2LootTable = {}
    for i, item in ipairs(screamer2Items) do
        screamer2LootTable[#screamer2LootTable + 1] = {
            item = item,
            quantity = math.max(1, math.floor((screamer2Quantities[i] or 1) * lootMultiplier)),
            chance = screamer2Chances[i] or 100
        }
    end
    lootTables["screamer2"] = screamer2LootTable

    -- Psycho1 zombie loot
    local psycho1Items = parseCommaString(getSandboxVar("ZMPsycho1LootItems", nil), {"Base.Knife"})
    local psycho1Quantities = parseCommaNumbers(getSandboxVar("ZMPsycho1LootQuantities", nil), {1, 1})
    local psycho1Chances = parseCommaNumbers(getSandboxVar("ZMPsycho1LootChances", nil), {50, 50})
    local psycho1MaxItems = getSandboxVar("ZMPsycho1MaxItems", 1)

    local psycho1LootTable = {}
    for i, item in ipairs(psycho1Items) do
        psycho1LootTable[#psycho1LootTable + 1] = {
            item = item,
            quantity = math.max(1, math.floor((psycho1Quantities[i] or 1) * lootMultiplier)),
            chance = psycho1Chances[i] or 100
        }
    end
    lootTables["psycho1"] = psycho1LootTable

    -- Psycho2 zombie loot
    local psycho2Items = parseCommaString(getSandboxVar("ZMPsycho2LootItems", nil), {"Base.Knife"})
    local psycho2Quantities = parseCommaNumbers(getSandboxVar("ZMPsycho2LootQuantities", nil), {1, 1, 1})
    local psycho2Chances = parseCommaNumbers(getSandboxVar("ZMPsycho2LootChances", nil), {60, 60, 40})
    local psycho2MaxItems = getSandboxVar("ZMPsycho2MaxItems", 1)

    local psycho2LootTable = {}
    for i, item in ipairs(psycho2Items) do
        psycho2LootTable[#psycho2LootTable + 1] = {
            item = item,
            quantity = math.max(1, math.floor((psycho2Quantities[i] or 1) * lootMultiplier)),
            chance = psycho2Chances[i] or 100
        }
    end
    lootTables["psycho2"] = psycho2LootTable

    local lootTable = lootTables[zombieType]
    if not lootTable then return end

    -- Get max items for this zombie type
    local maxItems = 999 -- Default to unlimited
    if zombieType == "elite" or zombieType == "elite2" then
        maxItems = eliteMaxItems
    elseif zombieType == "screamer1" then
        maxItems = screamer1MaxItems
    elseif zombieType == "screamer2" then
        maxItems = screamer2MaxItems
    elseif zombieType == "psycho1" then
        maxItems = psycho1MaxItems
    elseif zombieType == "psycho2" then
        maxItems = psycho2MaxItems
    end

    -- Store loot data directly on the zombie object (but don't set ZM_ZombieType here)
    -- Use the new random selection logic
    local selectedLoot = selectRandomLoot(lootTable, maxItems)
    zombie:getModData().ZM_LootTable = selectedLoot

    -- print("Prepared loot for " .. zombieType .. " zombie (loot enabled: " .. tostring(lootEnabled) .. ", multiplier: " .. lootMultiplier .. ", max items: " .. maxItems .. ", selected items: " .. #selectedLoot .. ")")
end

ZM_ZombieHandlerServer.checkLootSettings = function()
    -- print("=== Zona Merah Zombie Loot Settings ===")

    if not SandboxVars then
        -- print("ERROR: SandboxVars is not available!")
        -- print("This usually means the server is still starting up or sandbox settings haven't loaded yet.")
        -- print("=====================================")
        return
    end

    -- print("Loot Enabled: " .. tostring(SandboxVars.ZMZombieLootEnabled))
    -- print("Loot Multiplier: " .. (SandboxVars.ZMZombieLootMultiplier or "default"))
    -- print("")
    -- print("Elite Items: " .. (SandboxVars.ZMEliteLootItems or "default"))
    -- print("Elite Quantities: " .. (SandboxVars.ZMEliteLootQuantities or "default"))
    -- print("Elite Chances: " .. (SandboxVars.ZMEliteLootChances or "default"))
    -- print("Elite Max Items: " .. (SandboxVars.ZMEliteMaxItems or "default"))
    -- print("")
    -- print("Screamer1 Items: " .. (SandboxVars.ZMScreamer1LootItems or "default"))
    -- print("Screamer1 Quantities: " .. (SandboxVars.ZMScreamer1LootQuantities or "default"))
    -- print("Screamer1 Chances: " .. (SandboxVars.ZMScreamer1LootChances or "default"))
    -- print("Screamer1 Max Items: " .. (SandboxVars.ZMScreamer1MaxItems or "default"))
    -- print("")
    -- print("Screamer2 Items: " .. (SandboxVars.ZMScreamer2LootItems or "default"))
    -- print("Screamer2 Quantities: " .. (SandboxVars.ZMScreamer2LootQuantities or "default"))
    -- print("Screamer2 Chances: " .. (SandboxVars.ZMScreamer2LootChances or "default"))
    -- print("Screamer2 Max Items: " .. (SandboxVars.ZMScreamer2MaxItems or "default"))
    -- print("=====================================")
end

-- Debug function to test loot calculation
ZM_ZombieHandlerServer.testLootCalculation = function()
    -- print("=== Testing Elite Loot Calculation ===")

    if not SandboxVars then
        -- print("ERROR: SandboxVars not available!")
        -- print("This means the server hasn't fully loaded or no world is active.")
        -- print("Try:")
        -- print("1. Wait for server to fully start and load a world")
        -- print("2. Create/load a world first")
        -- print("3. Check if mod is properly loaded in the world")
        -- print("========================================")
        return
    end

    -- print("ZMZombieLootEnabled: " .. tostring(SandboxVars.ZMZombieLootEnabled))
    -- print("ZMEliteLootChances: " .. tostring(SandboxVars.ZMEliteLootChances))

    -- Test parsing (Kahlua-safe version)
    local function parseCommaNumbers(str, default)
        if not str or str == "" then return default end
        local result = {}
        for item in string.gmatch(str, "([^,]+)") do
            local trimmed = string.gsub(item, "^%s*(.-)%s*$", "%1")
            local num = nil

            -- Safe number parsing for Kahlua
            if trimmed and trimmed ~= "" then
                -- Check if it's a valid number pattern
                if string.match(trimmed, "^%-?%d*%.?%d*$") then
                    -- Manual conversion to avoid Kahlua tonumber bugs
                    local isNegative = string.sub(trimmed, 1, 1) == "-"
                    local cleanNum = isNegative and string.sub(trimmed, 2) or trimmed

                    if cleanNum and cleanNum ~= "" and cleanNum ~= "." then
                        -- Simple integer parsing
                        if not string.find(cleanNum, "%.") then
                            num = 0
                            for i = 1, string.len(cleanNum) do
                                local digit = string.byte(cleanNum, i) - 48
                                if digit >= 0 and digit <= 9 then
                                    num = num * 10 + digit
                                end
                            end
                            if isNegative then num = -num end
                        else
                            -- For decimals, fall back to 1
                            num = 1
                        end
                    end
                end
            end

            result[#result + 1] = (num or 1)
        end
        return result
    end

    local eliteChances = parseCommaNumbers(SandboxVars.ZMEliteLootChances, {100, 80, 90})
    -- print("Parsed Elite Chances: " .. table.concat(eliteChances, ", "))

    -- print("========================================")
end

-- Zombie death handler
ZM_ZombieHandlerServer.onZombieDeath = function(zombie)
    if not zombie then return end

    local modData = zombie:getModData()

    -- CRITICAL: ONLY process zombies that have the ZM_ZombieType flag set
    -- This flag is ONLY set in createZombie() for special zombies (elite, screamer, etc.)
    -- Normal zombies should NEVER have this flag, so they won't drop any special loot
    if not modData or not modData.ZM_ZombieType then
        -- This is not one of our special zombies, skip loot processing
        return
    end

    local zombieType = modData.ZM_ZombieType

    -- Verify this is a valid zombie type that should have loot
    if not ZM_ZombieHandlerServer.ZombieTypes[zombieType] then
        -- Invalid zombie type, skip
        return
    end

    -- OUTFIT VALIDATION: Verify the zombie's outfit matches the expected outfit for this type
    -- This prevents old/corrupted data from causing wrong loot drops
    local zombieData = ZM_ZombieHandlerServer.ZombieTypes[zombieType]
    local zombieOutfit = zombie:getOutfitName() or nil

    if zombieOutfit ~= zombieData.outfit then
        -- CRITICAL: Zombie has wrong outfit for this type!
        -- This likely means it's an old zombie with corrupted data or a regular zombie
        -- that somehow got tagged incorrectly. Clear the invalid data and don't drop loot.
        print("[ZM_ZombieHandler] WARNING: Zombie has ZM_ZombieType='" .. zombieType ..
              "' but outfit='" .. tostring(zombieOutfit) .. "' (expected '" .. zombieData.outfit ..
              "'). Clearing invalid data.")
        modData.ZM_ZombieType = nil
        modData.ZM_LootTable = nil
        return
    end

    -- Recalculate loot based on current sandbox settings
    -- This ensures that any changes to loot settings after zombie spawned are applied
    -- print("Recalculating loot for " .. zombieType .. " zombie based on current settings")

    -- Clear old loot table and recalculate with current settings
    -- Note: addItemsToZombie does NOT modify ZM_ZombieType, only prepares the loot table
    modData.ZM_LootTable = nil
    ZM_ZombieHandlerServer.addItemsToZombie(zombie, zombieType)

    -- Use the newly calculated loot table
    modData = zombie:getModData()

    -- Drop loot ONLY if we have a loot table AND a valid zombie type
    if modData and modData.ZM_LootTable and modData.ZM_ZombieType then
        local square = zombie:getSquare()
        if square then
            for _, lootItem in ipairs(modData.ZM_LootTable) do
                for i = 1, (lootItem.quantity or 1) do
                    square:AddWorldInventoryItem(lootItem.item, 0, 0, 0)
                end
                -- print("Dropped " .. lootItem.item .. " from " .. zombieType .. " zombie")
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
        -- print("Error: Unknown zombie type: " .. tostring(zombieType))
        return nil
    end

    local x, y, z = square:getX(), square:getY(), square:getZ()

    -- Convert coordinates to integers to avoid Double type issues
    local ix = math.floor(x)
    local iy = math.floor(y)
    local iz = math.floor(z)

    -- Use addZombiesInOutfitArea with explicit integer conversion
    -- Signature: addZombiesInOutfitArea(int x1, int y1, int x2, int y2, int z, int totalZombies, String outfit, Integer femaleChance)
    local zombieList = addZombiesInOutfitArea(
        ix, iy,         -- x1, y1 (start coordinates) - integers
        ix, iy,         -- x2, y2 (end coordinates - same as start for single tile) - integers
        iz,             -- z level - integer
        1,              -- totalZombies - integer
        zombieData.outfit or "Random",  -- outfit - string
        nil             -- femaleChance - nil means random (or use 50)
    )

    print("[ZM_ZombieHandlerServer] Called addZombiesInOutfitArea for " .. zombieData.outfit .. " zombie at (" .. ix .. ", " .. iy .. ", " .. iz .. ")")

    -- Get the zombie from the returned list or from the square
    local zombie = nil

    if zombieList and zombieList:size() > 0 then
        zombie = zombieList:get(0)
        print("[ZM_ZombieHandlerServer] Found zombie from returned list")
    else
        -- Fallback: search the square's moving objects
        local zombies = square:getMovingObjects()
        for i = zombies:size() - 1, 0, -1 do
            local obj = zombies:get(i)
            if instanceof(obj, "IsoZombie") then
                zombie = obj
                print("[ZM_ZombieHandlerServer] Found zombie from square search")
                break
            end
        end
    end

    if not zombie then
        print("[ZM_ZombieHandlerServer] Error: Could not find spawned zombie")
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

    -- Additional configuration for screamers
    if zombieType == "screamer1" or zombieType == "screamer2" then
        -- zombie:setVariable("isScreamerII", true)
    end

    -- Call the function to add loot to the zombie
    ZM_ZombieHandlerServer.addItemsToZombie(zombie, zombieType)

    -- IMPORTANT: Set the zombie type AFTER adding loot to mark this as a special zombie
    zombie:getModData().ZM_ZombieType = zombieType

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

    local zombieType = args.zombieType or "elite"

    -- Skip if it's a Psycho zombie - those are handled by PsychoZed mod on client side
    if zombieType == "psycho1" or zombieType == "psycho2" then
        -- print("[ZM_ZombieHandler] Skipping Psycho zombie spawn - handled by PsychoZed mod")
        return
    end

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

    -- print("[ZM_ZombieHandler] " .. player:getUsername() .. " spawned " .. spawnedCount .. " " .. zombieType .. " zombies")
end

-- Function to spawn zombie at specific coordinates
function ZM_ZombieHandlerServer.spawnZombieAtCoords(player, args)
    local zombieType = args.zombieType or "elite"

    -- Skip if it's a Psycho zombie - those are handled by PsychoZed mod on client side
    if zombieType == "psycho1" or zombieType == "psycho2" then
        -- print("[ZM_ZombieHandler] Skipping Psycho zombie spawn - handled by PsychoZed mod")
        return
    end

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
    local count = math.min(args.count or 10, 100) -- Limit to 100 zombies max for horde
    local radius = args.radius or 5
    local safeRadius = args.safeRadius or 0
    local isTargeted = args.isTargeted or false
    local targetUsername = args.targetUsername
    local targetPlayer = nil
    local spawnedCount = 0
    local failedCount = 0
    local zombieType = args.zombieType or "elite"

    -- Skip if it's a Psycho zombie - those are handled by PsychoZed mod on client side
    if zombieType == "psycho1" or zombieType == "psycho2" then
        -- print("[ZM_ZombieHandler] Skipping Psycho zombie horde spawn - handled by PsychoZed mod")
        return
    end

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

    -- print("[ZM_ZombieHandler] " .. player:getUsername() .. " spawned horde of " .. spawnedCount .. " " .. zombieType .. " zombies" ..
    --       (isTargeted and targetPlayer and (" targeting " .. targetPlayer:getUsername()) or ""))
end

-- Function to spawn boss zombie with minions
function ZM_ZombieHandlerServer.spawnBossWithMinions(player, args)

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

-- Function to find and remove ritual items from a 5x5 area around player
function ZM_ZombieHandlerServer.consumeRitualItems(player, playerX, playerY, playerZ)
    if not player then return false end

    local requiredItems = {
        "RMWeapons.DragonsteelIngot",
        "RMWeapons.EldritchWood",
        "RMWeapons.SoulThread"
    }

    local itemFound = false
    local consumedItem = nil

    -- Check 5x5 area around player (-2 to +2 from player position)
    for x = playerX - 2, playerX + 2 do
        for y = playerY - 2, playerY + 2 do
            local square = getCell():getGridSquare(x, y, playerZ)
            if square and not itemFound then
                -- Check for world objects that might contain items
                local objects = square:getWorldObjects()
                if objects then
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj and obj.getContainer and not itemFound then
                            local container = obj:getContainer()
                            if container then
                                local items = container:getItems()
                                for j = 0, items:size() - 1 do
                                    local item = items:get(j)
                                    if item and not itemFound then
                                        local fullType = item:getFullType()
                                        for _, requiredItem in ipairs(requiredItems) do
                                            if fullType == requiredItem then
                                                -- Remove the item from container
                                                container:Remove(item)
                                                itemFound = true
                                                consumedItem = requiredItem
                                                print("[ZM_ZombieHandlerServer] Consumed " .. requiredItem .. " from container at (" .. x .. "," .. y .. "," .. playerZ .. ")")
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- Also check items directly on the ground (IsoWorldInventoryObject)
                if not itemFound then
                    local worldObjects = square:getWorldObjects()
                    if worldObjects and worldObjects:size() > 0 then
                        for j = 0, worldObjects:size() - 1 do
                            local worldObj = worldObjects:get(j)
                            if worldObj and worldObj.getItem and not itemFound then
                                local item = worldObj:getItem()
                                if item then
                                    local fullType = item:getFullType()
                                    for _, requiredItem in ipairs(requiredItems) do
                                        if fullType == requiredItem then
                                            -- Remove the world inventory object
                                            square:removeWorldObject(worldObj)
                                            itemFound = true
                                            consumedItem = requiredItem
                                            print("[ZM_ZombieHandlerServer] Consumed " .. requiredItem .. " from ground at (" .. x .. "," .. y .. "," .. playerZ .. ")")
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return itemFound, consumedItem
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
        elseif command == "consumeRitualItems" then
            -- Handle ritual item consumption
            local playerX = args.playerX or player:getX()
            local playerY = args.playerY or player:getY()
            local playerZ = args.playerZ or player:getZ()

            local success, consumedItem = ZM_ZombieHandlerServer.consumeRitualItems(player, playerX, playerY, playerZ)

            -- Send response back to client
            sendServerCommand(player, "ZM_ZombieHandler", "ritualItemConsumed", {
                success = success,
                consumedItem = consumedItem
            })
        elseif command == "checkLootSettings" then
            -- Only admins can check loot settings
            if player:isAccessLevel("admin") then
                ZM_ZombieHandlerServer.checkLootSettings()
            else
                -- print("[ZM_ZombieHandler] Non-admin user " .. player:getUsername() .. " tried to check loot settings")
            end
        elseif command == "testLootCalculation" then
            -- Only admins can test loot calculation
            if player:isAccessLevel("admin") then
                ZM_ZombieHandlerServer.testLootCalculation()
            else
                -- print("[ZM_ZombieHandler] Non-admin user " .. player:getUsername() .. " tried to test loot calculation")
            end
        elseif command == "checkSandboxStatus" then
            -- Only admins can check sandbox status
            if player:isAccessLevel("admin") then

            else
                -- print("[ZM_ZombieHandler] Non-admin user " .. player:getUsername() .. " tried to check sandbox status")
            end
        end
    end
end)

return ZM_ZombieHandlerServer