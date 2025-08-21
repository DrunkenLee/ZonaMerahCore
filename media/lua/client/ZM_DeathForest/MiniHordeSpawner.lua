-- Mini Horde Spawner System with Serverwide Flag Integration
-- Triggers waves of zombies when players enter defined zones

ZM_MiniHordeSpawner = ZM_MiniHordeSpawner or {}

-- Flag names for serverwide state tracking
ZM_MiniHordeSpawner.FLAGS = {
    HORDE_ONE = "horde_one_triggered",
    HORDE_TWO = "horde_two_triggered",
    SCREAMER = "screamer_spawned",
    BOSS = "boss_spawned"
}

-- Zone definitions
ZM_MiniHordeSpawner.Zones = {
    Horde1 = {
        x1 = 19502, y1 = 15603, -- /teleportto 19502,15603,0
        x2 = 19798, y2 = 15898, -- /teleportto 19798,15898,0
        flagName = ZM_MiniHordeSpawner.FLAGS.HORDE_ONE
    },
    Horde2 = {
        x1 = 19501, y1 = 15300, -- /teleportto 19501,15300,0
        x2 = 19798, y2 = 15598, -- /teleportto 19798,15598,0
        flagName = ZM_MiniHordeSpawner.FLAGS.HORDE_TWO
    }
}

-- Wave configuration
ZM_MiniHordeSpawner.WaveConfig = {
    wave1 = {
        totalZombies = 250,
        batchSize = 50,    -- Zombies per spawn batch
        radius = 100,      -- Adjustable radius
        interval = 5,      -- Seconds between batches
        zombieTypes = {    -- Distribution of zombie types
            horde = 195,    -- 70% regular horde zombies    -- 5% tanks
            elite = 5      -- 5% elite zombies
        }
    },
    wave2 = {
        totalZombies = 250,
        batchSize = 50,
        radius = 100,
        interval = 5,
        zombieTypes = {
            horde = 200,
            elite = 50
        }
    }
}

-- Cooldown time in minutes before a zone can be triggered again
ZM_MiniHordeSpawner.ZONE_COOLDOWN = 30

-- Check if a player is within a zone
function ZM_MiniHordeSpawner.isPlayerInZone(player, zone)
    local x = player:getX()
    local y = player:getY()

    return x >= zone.x1 and x <= zone.x2 and y >= zone.y1 and y <= zone.y2
end

-- Spawn a batch of zombies based on type distribution
function ZM_MiniHordeSpawner.spawnZombieBatch(batchSize, radius, typeDistribution)
    local player = getPlayer()
    if not player then return end

    -- Create a cumulative distribution for zombie types
    local cumulativeDistribution = {}
    local total = 0
    for zombieType, percentage in pairs(typeDistribution) do
        total = total + percentage
        cumulativeDistribution[zombieType] = total
    end

    -- Spawn zombies according to distribution
    for i = 1, batchSize do
        local rand = ZombRand(100)
        local selectedType = "horde" -- default

        for zombieType, cumulative in pairs(cumulativeDistribution) do
            if rand < cumulative then
                selectedType = zombieType
                break
            end
        end

        -- Spawn individual zombie
        ZM_ZombieHandler.spawnZombieAtPlayer(selectedType, 1, 100)

        -- Small delay to prevent game lag
        if i % 10 == 0 then
            print("Spawned 10 zombies in batch...")
        end
    end

    -- Spawn a larger horde to ensure good distribution
    ZM_ZombieHandler.spawnHorde(batchSize, radius, false, nil, "horde", true, 30)

end

-- Wave 1 - Triggered when any player enters Horde 1 zone
function ZM_MiniHordeSpawner.wave1()
    -- Check if this horde is already triggered using serverwide flag
    ZMServerwideFlagHandler.getFlagBoolDirect(ZM_MiniHordeSpawner.FLAGS.HORDE_ONE, function(isTriggered)
        if isTriggered then
            print("Horde 1 is already triggered according to serverwide flag")
            return
        end

        local player = getPlayer()
        if not player then return end

        -- Set flag to mark horde as triggered
        ZMServerwideFlagHandler.consoleSetFlag(ZM_MiniHordeSpawner.FLAGS.HORDE_ONE, 1)

        local config = ZM_MiniHordeSpawner.WaveConfig.wave1
        local remainingZombies = config.totalZombies
        local waveCount = 1

        player:Say("You've disturbed something in this area...")

        -- Function to spawn batches with delay
        local function spawnNextBatch()
            if remainingZombies <= 0 then

                return
            end

            local batchSize = math.min(config.batchSize, remainingZombies)
            remainingZombies = remainingZombies - batchSize

            waveCount = waveCount + 1
            spawnDayPsycho()
            spawnNightPsycho()
            ZM_MiniHordeSpawner.spawnZombieBatch(batchSize, config.radius, config.zombieTypes)

            -- Schedule next batch
            if remainingZombies > 0 then
                local timeUntilNextBatch = config.interval * 1000 -- convert to milliseconds
                Events.OnTick.Add(function()
                    Events.OnTick.Remove(spawnNextBatch)
                    spawnNextBatch()
                end)
            end
        end

        -- Start the first batch
        spawnNextBatch()
    end)
end

-- Wave 2 - Triggered when any player enters Horde 2 zone
function ZM_MiniHordeSpawner.wave2()
    -- Check if this horde is already triggered using serverwide flag
    ZMServerwideFlagHandler.getFlagBoolDirect(ZM_MiniHordeSpawner.FLAGS.HORDE_TWO, function(isTriggered)
        if isTriggered then
            print("Horde 2 is already triggered according to serverwide flag")
            return
        end

        local player = getPlayer()
        if not player then return end

        -- Set flag to mark horde as triggered
        ZMServerwideFlagHandler.setFlag(ZM_MiniHordeSpawner.FLAGS.HORDE_TWO, 1)

        local config = ZM_MiniHordeSpawner.WaveConfig.wave2
        local remainingZombies = config.totalZombies
        local waveCount = 1

        player:Say("The ground trembles beneath your feet...")

        -- Function to spawn batches with delay
        local function spawnNextBatch()
            if remainingZombies <= 0 then

                return
            end

            local batchSize = math.min(config.batchSize, remainingZombies)
            remainingZombies = remainingZombies - batchSize

            waveCount = waveCount + 1
            spawnDayPsycho()
            spawnNightPsycho()
            ZM_MiniHordeSpawner.spawnZombieBatch(batchSize, config.radius, config.zombieTypes)

            -- Schedule next batch
            if remainingZombies > 0 then
                local timeUntilNextBatch = config.interval * 10000 -- convert to milliseconds
                Events.OnTick.Add(function()
                    Events.OnTick.Remove(spawnNextBatch)
                    spawnNextBatch()
                end)
            end
        end

        -- Start the first batch
        spawnNextBatch()
    end)
end

-- Reserved function for spawning a screamer zombie with serverwide flag check
function ZM_MiniHordeSpawner.spawnScreamer1()
    -- Check if screamer is already spawned using serverwide flag
    ZMServerwideFlagHandler.getFlagBoolDirect(ZM_MiniHordeSpawner.FLAGS.SCREAMER, function(isSpawned)
        if isSpawned then
            print("Screamer is already spawned according to serverwide flag")
            return
        end

        -- Set flag to mark screamer as spawned
        ZMServerwideFlagHandler.setFlag(ZM_MiniHordeSpawner.FLAGS.SCREAMER, 1)

        -- Reserved for future implementation
        print("spawnScreamer1 called - functionality not yet implemented")

        -- The actual spawn logic would go here
    end)
end

-- Reserved function for spawning a boss zombie with serverwide flag check
function ZM_MiniHordeSpawner.spawnBoss1()
    -- Check if boss is already spawned using serverwide flag
    ZMServerwideFlagHandler.getFlagBoolDirect(ZM_MiniHordeSpawner.FLAGS.BOSS, function(isSpawned)
        if isSpawned then
            print("Boss is already spawned according to serverwide flag")
            return
        end

        -- Set flag to mark boss as spawned
        ZMServerwideFlagHandler.setFlag(ZM_MiniHordeSpawner.FLAGS.BOSS, 1)

        -- Reserved for future implementation
        print("spawnBoss1 called - functionality not yet implemented")

        -- The actual spawn logic would go here
    end)
end

-- Replace the Events.OnTickEvenPaused section with these executable functions

-- Main function to check if player is in any horde zones
function ZM_MiniHordeSpawner.checkAllHordeZones()
    local player = getPlayer()
    if not player then return false end

    -- Check both zones
    ZM_MiniHordeSpawner.checkHordeZone1(player)
    ZM_MiniHordeSpawner.checkHordeZone2(player)

    return true
end

-- Function to check if player is in Horde Zone 1
function ZM_MiniHordeSpawner.checkHordeZone1(player)
    player = player or getPlayer()
    if not player then return false end

    -- Check if player is in Horde 1 zone
    if ZM_MiniHordeSpawner.isPlayerInZone(player, ZM_MiniHordeSpawner.Zones.Horde1) then

        -- Check flag before triggering
        ZMServerwideFlagHandler.getFlagBoolDirect(ZM_MiniHordeSpawner.FLAGS.HORDE_ONE, function(isTriggered)
            if not isTriggered then
                player:Say("I feel weird in this area, hmm something is coming, hmmm...")
                print("Player entered Horde1 zone, triggering wave1")
                ZM_MiniHordeSpawner.wave1()
                return true
            end
            if isTriggered then
                player:Say("oh.. thank God, its over, I think...")
                print("Horde1 already triggered, not spawning again")
            end
            return false
        end)
    end

    return false
end

-- Function to check if player is in Horde Zone 2
function ZM_MiniHordeSpawner.checkHordeZone2(player)
    player = player or getPlayer()
    if not player then return false end

    -- Check if player is in Horde 2 zone
    if ZM_MiniHordeSpawner.isPlayerInZone(player, ZM_MiniHordeSpawner.Zones.Horde2) then
        -- Check flag before triggering
        ZMServerwideFlagHandler.getFlagBoolDirect(ZM_MiniHordeSpawner.FLAGS.HORDE_TWO, function(isTriggered)
            if not isTriggered then
                player:Say("Ah shit!, sounds like more of them coming!")
                print("Player entered Horde2 zone, triggering wave2")
                ZM_MiniHordeSpawner.wave2()
                return true
            end

            if isTriggered then
                player:Say("oh.. thank God, its over, I think...")
                print("Horde2 already triggered, not spawning again")
            end
            return false
        end)
    end

    return false
end

-- Function to force trigger a specific horde (for admin commands)
function ZM_MiniHordeSpawner.triggerHorde(hordeNumber)
    if hordeNumber == 1 then
        ZM_MiniHordeSpawner.wave1()
        return true
    elseif hordeNumber == 2 then
        ZM_MiniHordeSpawner.wave2()
        return true
    else
        print("Invalid horde number: " .. tostring(hordeNumber))
        return false
    end
end

-- Function to get all players within a specific zone
function ZM_MiniHordeSpawner.getPlayersInZone(zone)
    local playersInZone = {}
    local onlinePlayers = getOnlinePlayers()

    if not onlinePlayers then
        -- Single player mode - check only the main player
        local player = getPlayer()
        if player and ZM_MiniHordeSpawner.isPlayerInZone(player, zone) then
            table.insert(playersInZone, player:getUsername())
        end
        return playersInZone
    end

    -- Multiplayer mode - check all online players
    for i = 0, onlinePlayers:size() - 1 do
        local player = onlinePlayers:get(i)
        if player and not player:isDead() and ZM_MiniHordeSpawner.isPlayerInZone(player, zone) then
            table.insert(playersInZone, player:getUsername())
        end
    end

    return playersInZone
end

-- Function to get all players within Horde Zone 1
function ZM_MiniHordeSpawner.getPlayersInHordeZone1()
    return ZM_MiniHordeSpawner.getPlayersInZone(ZM_MiniHordeSpawner.Zones.Horde1)
end

-- Function to get all players within Horde Zone 2
function ZM_MiniHordeSpawner.getPlayersInHordeZone2()
    return ZM_MiniHordeSpawner.getPlayersInZone(ZM_MiniHordeSpawner.Zones.Horde2)
end

-- Function to get all players within any horde zone (isolation zones)
function ZM_MiniHordeSpawner.getAllPlayersInIsolationZones()
    local allPlayersInZones = {}

    -- Check Horde Zone 1
    local playersInZone1 = ZM_MiniHordeSpawner.getPlayersInHordeZone1()
    for _, username in ipairs(playersInZone1) do
        table.insert(allPlayersInZones, {
            username = username,
            zone = "Horde1",
            coordinates = ZM_MiniHordeSpawner.Zones.Horde1
        })
    end

    -- Check Horde Zone 2
    local playersInZone2 = ZM_MiniHordeSpawner.getPlayersInHordeZone2()
    for _, username in ipairs(playersInZone2) do
        table.insert(allPlayersInZones, {
            username = username,
            zone = "Horde2",
            coordinates = ZM_MiniHordeSpawner.Zones.Horde2
        })
    end

    return allPlayersInZones
end

-- Function to get count of players in each zone
function ZM_MiniHordeSpawner.getZonePlayerCounts()
    local zoneCounts = {
        Horde1 = #ZM_MiniHordeSpawner.getPlayersInHordeZone1(),
        Horde2 = #ZM_MiniHordeSpawner.getPlayersInHordeZone2(),
        Total = 0
    }

    zoneCounts.Total = zoneCounts.Horde1 + zoneCounts.Horde2

    return zoneCounts
end

-- Function to check if any players are in isolation zones
function ZM_MiniHordeSpawner.hasPlayersInIsolationZones()
    local counts = ZM_MiniHordeSpawner.getZonePlayerCounts()
    return counts.Total > 0
end

-- Function to get detailed zone information with player data
function ZM_MiniHordeSpawner.getZoneStatus()
    local status = {
        timestamp = os.time(),
        zones = {
            Horde1 = {
                players = ZM_MiniHordeSpawner.getPlayersInHordeZone1(),
                playerCount = 0,
                coordinates = ZM_MiniHordeSpawner.Zones.Horde1,
                flagName = ZM_MiniHordeSpawner.FLAGS.HORDE_ONE
            },
            Horde2 = {
                players = ZM_MiniHordeSpawner.getPlayersInHordeZone2(),
                playerCount = 0,
                coordinates = ZM_MiniHordeSpawner.Zones.Horde2,
                flagName = ZM_MiniHordeSpawner.FLAGS.HORDE_TWO
            }
        },
        totalPlayersInZones = 0
    }

    -- Calculate counts
    status.zones.Horde1.playerCount = #status.zones.Horde1.players
    status.zones.Horde2.playerCount = #status.zones.Horde2.players
    status.totalPlayersInZones = status.zones.Horde1.playerCount + status.zones.Horde2.playerCount

    return status
end

-- Utility function to print zone status to console
function ZM_MiniHordeSpawner.printZoneStatus()
    local status = ZM_MiniHordeSpawner.getZoneStatus()

    print("=== Horde Zone Status ===")
    print("Timestamp: " .. status.timestamp)
    print("Total players in isolation zones: " .. status.totalPlayersInZones)

    for zoneName, zoneData in pairs(status.zones) do
        print("\n" .. zoneName .. ":")
        print("  Player count: " .. zoneData.playerCount)
        print("  Flag: " .. zoneData.flagName)

        if zoneData.playerCount > 0 then
            print("  Players:")
            for i, username in ipairs(zoneData.players) do
                print("    " .. i .. ". " .. username)
            end
        else
            print("  No players in zone")
        end
    end

    print("========================")
end
