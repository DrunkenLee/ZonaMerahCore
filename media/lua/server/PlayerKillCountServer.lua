PlayerKillCountServer = {}
local killCountFilePath = "server-zombie-kill-counts.ini"
local zombieHitByPlayer = {}

-- Function to save the player's zombie kill count to a file
function PlayerKillCountServer.saveKillCountToFile(username, killCount)
    local data = {}
    print("[ZonaMerahCore] Saving kill count for user: " .. username .. " with count: " .. killCount)

    -- Read existing data from file if it exists
    local file = getFileReader(killCountFilePath, true)
    if file then
        local line = file:readLine()
        while line do
            local user, count = line:match("([^,]+),([^,]+)")
            data[user] = tonumber(count)
            line = file:readLine()
        end
        file:close()
    end

    -- Update data with new kill count
    data[username] = killCount

    -- Write updated data back to file
    local fileWriter = getFileWriter(killCountFilePath, true, false)
    if fileWriter then
        for user, count in pairs(data) do
            fileWriter:write(string.format("%s,%d\n", user, count))
        end
        fileWriter:close()
    else
        error("Failed to open file for writing: " .. killCountFilePath)
    end
end

-- Function to load the player's zombie kill count from a file
function PlayerKillCountServer.loadKillCountFromFile(username)
    print("[ZonaMerahCore] Loading kill count for user: " .. username)
    local file = getFileReader(killCountFilePath, true)
    if not file then
        print("[ZonaMerahCore] File not found: " .. killCountFilePath)
        return 0
    end

    local data = {}
    local line = file:readLine()
    while line do
        local user, count = line:match("([^,]+),([^,]+)")
        data[user] = tonumber(count)
        line = file:readLine()
    end
    file:close()

    local killCount = data[username] or 0
    print("[ZonaMerahCore] Kill count for user " .. username .. ": " .. killCount)
    return killCount
end

-- Function to update the player's zombie kill count
function PlayerKillCountServer.updateKillCount(player, isSprinter, hitHead)
    local username = player:getUsername()
    local killCount = PlayerKillCountServer.loadKillCountFromFile(username)
    killCount = killCount + 1
    if isSprinter then
        killCount = killCount + 2 -- Increment by 3 in total for sprinters
    end
    if hitHead then
        killCount = killCount + 1
    end
    print("[ZonaMerahCore] Updating kill count for user: " .. username .. " to: " .. killCount)
    PlayerKillCountServer.saveKillCountToFile(username, killCount)
    sendServerCommand(player, "PlayerKillCount", "updateKillCount", { killCount = killCount })
    print("[ZonaMerahCore] Updated zombie kill count for user " .. username .. ": " .. killCount)
end

-- Event handler for hitting a zombie
local function OnHitZombie(zombie, attacker, bodyPart, weapon)
    if attacker and instanceof(attacker, "IsoPlayer") then
        local zombieID = zombie:getOnlineID()
        local speedType = zombie:getVariableString("Speed")
        local isSprinter = speedType == "3" -- Assuming "3" represents sprinters
        local hitHead = bodyPart == "Head"
        zombieHitByPlayer[zombieID] = { player = attacker, isSprinter = isSprinter, hitHead = hitHead }
        print("[ZonaMerahCore] Player " .. attacker:getUsername() .. " hit zombie with ID " .. zombieID .. ". SpeedType: " .. tostring(speedType) .. ", IsSprinter: " .. tostring(isSprinter) .. ", HitHead: " .. tostring(hitHead))
    else
        print("[ZonaMerahCore] OnHitZombie called with invalid parameters")
    end
end

-- Event handler for zombie deaths
Events.OnZombieDead.Add(function(zombie)
    if zombie then
        local zombieID = zombie:getOnlineID()
        local hitInfo = zombieHitByPlayer[zombieID]
        if hitInfo then
            print("[ZonaMerahCore] Zombie with ID " .. zombieID .. " killed by player " .. hitInfo.player:getUsername())
            PlayerKillCountServer.updateKillCount(hitInfo.player, hitInfo.isSprinter, hitInfo.hitHead)
            zombieHitByPlayer[zombieID] = nil -- Clear the entry after updating the kill count
        else
            print("[ZonaMerahCore] Zombie with ID " .. zombieID .. " died but no player was recorded as the attacker")
        end
    else
        print("[ZonaMerahCore] OnZombieDead called with invalid parameters")
    end
end)

Events.OnHitZombie.Add(OnHitZombie)

return PlayerKillCountServer