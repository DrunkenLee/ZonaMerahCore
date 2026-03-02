require "PlayerConfig"
require "PlayerTierPersistence"
require "ZM_InventoryCapacityHandler"

ServerPlayerTierHandler = {}
local IMMORTAL_TIER_VALUE = PlayerTierPersistence.getTierValue("Immortal")
local INVENTORY_TIER_BONUS = 7
local runtimeTierInventoryBonusByPlayer = setmetatable({}, { __mode = "k" })
local DEBUG_TIER_INVENTORY_BONUS = true

local function debugTierInventoryBonus(player, message)
    if not DEBUG_TIER_INVENTORY_BONUS then
        return
    end

    local username = "unknown"
    if player and player.getUsername then
        username = tostring(player:getUsername())
    end

    print("[ServerPlayerTierHandler][TierInvDebug][" .. username .. "] " .. tostring(message))
end

function ServerPlayerTierHandler.setInventoryBonusDebugEnabled(enabled)
    DEBUG_TIER_INVENTORY_BONUS = enabled ~= false
    print("[ServerPlayerTierHandler][TierInvDebug] enabled=" .. tostring(DEBUG_TIER_INVENTORY_BONUS))
    return DEBUG_TIER_INVENTORY_BONUS
end

if not _G.zmSetTierInvDebug then
    _G.zmSetTierInvDebug = ServerPlayerTierHandler.setInventoryBonusDebugEnabled
end

local function getTierValueFromModData(modData)
    if not modData then
        return 1
    end
    local fromValue = tonumber(modData.PlayerTierValue) or 0
    local fromName = PlayerTierPersistence.getTierValue(modData.PlayerTier)
    local tierValue = math.max(fromValue, fromName)
    if tierValue < 1 then
        tierValue = 1
    end
    return tierValue
end

local function getHighestTierFlagValue(modData)
    if not modData then
        return 0
    end

    return math.max(
        tonumber(modData.PlayerTierHighestFlagValue) or 0,
        PlayerTierPersistence.getTierValue(modData.PlayerTierHighestFlagName)
    )
end

local function updateHighestTierFlagValue(modData, tierName, tierValue)
    if not modData then
        return
    end

    local resolvedTierValue = math.max(
        tonumber(tierValue) or 0,
        PlayerTierPersistence.getTierValue(tierName)
    )
    if resolvedTierValue < 1 then
        return
    end

    local highestTierValue = getHighestTierFlagValue(modData)
    if resolvedTierValue > highestTierValue then
        local resolvedTierName = PlayerTierPersistence.getTierName(resolvedTierValue)
        modData.PlayerTierHighestFlagValue = resolvedTierValue
        modData.PlayerTierHighestFlagName = resolvedTierName
        return
    end

    if highestTierValue > 0 then
        modData.PlayerTierHighestFlagValue = highestTierValue
        if not modData.PlayerTierHighestFlagName or modData.PlayerTierHighestFlagName == "" then
            modData.PlayerTierHighestFlagName = PlayerTierPersistence.getTierName(highestTierValue)
        end
    end
end

local function getLiveSnapshot(player, args)
    local modData = player:getModData()

    local incomingHours = tonumber(args and args.hours) or 0
    local incomingKills = tonumber(args and (args.zombieKills or args.kills)) or 0

    local snapshot = {
        hours = math.max(
            tonumber(player:getHoursSurvived()) or 0,
            tonumber(modData.PersistentHours) or 0,
            tonumber(modData.HoursSurvived) or 0,
            incomingHours
        ),
        zombieKills = math.max(
            tonumber(player:getZombieKills()) or 0,
            tonumber(modData.PersistentZombieKills) or 0,
            tonumber(modData.ZombieKills) or 0,
            incomingKills
        ),
        tier = args and args.tier or modData.PlayerTier,
        tierValue = math.max(
            getTierValueFromModData(modData),
            tonumber(args and args.tierValue) or 0
        ),
        updatedAt = PlayerTierPersistence.nowMs()
    }

    return PlayerTierPersistence.sanitizeSnapshot(snapshot)
end

local function applySnapshotToPlayer(player, snapshot)
    local modData = player:getModData()
    local safe = PlayerTierPersistence.sanitizeSnapshot(snapshot)

    modData.PersistentHours = safe.hours
    modData.PersistentZombieKills = safe.zombieKills

    if safe.hours > (tonumber(player:getHoursSurvived()) or 0) then
        player:setHoursSurvived(safe.hours)
    end

    if safe.zombieKills > (tonumber(player:getZombieKills()) or 0) then
        player:setZombieKills(safe.zombieKills)
    end

    if safe.tierValue > getTierValueFromModData(modData) then
        modData.PlayerTier = safe.tier
        modData.PlayerTierValue = safe.tierValue
    end

    updateHighestTierFlagValue(modData, modData.PlayerTier, getTierValueFromModData(modData))
end

local function sendTierSnapshot(player, username, command, snapshot)
    local payload = PlayerTierPersistence.snapshotToCommandArgs(username, snapshot)

    if player and player.getUsername and username == player:getUsername() then
        local modData = player:getModData()
        local highestTierFlagValue = getHighestTierFlagValue(modData)
        if highestTierFlagValue > 0 then
            payload.highestTierFlagValue = highestTierFlagValue
            payload.highestTierFlagName = PlayerTierPersistence.getTierName(highestTierFlagValue)
        end
    end

    sendServerCommand(
        player,
        "PlayerTierHandler",
        command,
        payload
    )
end

local function applyTierInventoryCapacityBonus(player)
    if not player then
        return
    end

    local modData = player:getModData()
    if not modData then
        return
    end

    -- Legacy cleanup: this key was persisted and could cause stale relog math.
    modData.ZM_TierInventoryBonusApplied = nil

    local tierValue = getTierValueFromModData(modData)
    local tierName = tostring(modData.PlayerTier or PlayerTierPersistence.getTierName(tierValue))
    local previousBonus = tonumber(runtimeTierInventoryBonusByPlayer[player]) or 0
    local targetBonus = tierValue >= IMMORTAL_TIER_VALUE and INVENTORY_TIER_BONUS or 0
    local currentBase = math.max(1, math.floor(tonumber(player:getMaxWeightBase()) or 1))
    local currentCapacity = math.max(1, math.floor(tonumber(player:getMaxWeight()) or currentBase))

    debugTierInventoryBonus(
        player,
        "apply start tier=" .. tierName ..
        " tierValue=" .. tostring(tierValue) ..
        " forcedOverride=" .. tostring(modData.ZM_ForcedInventoryCapacity) ..
        " previousBonus=" .. tostring(previousBonus) ..
        " base=" .. tostring(currentBase) ..
        " current=" .. tostring(currentCapacity)
    )

    -- Respect explicit forced capacity override from ZM_InventoryCapacityHandler.
    if modData.ZM_ForcedInventoryCapacity ~= nil then
        runtimeTierInventoryBonusByPlayer[player] = 0
        debugTierInventoryBonus(player, "forced override branch -> applyPersistedCapacity")
        if ZM_InventoryCapacityHandler and ZM_InventoryCapacityHandler.applyPersistedCapacity then
            ZM_InventoryCapacityHandler.applyPersistedCapacity(player)
        end
        return
    end

    local baseWithoutTierBonus = currentBase - previousBonus
    if baseWithoutTierBonus < 1 then
        baseWithoutTierBonus = 1
    end

    local targetCapacity = baseWithoutTierBonus + targetBonus
    debugTierInventoryBonus(
        player,
        "computed baseWithoutTierBonus=" .. tostring(baseWithoutTierBonus) ..
        " targetBonus=" .. tostring(targetBonus) ..
        " targetCapacity=" .. tostring(targetCapacity)
    )

    if targetCapacity ~= currentBase or targetCapacity ~= currentCapacity then
        if ZM_InventoryCapacityHandler and ZM_InventoryCapacityHandler.setCurrentCapacityAndSync then
            debugTierInventoryBonus(player, "apply capacity via setCurrentCapacityAndSync -> " .. tostring(targetCapacity))
            ZM_InventoryCapacityHandler.setCurrentCapacityAndSync(player, targetCapacity)
        else
            debugTierInventoryBonus(player, "apply capacity direct -> " .. tostring(targetCapacity))
            player:setMaxWeightBase(targetCapacity)
            player:setMaxWeight(targetCapacity)
            if ZM_InventoryCapacityHandler and ZM_InventoryCapacityHandler.syncCurrentCapacityToClient then
                ZM_InventoryCapacityHandler.syncCurrentCapacityToClient(player)
            end
        end
    elseif ZM_InventoryCapacityHandler and ZM_InventoryCapacityHandler.syncCurrentCapacityToClient then
        debugTierInventoryBonus(player, "no capacity change needed, syncing current values to client")
        ZM_InventoryCapacityHandler.syncCurrentCapacityToClient(player)
    end

    runtimeTierInventoryBonusByPlayer[player] = targetBonus
    debugTierInventoryBonus(player, "apply complete runtimeStoredBonus=" .. tostring(targetBonus))
end

-- Function to set unlimited endurance for GODLIKE tier and add a trait
function ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
    if not player then
        return
    end

    local modData = player:getModData()
    local tierValue = getTierValueFromModData(modData)
    local godlikeValue = PlayerTierPersistence.getTierValue("Godlike")

    if tierValue >= godlikeValue then
        -- player:setUnlimitedEndurance(true)
        -- if not player:HasTrait("Desensitized") then
        --     player:getTraits():add("Desensitized")
        -- end
    end
    print("[ServerPlayerTierHandler] Applied unlimited endurance and trait for player: " .. player:getUsername() ..
        " - TierValue: " .. tierValue)
    applyTierInventoryCapacityBonus(player)
end

function ServerPlayerTierHandler.savePlayerSurvivedHours(player, args)
    if not player then
        return
    end

    local username = player:getUsername()
    debugTierInventoryBonus(player, "trigger savePlayerSurvivedHours")
    local liveSnapshot = getLiveSnapshot(player, args)
    local mergedSnapshot = PlayerTierPersistence.upsertSnapshot(username, liveSnapshot)

    applySnapshotToPlayer(player, mergedSnapshot)
    applyTierInventoryCapacityBonus(player)

    print("[ServerPlayerTierHandler] Saved tier snapshot for user: " .. username)
    sendTierSnapshot(player, username, "saveSurvivedHoursResponse", mergedSnapshot)
    sendTierSnapshot(player, username, "tierSnapshotResponse", mergedSnapshot)
end

-- Function to load the player's tier data from a file
function ServerPlayerTierHandler.loadPlayerSurvivedHours(player, args)
    if not player then
        return 0, 0
    end

    local username = args and args.username or player:getUsername()
    debugTierInventoryBonus(player, "trigger loadPlayerSurvivedHours username=" .. tostring(username))
    local snapshot

    if username == player:getUsername() then
        snapshot = PlayerTierPersistence.upsertSnapshot(username, getLiveSnapshot(player, args))
        applySnapshotToPlayer(player, snapshot)
        applyTierInventoryCapacityBonus(player)
    else
        snapshot = PlayerTierPersistence.getSnapshot(username)
    end

    print("[ServerPlayerTierHandler] Loaded tier snapshot for user: " .. username ..
        " - Hours: " .. snapshot.hours .. ", Kills: " .. snapshot.zombieKills ..
        ", Tier: " .. snapshot.tier)

    sendTierSnapshot(player, username, "loadSurvivedHoursResponse", snapshot)
    sendTierSnapshot(player, username, "tierSnapshotResponse", snapshot)

    return snapshot.hours, snapshot.zombieKills
end

function ServerPlayerTierHandler.savePlayerExoOperatorLevel(player, args)
    if not player then
        return
    end

    local username = player:getUsername()
    local level = args.exoLevel
    local mdUnlocked = args.MDUnlocked or 0
    local rsUnlocked = args.RSUnlocked or 0
    local lvUnlocked = args.LVUnlocked or 0

    local filePath = "server-player-exo-level.ini"
    local data = {}

    local file = getFileReader(filePath, true)
    if file then
        local line = file:readLine()
        while line do
            local user, exoLevel, md, rs, lv = line:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
            data[user] = {
                level = tonumber(exoLevel) or 1,
                md = tonumber(md) or 0,
                rs = tonumber(rs) or 0,
                lv = tonumber(lv) or 0
            }
            line = file:readLine()
        end
        file:close()
    end

    data[username] = {
        level = level,
        md = mdUnlocked,
        rs = rsUnlocked,
        lv = lvUnlocked
    }

    local fileWriter = getFileWriter(filePath, true, false)
    if fileWriter then
        for user, userData in pairs(data) do
            fileWriter:write(string.format("%s,%d,%d,%d,%d\n", user, userData.level, userData.md, userData.rs, userData.lv))
        end
        fileWriter:close()
        print("[ServerPlayerTierHandler] Saved exo operator data for user: " .. username ..
            " - Level: " .. level ..
            ", MD: " .. mdUnlocked ..
            ", RS: " .. rsUnlocked ..
            ", LV: " .. lvUnlocked)

        sendServerCommand(player, "PlayerTierHandler", "saveExoOperatorLevelResponse", {
            username = username,
            exoLevel = level,
            MDUnlocked = mdUnlocked,
            RSUnlocked = rsUnlocked,
            LVUnlocked = lvUnlocked
        })
    else
        error("Failed to open file for writing: " .. filePath)
    end
end

function ServerPlayerTierHandler.loadPlayerExoOperatorLevel(player)
    if not player then
        return
    end

    local username = player:getUsername()

    local filePath = "server-player-exo-level.ini"
    local file = getFileReader(filePath, true)
    if not file then
        print("[ServerPlayerTierHandler] No saved exo operator level data found for user: " .. username)
        sendServerCommand(player, "PlayerTierHandler", "loadExoOperatorLevelResponse", {
            username = username,
            exoLevel = 1,
            MDUnlocked = 0,
            RSUnlocked = 0,
            LVUnlocked = 0
        })
        return
    end

    local data = {}
    local line = file:readLine()
    while line do
        local user, exoLevel, md, rs, lv = line:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        if user then
            data[user] = {
                level = tonumber(exoLevel) or 1,
                md = tonumber(md) or 0,
                rs = tonumber(rs) or 0,
                lv = tonumber(lv) or 0
            }
        end
        line = file:readLine()
    end
    file:close()

    local userData = data[username] or { level = 1, md = 0, rs = 0, lv = 0 }
    print("[ServerPlayerTierHandler] Loaded exo operator data for user: " .. username ..
        " - Level: " .. userData.level ..
        ", MD: " .. userData.md ..
        ", RS: " .. userData.rs ..
        ", LV: " .. userData.lv)

    sendServerCommand(player, "PlayerTierHandler", "loadExoOperatorLevelResponse", {
        username = username,
        exoLevel = userData.level,
        MDUnlocked = userData.md,
        RSUnlocked = userData.rs,
        LVUnlocked = userData.lv
    })
end

function ServerPlayerTierHandler.setPlayerTier(admin, args)
    if not admin:isAccessLevel("admin") then
        sendServerCommand(admin, "PlayerTierHandler", "tierSetResponse",
            { message = "Error: Only admins can set player tiers." })
        return
    end

    local targetUsername = args.targetUsername
    local targetPlayer = nil

    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player:getUsername() == targetUsername then
            targetPlayer = player
            break
        end
    end

    if not targetPlayer then
        sendServerCommand(admin, "PlayerTierHandler", "tierSetResponse",
            { message = "Error: Player " .. targetUsername .. " not found." })
        return
    end

    local tier = args.tier
    print("[ServerPlayerTierHandler] Attempting to set " .. targetUsername .. "'s tier to: " .. tostring(tier))

    local validTier = false
    local tierValue = 1
    local availableTiers = {
        "Newbies",
        "Adventurer",
        "Veteran",
        "Champion",
        "Legend",
        "Immortal",
        "Mythic",
        "Godlike",
        "Beyond Godlike"
    }

    for i, tierName in ipairs(availableTiers) do
        if tier == tierName then
            validTier = true
            tierValue = i
            break
        end
    end

    if not validTier then
        sendServerCommand(admin, "PlayerTierHandler", "tierSetResponse",
            { message = "Error: Invalid tier '" .. tostring(tier) .. "'" })
        return
    end

    local modData = targetPlayer:getModData()
    modData.PlayerTier = tier
    modData.PlayerTierValue = tierValue
    updateHighestTierFlagValue(modData, tier, tierValue)
    modData.TierSetManually = true

    local existingSnapshot = PlayerTierPersistence.getSnapshot(targetUsername)
    local snapshot = PlayerTierPersistence.setSnapshot(targetUsername, {
        hours = math.max(
            existingSnapshot.hours,
            tonumber(targetPlayer:getHoursSurvived()) or 0,
            tonumber(modData.PersistentHours) or 0
        ),
        zombieKills = math.max(
            existingSnapshot.zombieKills,
            tonumber(targetPlayer:getZombieKills()) or 0,
            tonumber(modData.PersistentZombieKills) or 0
        ),
        tier = tier,
        tierValue = tierValue,
        updatedAt = PlayerTierPersistence.nowMs()
    })

    applySnapshotToPlayer(targetPlayer, snapshot)
    applyTierInventoryCapacityBonus(targetPlayer)

    sendServerCommand(admin, "PlayerTierHandler", "tierSetResponse",
        { message = "Successfully set " .. targetUsername .. "'s tier to " .. tier })

    sendServerCommand(targetPlayer, "PlayerTierHandler", "tierUpdated",
        {
            tier = tier,
            tierValue = tierValue,
            highestTierFlagValue = getHighestTierFlagValue(modData),
            highestTierFlagName = modData.PlayerTierHighestFlagName,
            message = "An admin has set your tier to " .. tier
        })

    sendTierSnapshot(targetPlayer, targetUsername, "tierSnapshotResponse", snapshot)

    print("[ServerPlayerTierHandler] Admin " .. admin:getUsername() ..
        " set " .. targetUsername .. "'s tier to " .. tier)
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= "PlayerTierHandler" then
        return
    end

    debugTierInventoryBonus(player, "OnClientCommand command=" .. tostring(command))

    if command == "saveSurvivedHours" then
        ServerPlayerTierHandler.savePlayerSurvivedHours(player, args)
    elseif command == "syncTierSnapshot" then
        ServerPlayerTierHandler.savePlayerSurvivedHours(player, args)
    elseif command == "loadSurvivedHours" then
        ServerPlayerTierHandler.loadPlayerSurvivedHours(player, args)
    elseif command == "requestTierSnapshot" then
        ServerPlayerTierHandler.loadPlayerSurvivedHours(player, args)
    elseif command == "saveExoOperatorLevel" then
        ServerPlayerTierHandler.savePlayerExoOperatorLevel(player, args)
    elseif command == "loadExoOperatorLevel" then
        ServerPlayerTierHandler.loadPlayerExoOperatorLevel(player)
    elseif command == "loadPlayerTier" then
        ServerPlayerTierHandler.loadPlayerSurvivedHours(player, args)
    elseif command == "reapplyTierInventoryBonus" then
        applyTierInventoryCapacityBonus(player)
    elseif command == "setUnlimitedEnduranceAndTrait" then
        ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
    elseif command == "setPlayerTier" then
        print("[ServerPlayerTierHandler] Received setPlayerTier command from " .. player:getUsername())
        for k, v in pairs(args or {}) do
            print("  " .. k .. " = " .. tostring(v))
        end

        ServerPlayerTierHandler.setPlayerTier(player, args or {})
    end
end)

Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
    local player = playerObj or getSpecificPlayer(playerIndex)
    if not player then
        return
    end

    local modData = player:getModData()
    updateHighestTierFlagValue(modData, modData.PlayerTier, getTierValueFromModData(modData))
    debugTierInventoryBonus(player, "OnCreatePlayer -> reset runtime bonus and reapply")
    runtimeTierInventoryBonusByPlayer[player] = 0
    applyTierInventoryCapacityBonus(player)
end)

Events.EveryDays.Add(function()
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player then
            -- ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
            ServerPlayerTierHandler.savePlayerSurvivedHours(player, nil)
        end
    end
end)

return ServerPlayerTierHandler
