PlayerTierPersistence = PlayerTierPersistence or {}

PlayerTierPersistence.FILE_PATH = "server-player-tier.ini"
PlayerTierPersistence.TIERS = {
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

local function toNumber(value, defaultValue)
    local n = tonumber(value)
    if not n then
        return defaultValue
    end
    return n
end

local function nonNegativeNumber(value)
    local n = toNumber(value, 0)
    if n < 0 then
        return 0
    end
    return n
end

function PlayerTierPersistence.nowMs()
    if getTimestampMs then
        return nonNegativeNumber(getTimestampMs())
    end
    if os and os.time then
        return nonNegativeNumber(os.time() * 1000)
    end
    return 0
end

function PlayerTierPersistence.getTierValue(tierName)
    if not tierName then
        return 1
    end

    for i, name in ipairs(PlayerTierPersistence.TIERS) do
        if name == tierName then
            return i
        end
    end
    return 1
end

function PlayerTierPersistence.getTierName(tierValue)
    local idx = math.floor(nonNegativeNumber(tierValue))
    if idx < 1 then
        idx = 1
    elseif idx > #PlayerTierPersistence.TIERS then
        idx = #PlayerTierPersistence.TIERS
    end
    return PlayerTierPersistence.TIERS[idx], idx
end

function PlayerTierPersistence.sanitizeSnapshot(snapshot)
    local src = snapshot or {}

    local safe = {
        hours = nonNegativeNumber(src.hours or src.HoursSurvived),
        zombieKills = nonNegativeNumber(src.zombieKills or src.ZombieKills or src.kills),
        tierValue = nonNegativeNumber(src.tierValue or src.PlayerTierValue),
        updatedAt = nonNegativeNumber(src.updatedAt or src.updated_at)
    }

    local tierFromName = PlayerTierPersistence.getTierValue(src.tier or src.PlayerTier)
    if tierFromName > safe.tierValue then
        safe.tierValue = tierFromName
    end
    if safe.tierValue < 1 then
        safe.tierValue = 1
    end

    safe.tier, safe.tierValue = PlayerTierPersistence.getTierName(safe.tierValue)

    if safe.updatedAt <= 0 then
        safe.updatedAt = PlayerTierPersistence.nowMs()
    end

    return safe
end

function PlayerTierPersistence.mergeSnapshots(existingSnapshot, incomingSnapshot)
    local existing = PlayerTierPersistence.sanitizeSnapshot(existingSnapshot)
    local incoming = PlayerTierPersistence.sanitizeSnapshot(incomingSnapshot)

    local merged = {
        hours = math.max(existing.hours, incoming.hours),
        zombieKills = math.max(existing.zombieKills, incoming.zombieKills),
        tierValue = math.max(existing.tierValue, incoming.tierValue),
        updatedAt = math.max(existing.updatedAt, incoming.updatedAt, PlayerTierPersistence.nowMs())
    }

    merged.tier, merged.tierValue = PlayerTierPersistence.getTierName(merged.tierValue)
    return merged
end

function PlayerTierPersistence.snapshotToCommandArgs(username, snapshot)
    local safe = PlayerTierPersistence.sanitizeSnapshot(snapshot)
    return {
        username = username,
        hours = safe.hours,
        zombieKills = safe.zombieKills,
        tier = safe.tier,
        tierValue = safe.tierValue,
        updatedAt = safe.updatedAt
    }
end

local function parseSnapshotLine(line)
    if not line or line == "" then
        return nil, nil
    end

    local username, hours, kills, tierValue, updatedAt = line:match("^([^,]+),([^,]+),([^,]*),([^,]*),([^,]*)$")
    if username then
        return username, PlayerTierPersistence.sanitizeSnapshot({
            hours = hours,
            zombieKills = kills,
            tierValue = tierValue,
            updatedAt = updatedAt
        })
    end

    username, hours, kills = line:match("^([^,]+),([^,]+),([^,]*)$")
    if username then
        return username, PlayerTierPersistence.sanitizeSnapshot({
            hours = hours,
            zombieKills = kills,
            tierValue = 1
        })
    end

    return nil, nil
end

function PlayerTierPersistence.readAllSnapshots()
    if not isServer or not isServer() then
        return {}
    end

    local snapshots = {}
    local file = getFileReader(PlayerTierPersistence.FILE_PATH, true)
    if not file then
        return snapshots
    end

    local line = file:readLine()
    while line do
        local username, snapshot = parseSnapshotLine(line)
        if username and snapshot then
            snapshots[username] = snapshot
        end
        line = file:readLine()
    end
    file:close()

    return snapshots
end

function PlayerTierPersistence.writeAllSnapshots(snapshots)
    if not isServer or not isServer() then
        return false
    end

    local fileWriter = getFileWriter(PlayerTierPersistence.FILE_PATH, true, false)
    if not fileWriter then
        return false
    end

    for username, snapshot in pairs(snapshots or {}) do
        local safe = PlayerTierPersistence.sanitizeSnapshot(snapshot)
        fileWriter:write(string.format(
            "%s,%d,%d,%d,%d\n",
            username,
            safe.hours,
            safe.zombieKills,
            safe.tierValue,
            safe.updatedAt
        ))
    end
    fileWriter:close()

    return true
end

function PlayerTierPersistence.getSnapshot(username)
    local snapshots = PlayerTierPersistence.readAllSnapshots()
    local snapshot = snapshots[username]
    if not snapshot then
        snapshot = PlayerTierPersistence.sanitizeSnapshot({})
    end
    return snapshot
end

function PlayerTierPersistence.upsertSnapshot(username, incomingSnapshot)
    if not isServer or not isServer() then
        return PlayerTierPersistence.sanitizeSnapshot(incomingSnapshot)
    end

    local snapshots = PlayerTierPersistence.readAllSnapshots()
    local existing = snapshots[username]

    if existing then
        snapshots[username] = PlayerTierPersistence.mergeSnapshots(existing, incomingSnapshot)
    else
        snapshots[username] = PlayerTierPersistence.sanitizeSnapshot(incomingSnapshot)
    end

    PlayerTierPersistence.writeAllSnapshots(snapshots)
    return snapshots[username]
end

function PlayerTierPersistence.setSnapshot(username, snapshot)
    local safeSnapshot = PlayerTierPersistence.sanitizeSnapshot(snapshot)

    if not isServer or not isServer() then
        return safeSnapshot
    end

    local snapshots = PlayerTierPersistence.readAllSnapshots()
    snapshots[username] = safeSnapshot
    PlayerTierPersistence.writeAllSnapshots(snapshots)
    return snapshots[username]
end

return PlayerTierPersistence
