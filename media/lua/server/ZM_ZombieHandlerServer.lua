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
        walkType = "sprint2",
        canSprint = true,
        outfit = "ArmyCamoDesert",
        profession = "Soldier"
    },
    ["screamer1"] = {
        health = 150,
        strength = 20,
        fitness = 3,
        walkType = "WTSprint2",
        canSprint = true,
        outfit = "Screamer1",
        profession = "Unemployed"
    },
    ["screamer2"] = {
        health = 150,
        strength = 20,
        fitness = 4,
        walkType = "WTSprint2",
        canSprint = true,
        outfit = "Screamer2",
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
    ["bank_robber"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "BankRobberSuit",
        profession = "Unemployed"
    },
    ["bounty_hunter"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "BountyHunter",
        profession = "Unemployed"
    },
    ["beast_mom"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "CostumeBeastMom",
        profession = "Unemployed"
    },
    ["chunk"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "CostumeChunk",
        profession = "Unemployed"
    },
    ["commando_john"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "CostumeCommandoJohn",
        profession = "Unemployed"
    },
    ["ghillie"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "Ghillie",
        profession = "Unemployed"
    },
    ["hunter"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "Hunter",
        profession = "Unemployed"
    },
    ["ice_hockey_white"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "IceHockey_White",
        profession = "Unemployed"
    },
    ["ice_hockey_goalie"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "IceHockey_White_Goalie",
        profession = "Unemployed"
    },
    ["punk"] = {
        health = 150,
        strength = 40,
        fitness = 3,
        walkType = "sprint1",
        canSprint = true,
        outfit = "Punk",
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

-- Weighted spawn pool that includes every zombie type in ZombieTypes.
-- Higher weight = higher spawn chance.
ZM_ZombieHandlerServer.ZoneSpawnWeights = ZM_ZombieHandlerServer.ZoneSpawnWeights or {
    elite = 8,
    elite2 = 7,
    screamer1 = 11,
    screamer2 = 11,
    bandit_late = 9,
    bandit_mid = 9,
    biker = 8,
    monster_bride = 6,
    bank_robber = 8,
    bounty_hunter = 8,
    beast_mom = 6,
    chunk = 6,
    commando_john = 7,
    ghillie = 8,
    hunter = 8,
    ice_hockey_white = 6,
    ice_hockey_goalie = 5,
    punk = 7,
    nightmares = 4
}

local function pickWeightedZombieType(weightTable)
    local totalWeight = 0
    for zombieType, weight in pairs(weightTable) do
        if ZM_ZombieHandlerServer.ZombieTypes[zombieType] and type(weight) == "number" and weight > 0 then
            totalWeight = totalWeight + weight
        end
    end

    if totalWeight <= 0 then
        return "elite"
    end

    local roll = ZombRand(totalWeight) + 1
    local runningWeight = 0

    for zombieType, weight in pairs(weightTable) do
        if ZM_ZombieHandlerServer.ZombieTypes[zombieType] and type(weight) == "number" and weight > 0 then
            runningWeight = runningWeight + weight
            if roll <= runningWeight then
                return zombieType
            end
        end
    end

    return "elite"
end

-- Debug flag for sprint enforcement logging
ZM_ZombieHandlerServer.SprintDebug = (ZM_ZombieHandlerServer.SprintDebug ~= false)
ZM_ZombieHandlerServer.PendingSpawns = ZM_ZombieHandlerServer.PendingSpawns or {}

local function sprintLog(message)
    if ZM_ZombieHandlerServer.SprintDebug then
        print("[ZM_ZombieHandler] " .. message)
    end
end

local function queuePendingSpawn(zombieType, outfit, x, y, z)
    if not zombieType then return end
    local entry = {
        zombieType = zombieType,
        outfit = outfit,
        x = math.floor(x or 0),
        y = math.floor(y or 0),
        z = math.floor(z or 0)
    }
    local list = ZM_ZombieHandlerServer.PendingSpawns
    list[#list + 1] = entry
    sprintLog("Queued spawn - type=" .. tostring(zombieType) ..
              ", outfit=" .. tostring(outfit) ..
              ", pos=(" .. entry.x .. "," .. entry.y .. "," .. entry.z .. ")")
    return entry
end

local function matchPendingSpawn(zombie)
    local list = ZM_ZombieHandlerServer.PendingSpawns
    if not list or #list == 0 or not zombie then return nil end

    local outfit = zombie:getOutfitName()
    if not outfit then return nil end

    local zx = math.floor(zombie:getX() or 0)
    local zy = math.floor(zombie:getY() or 0)
    local zz = math.floor(zombie:getZ() or 0)

    for i = #list, 1, -1 do
        local entry = list[i]
        if entry and entry.outfit == outfit and entry.z == zz then
            local dx = math.abs(zx - entry.x)
            local dy = math.abs(zy - entry.y)
            if dx <= 2 and dy <= 2 then
                table.remove(list, i)
                return entry
            end
        end
    end
    return nil
end

local function removePendingSpawn(entry)
    if not entry then return false end
    local list = ZM_ZombieHandlerServer.PendingSpawns
    if not list or #list == 0 then return false end
    for i = #list, 1, -1 do
        if list[i] == entry then
            table.remove(list, i)
            return true
        end
    end
    return false
end

function ZM_ZombieHandlerServer.forceSprintForZombie(zombie, zombieType, reason)
    if not zombie then return false end

    local resolvedType = zombieType
    if not resolvedType then
        local modData = zombie:getModData()
        if modData and modData.ZM_ZombieType then
            resolvedType = modData.ZM_ZombieType
        end
    end

    if not resolvedType then
        sprintLog("forceSprint skipped - no zombieType (reason=" .. tostring(reason) .. ")")
        return false
    end

    local zombieData = ZM_ZombieHandlerServer.ZombieTypes[resolvedType]
    if not zombieData then
        sprintLog("forceSprint skipped - unknown type " .. tostring(resolvedType) ..
                  " (reason=" .. tostring(reason) .. ")")
        return false
    end

    local desiredWalkType = zombieData.walkType
    local shouldSprint = (zombieData.canSprint == true) and
        (desiredWalkType == "sprint1" or desiredWalkType == "sprint2")

    local currentWalkType = nil
    if zombie.getWalkType then
        currentWalkType = zombie:getWalkType()
    end

    sprintLog("forceSprint check - type=" .. tostring(resolvedType) ..
              ", outfit=" .. tostring(zombie:getOutfitName()) ..
              ", id=" .. tostring(zombie:getOnlineID()) ..
              ", pos=(" .. tostring(zombie:getX()) .. "," .. tostring(zombie:getY()) .. "," .. tostring(zombie:getZ()) .. ")" ..
              ", desired=" .. tostring(desiredWalkType) ..
              ", current=" .. tostring(currentWalkType) ..
              ", shouldSprint=" .. tostring(shouldSprint) ..
              ", reason=" .. tostring(reason))

    if not shouldSprint then
        return false
    end



    zombie:setWalkType(desiredWalkType)
    print(desiredWalkType .. "<- Desired Walktype")
    zombie:setSprinting(true)
    local modData = zombie:getModData()
    modData.ZM_ZombieType = resolvedType
    modData.ZM_DesiredWalkType = desiredWalkType
    modData.ZM_WalkTypeSet = true

    sprintLog("forceSprint applied - type=" .. tostring(resolvedType) ..
              ", walkType=" .. tostring(desiredWalkType) ..
              ", id=" .. tostring(zombie:getOnlineID()) ..
              ", reason=" .. tostring(reason))
    return true
end

ZM_ZombieHandlerServer.onZombieCreate = function(zombie)
    if not zombie then return end
    local entry = matchPendingSpawn(zombie)
    if not entry then return end

    sprintLog("OnZombieCreate matched spawn - type=" .. tostring(entry.zombieType) ..
              ", outfit=" .. tostring(entry.outfit) ..
              ", id=" .. tostring(zombie:getOnlineID()))

    ZM_ZombieHandlerServer.forceSprintForZombie(zombie, entry.zombieType, "OnZombieCreate")
end

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
    -- ZM_ZombieHandlerServer.addItemsToZombie(zombie, zombieType)

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

    -- Track this spawn so OnZombieCreate can match and force sprint immediately
    local pendingEntry = queuePendingSpawn(zombieType, zombieData.outfit or "Random", ix, iy, iz)

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

    -- print("[ZM_ZombieHandlerServer] Called addZombiesInOutfitArea for " .. zombieData.outfit .. " zombie at (" .. ix .. ", " .. iy .. ", " .. iz .. ")")

    -- Get the zombie from the returned list or from the square
    local zombie = nil

    if zombieList and zombieList:size() > 0 then
        zombie = zombieList:get(0)
        -- print("[ZM_ZombieHandlerServer] Found zombie from returned list")
    else
        print("[ZM_ZombieHandlerServer] zombieList is empty or nil, searching square and nearby...")

        -- Search the target square and nearby squares (3x3 area)
        for dx = -1, 1 do
            for dy = -1, 1 do
                local searchSquare = getCell():getGridSquare(ix + dx, iy + dy, iz)
                if searchSquare then
                    local zombies = searchSquare:getMovingObjects()
                    for i = 0, zombies:size() - 1 do
                        local obj = zombies:get(i)
                        if instanceof(obj, "IsoZombie") then
                            local zombieOutfit = obj:getOutfitName()
                            -- Check if this zombie has the outfit we just spawned
                            if zombieOutfit == zombieData.outfit then
                                zombie = obj
                                -- print("[ZM_ZombieHandlerServer] Found zombie from square search at offset (" .. dx .. ", " .. dy .. ")")
                                break
                            end
                        end
                    end
                    if zombie then break end
                end
            end
            if zombie then break end
        end
    end

    if not zombie then
        removePendingSpawn(pendingEntry)
        print("[ZM_ZombieHandlerServer] Error: Could not find spawned zombie")
        return nil
    end


    -- print("[ZM_ZombieHandlerServer] Successfully found zombie, configuring...")

    zombie:setHealth(zombieData.health)

    -- Configure movement settings first
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

    -- Store the desired walk type and zombie type in mod data
    zombie:getModData().ZM_DesiredWalkType = zombieData.walkType
    zombie:getModData().ZM_ZombieType = zombieType

    if zombieType == "nightmares" then
        zombie:setCrawler(true)
        zombie:setBecomeCrawler(true)
        zombie:setCanWalk(false)
        zombie:getModData().ZM_NightmareHealth = zombie:getHealth()
    end

    -- Additional configuration for screamers
    if zombieType == "screamer1" or zombieType == "screamer2" then
        -- zombie:setVariable("isScreamerII", true)
    end

    -- Force sprint immediately as a fallback in case OnZombieCreate didn't match
    ZM_ZombieHandlerServer.forceSprintForZombie(zombie, zombieType, "post-create")

    -- Ensure the pending entry doesn't linger after fallback
    removePendingSpawn(pendingEntry)

    -- Call the function to add loot to the zombie
    -- ZM_ZombieHandlerServer.addItemsToZombie(zombie, zombieType)

    return zombie
end

-- Function to count zombies in a circular area
function ZM_ZombieHandlerServer.countZombiesInArea(x, y, z, radius)
    if not x or not y or not z or not radius then return 0 end

    local cell = getCell()
    if not cell then return 0 end

    local zombieCount = 0
    local searchRadius = math.ceil(radius)

    -- Search in a square area and check distance for each zombie
    for dx = -searchRadius, searchRadius do
        for dy = -searchRadius, searchRadius do
            local checkX = x + dx
            local checkY = y + dy
            local square = cell:getGridSquare(checkX, checkY, z)

            if square then
                -- Get all moving objects on this square
                local objects = square:getMovingObjects()
                if objects then
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        -- Check if it's a zombie
                        if obj and instanceof(obj, "IsoZombie") then
                            -- Calculate actual distance to ensure it's within radius
                            local objX = obj:getX()
                            local objY = obj:getY()
                            local distance = math.sqrt((objX - x)^2 + (objY - y)^2)

                            if distance <= radius then
                                zombieCount = zombieCount + 1
                            end
                        end
                    end
                end
            end
        end
    end
    print("[ZM_ZombieHandlerServer] countZombiesInArea found " .. zombieCount .. " zombies within radius " .. radius .. " of (" .. x .. ", " .. y .. ", " .. z .. ")")
    return zombieCount
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

-- Find a zombie by OnlineID (server-side)
function ZM_ZombieHandlerServer.findZombieByOnlineID(onlineID)
    if not onlineID then return nil end
    local cell = getCell()
    if not cell or not cell.getZombieList then return nil end

    local list = cell:getZombieList()
    if not list then return nil end

    for i = 0, list:size() - 1 do
        local z = list:get(i)
        if z and z.getOnlineID and z:getOnlineID() == onlineID then
            return z
        end
    end

    return nil
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

    print("[ZM_ZombieHandler] spawnZombieAtPlayer called - zombieType: " .. zombieType .. ", count: " .. (args.count or 1))

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

            print("[ZM_ZombieHandler] Attempt " .. attempt .. " - square: " .. tostring(square ~= nil) .. ", x: " .. x .. ", y: " .. y)

            -- Check if square is valid and no player is within safeRadius
            if square and not ZM_ZombieHandlerServer.isPlayerNearby(x, y, args.z or 0, safeRadius) then
                print("[ZM_ZombieHandler] Square valid, creating zombie...")
                local zombie = ZM_ZombieHandlerServer.createZombie(square, zombieType)
                print("[ZM_ZombieHandler] createZombie returned: " .. tostring(zombie ~= nil))
                if zombie then
                    print("[ZM_ZombieHandler] SUCCESS - Zombie created!")
                    -- Set walk type after zombie is created
                    local desiredWalkType = zombie:getModData().ZM_DesiredWalkType
                    if desiredWalkType then
                        local modData = zombie:getModData()
                        if not modData.ZM_WalkTypeSet then
                            if desiredWalkType ~= "sprint1" and desiredWalkType ~= "sprint2" then
                                zombie:setWalkType(desiredWalkType)
                                modData.ZM_WalkTypeSet = true
                            else
                                modData.ZM_WalkTypeSet = false
                            end
                        end
                    end
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

    -- Count zombies in a 200x200 area (radius 100) around the target coords before spawning
    local centerX = args.x
    local centerY = args.y
    local centerZ = args.z or 0
    local existingZombies = ZM_ZombieHandlerServer.countZombiesInArea(centerX, centerY, centerZ, 100)


    local count = math.min(args.count or 1, 50)
    local spawnedCount = 0
    if existingZombies >= 600 then
        sendServerCommand(player, "ZM_ZombieHandler", "spawnError", {
            error = "Too many zombies (" .. existingZombies .. ") in the area! Spawn limit reached."
        })
        return
        print("[ZM_ZombieHandler] Spawn aborted - too many zombies in area: " .. existingZombies)
    end
    for i = 1, count do
        local x = args.x + ZombRand(-1, 1)
        local y = args.y + ZombRand(-1, 1)
        local square = getCell():getGridSquare(x, y, args.z or 0)

        if square  then
            -- print("[ZM_ZombieHandler] spawnZombieAtCoords - Spawning " .. zombieType .. " zombie at (" .. x .. ", " .. y .. ", " .. (args.z or 0) .. ")")
            local zombie = ZM_ZombieHandlerServer.createZombie(square, zombieType)
            -- print("[ZM_ZombieHandler] spawnZombieAtCoords - createZombie returned: " .. tostring(zombie ~= nil))
            if zombie then
                -- Set walk type after zombie is created
                local desiredWalkType = zombie:getModData().ZM_DesiredWalkType
                -- print("[ZM_ZombieHandler] spawnZombieAtCoords - desiredWalkType: " .. tostring(desiredWalkType))
                if desiredWalkType then
                    -- Set walk type to allow non-sprinter behavior; defer sprinters until first hit
                    local modData = zombie:getModData()
                    if not modData.ZM_WalkTypeSet then
                        if desiredWalkType ~= "sprint1" and desiredWalkType ~= "sprint2" then
                            zombie:setWalkType(desiredWalkType)
                            modData.ZM_WalkTypeSet = true
                        else
                            modData.ZM_WalkTypeSet = false
                        end
                    end
                end
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
                    -- Set walk type after zombie is created
                    local desiredWalkType = zombie:getModData().ZM_DesiredWalkType
                    if desiredWalkType then
                        local modData = zombie:getModData()
                        if not modData.ZM_WalkTypeSet then
                            if desiredWalkType ~= "sprint1" and desiredWalkType ~= "sprint2" then
                                zombie:setWalkType(desiredWalkType)
                                modData.ZM_WalkTypeSet = true
                            else
                                modData.ZM_WalkTypeSet = false
                            end
                        end
                    end

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

-- Helper function to check if player is near or inside their safehouse (within 20 tiles)
local function isPlayerNearOrInSafehouse(targetPlayer)
    if not targetPlayer then return false end

    -- Get the safehouse the player actually owns (not just one they are standing in)
    local username = targetPlayer:getUsername()
    local safehouse = SafeHouse.getSafehouseByOwner(username)
    -- Fallback to membership lookup in case the player is only a member
    if not safehouse then
        safehouse = SafeHouse.hasSafehouse(username)
    end
    -- print("Checking safehouse for player: " .. targetPlayer:getUsername())
    -- print("Safehouse found: " .. tostring(safehouse ~= nil))
    -- If player doesn't have a safehouse, return false
    if not safehouse then
        return false
    end

    -- Get player's current position
    local playerX = targetPlayer:getX()
    local playerY = targetPlayer:getY()

    -- Check if player is inside the safehouse using containsLocation
    if safehouse:containsLocation(playerX, playerY) then
        return true
    end

    -- Check if player is within 20 tiles of the safehouse boundaries
    local safehouseX1 = safehouse:getX()
    local safehouseY1 = safehouse:getY()
    local safehouseX2 = safehouse:getX2()
    local safehouseY2 = safehouse:getY2()
    -- print("Safehouse boundaries: (" .. safehouseX1 .. ", " .. safehouseY1 .. ") to (" .. safehouseX2 .. ", " .. safehouseY2 .. ")")
    -- Calculate closest point on safehouse boundary to player
    local closestX = math.max(safehouseX1, math.min(playerX, safehouseX2))
    local closestY = math.max(safehouseY1, math.min(playerY, safehouseY2))

    -- Calculate distance from player to closest point on safehouse
    local distanceX = playerX - closestX
    local distanceY = playerY - closestY
    local distance = math.sqrt(distanceX * distanceX + distanceY * distanceY)
    -- print("Distance from player to safehouse: " .. distance)
    -- Return true if within 20 tiles
    return distance <= 80
end

-- Function to spawn horde for all online players with random outfits
function ZM_ZombieHandlerServer.spawnHordeForAllPlayers(player, args)
    local count = math.min(args.count or 10, 100)
    local radius = args.radius or 5
    local safeRadius = args.safeRadius or 0

    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers or onlinePlayers:size() == 0 then
        sendServerCommand(player, "ZM_ZombieHandler", "spawnError", {
            error = "No online players found"
        })
        return
    end

    local totalSpawned = 0
    local playersProcessed = 0
    local playersSkipped = 0

    -- Iterate through all online players
    for i = 0, onlinePlayers:size() - 1 do
        local targetPlayer = onlinePlayers:get(i)
        if targetPlayer and targetPlayer:isAlive() then
            -- SAFEHOUSE VALIDATION: Check if player is near or inside their safehouse
            if not isPlayerNearOrInSafehouse(targetPlayer) then
                -- Skip this player if they are not near/in their safehouse
                playersSkipped = playersSkipped + 1
                -- print("[ZM_ZombieHandler] Skipped spawning for " .. targetPlayer:getUsername() .. " (not near/in safehouse)")
            else
                -- ZOMBIE COUNT VALIDATION: Check if spawn area already has 200+ zombies
                local spawnAreaX = targetPlayer:getX() + 30
                local spawnAreaY = targetPlayer:getY() + 30
                local spawnAreaZ = targetPlayer:getZ()
                local checkRadius = radius + 200 -- Check slightly larger area to account for spawn spread

                local existingZombies = ZM_ZombieHandlerServer.countZombiesInArea(spawnAreaX, spawnAreaY, spawnAreaZ, checkRadius)
                -- print("[ZM_ZombieHandler] Existing zombies near " .. targetPlayer:getUsername() .. ": " .. existingZombies)
                if existingZombies >= 600 then
                    playersSkipped = playersSkipped + 1
                    -- print("[ZM_ZombieHandler] Skipped spawning for " .. targetPlayer:getUsername() .. " (spawn area has " .. existingZombies .. " zombies, limit: 200)")
                    sendServerCommand(targetPlayer, "ZM_ZombieHandler", "spawnError", {
                        error = "Spawn area already has too many zombies (" .. existingZombies .. "/200)"
                    })
                else
                    playersProcessed = playersProcessed + 1
                    local playerSpawned = 0

                    -- Spawn zombies around this player
                    for j = 1, count do
                        -- Select random zombie type from weighted pool (all defined types).
                        local zombieType = pickWeightedZombieType(ZM_ZombieHandlerServer.ZoneSpawnWeights)

                        -- Calculate spawn position in a circle around player
                        local angle = (j / count) * math.pi * 2
                        local spawnX = targetPlayer:getX() + 40 + (math.cos(angle) * radius)
                        local spawnY = targetPlayer:getY() + 40 + (math.sin(angle) * radius)
                        local spawnZ = targetPlayer:getZ()

                        -- Check safe radius if specified
                        if safeRadius > 0 and ZM_ZombieHandlerServer.isPlayerNearby(spawnX, spawnY, spawnZ, safeRadius) then
                            -- Skip this spawn location
                        else
                            local square = getCell():getGridSquare(spawnX, spawnY, spawnZ)
                            if square then
                                local zombie = ZM_ZombieHandlerServer.createZombie(square, zombieType)
                                if zombie then
                                    -- Make zombie target the player
                                    zombie:setTarget(targetPlayer)
                                    playerSpawned = playerSpawned + 1
                                    totalSpawned = totalSpawned + 1
                                end
                            end
                        end
                    end

                    -- Notify the target player
                    sendServerCommand(targetPlayer, "ZM_ZombieHandler", "zombieSpawned", {
                        message = "A horde of " .. playerSpawned .. " zombies has been spawned around you!"
                    })
                end
            end
        end
    end

    -- Notify the admin who triggered it
    local message = "Spawned " .. totalSpawned .. " zombies across " .. playersProcessed .. " players"
    if playersSkipped > 0 then
        message = message .. " (" .. playersSkipped .. " players skipped - not near safehouse)"
    end
    sendServerCommand(player, "ZM_ZombieHandler", "zombieSpawned", {
        message = message
    })

    -- print("[ZM_ZombieHandler] " .. player:getUsername() .. " spawned horde for all players: " .. totalSpawned .. " zombies across " .. playersProcessed .. " players (skipped " .. playersSkipped .. " players)")
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
                                                -- print("[ZM_ZombieHandlerServer] Consumed " .. requiredItem .. " from container at (" .. x .. "," .. y .. "," .. playerZ .. ")")
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
        if command == "spawnHordeForAllPlayers" then
            ZM_ZombieHandlerServer.spawnHordeForAllPlayers(player, args)
        elseif command == "spawnZombieAtPlayer" then
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
        elseif command == "forceSprintForZombie" then
            local zombieID = args and args.zombieID or nil
            if not zombieID then return end

            local zombie = ZM_ZombieHandlerServer.findZombieByOnlineID(zombieID)
            if not zombie then
                sprintLog("forceSprintForZombie command - zombie not found id=" .. tostring(zombieID) ..
                    " from " .. tostring(player and player:getUsername() or "unknown"))
                return
            end

            local zombieType = args and args.zombieType or nil
            if zombieType and not ZM_ZombieHandlerServer.ZombieTypes[zombieType] then
                zombieType = nil
            end

            ZM_ZombieHandlerServer.forceSprintForZombie(zombie, zombieType, "client-area")
        end
    end
end)




return ZM_ZombieHandlerServer
