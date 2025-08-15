require "PlayerConfig"
require "PlayerTierHandler"
require "PlayerTitleHandler"

ServerPlayerTierHandler = {}

-- Function to set unlimited endurance for GODLIKE tier and add a trait
function ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
    local tier = PlayerTierHandler.getPlayerTier(player) or "NO_TIER"
    if tier == "Godlike" then
        player:setUnlimitedEndurance(true)
        if not player:HasTrait("Desensitized") then
            player:getTraits():add("Desensitized")
        end
    end
end

function ServerPlayerTierHandler.savePlayerSurvivedHours(player)
    if not player then return end
    local username = player:getUsername()
    local hoursSurvived = player:getHoursSurvived()
    local zombieKills = player:getZombieKills()

    local filePath = "server-player-tier.ini"
    local tempFilePath = filePath .. ".tmp"
    local playerFound = false

    -- Use a temporary file to avoid loading everything into memory
    local fileWriter = getFileWriter(tempFilePath, true, false)
    if not fileWriter then
        print("[ServerPlayerTierHandler] ERROR: Could not open temporary file for writing: " .. tempFilePath)
        return
    end

    local fileReader = getFileReader(filePath, true)
    if fileReader then
        local line = fileReader:readLine()
        while line do
            local user, hours, kills = line:match("([^,]+),([^,]+),([^,]*)")
            if user and user == username then
                fileWriter:write(string.format("%s,%d,%d\n", username, hoursSurvived, zombieKills))
                playerFound = true
            else
                fileWriter:write(line .. "\n")
            end
            line = fileReader:readLine()
        end
        fileReader:close()
    end

    if not playerFound then
        fileWriter:write(string.format("%s,%d,%d\n", username, hoursSurvived, zombieKills))
    end

    fileWriter:close()

    -- Atomically replace the old file with the new one
    local success = ZomboidFileSystem.instance:rename(tempFilePath, filePath)

    if not success then
        print("[ServerPlayerTierHandler] ERROR: Failed to rename temporary file. Data may not have been saved.")
        return
    end

    print("[ServerPlayerTierHandler] Saved tier data for user: " .. username)
    sendServerCommand(player, "PlayerTierHandler", "saveSurvivedHoursResponse",
        { username = username, hours = hoursSurvived, zombieKills = zombieKills })
end

-- Function to load the player's tier data from a file
function ServerPlayerTierHandler.loadPlayerSurvivedHours(player, args)
    if not player then return end
    local username = args and args.username or player:getUsername()
    local filePath = "server-player-tier.ini"

    local fileReader = getFileReader(filePath, true)
    if not fileReader then
        print("[ServerPlayerTierHandler] No saved data file found. Sending default values for " .. username)
        sendServerCommand(player, "PlayerTierHandler", "loadSurvivedHoursResponse",
            { username = username, hours = 0, zombieKills = 0 })
        return 0, 0
    end

    local line = fileReader:readLine()
    while line do
        local user, hours, kills = line:match("([^,]+),([^,]+),([^,]*)")
        if user and user == username then
            local hoursSurvived = tonumber(hours) or 0
            local zombieKills = tonumber(kills) or 0

            print("[ServerPlayerTierHandler] Loaded tier data for user: " .. username ..
                " - Hours: " .. hoursSurvived .. ", Kills: " .. zombieKills)

            sendServerCommand(player, "PlayerTierHandler", "loadSurvivedHoursResponse",
                { username = username, hours = hoursSurvived, zombieKills = zombieKills })

            fileReader:close()
            return hoursSurvived, zombieKills
        end
        line = fileReader:readLine()
    end

    fileReader:close()

    -- If we reach here, the player was not in the file
    print("[ServerPlayerTierHandler] No saved data found for user: " .. username .. ". Sending default values.")
    sendServerCommand(player, "PlayerTierHandler", "loadSurvivedHoursResponse",
        { username = username, hours = 0, zombieKills = 0 })
    return 0, 0
end

function ServerPlayerTierHandler.savePlayerExoOperatorLevel(player, args)
    if not player then return end
    local username = player:getUsername()
    -- Use the values passed from client
    local level = args.exoLevel
    local mdUnlocked = args.MDUnlocked or 0
    local rsUnlocked = args.RSUnlocked or 0
    local lvUnlocked = args.LVUnlocked or 0

    local filePath = "server-player-exo-level.ini"
    local tempFilePath = filePath .. ".tmp"
    local playerFound = false

    local fileWriter = getFileWriter(tempFilePath, true, false)
    if not fileWriter then
        print("[ServerPlayerTierHandler] ERROR: Could not open temporary file for writing: " .. tempFilePath)
        return
    end

    local fileReader = getFileReader(filePath, true)
    if fileReader then
        local line = fileReader:readLine()
        while line do
            local user, _, _, _, _ = line:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
            if user and user == username then
                fileWriter:write(string.format("%s,%d,%d,%d,%d\n", username, level, mdUnlocked, rsUnlocked, lvUnlocked))
                playerFound = true
            else
                fileWriter:write(line .. "\n")
            end
            line = fileReader:readLine()
        end
        fileReader:close()
    end

    if not playerFound then
        fileWriter:write(string.format("%s,%d,%d,%d,%d\n", username, level, mdUnlocked, rsUnlocked, lvUnlocked))
    end

    fileWriter:close()

    local success = ZomboidFileSystem.instance:rename(tempFilePath, filePath)
    if not success then
        print("[ServerPlayerTierHandler] ERROR: Failed to rename temporary file for exo level. Data may not have been saved.")
        return
    end

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
end

function ServerPlayerTierHandler.loadPlayerExoOperatorLevel(player)
    if not player then return end
    local username = player:getUsername()
    local filePath = "server-player-exo-level.ini"

    local fileReader = getFileReader(filePath, true)
    if not fileReader then
        print("[ServerPlayerTierHandler] No saved exo operator level data found for user: " .. username)
        sendServerCommand(player, "PlayerTierHandler", "loadExoOperatorLevelResponse", {
            username = username, exoLevel = 1, MDUnlocked = 0, RSUnlocked = 0, LVUnlocked = 0
        })
        return
    end

    local line = fileReader:readLine()
    while line do
        local user, exoLevel, md, rs, lv = line:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        if user and user == username then
            local userData = {
                level = tonumber(exoLevel) or 1,
                md = tonumber(md) or 0,
                rs = tonumber(rs) or 0,
                lv = tonumber(lv) or 0
            }
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
            fileReader:close()
            return
        end
        line = fileReader:readLine()
    end

    fileReader:close()

    -- Player not found in the file, send default values
    print("[ServerPlayerTierHandler] No saved exo operator level data found for user: " .. username)
    sendServerCommand(player, "PlayerTierHandler", "loadExoOperatorLevelResponse", {
        username = username, exoLevel = 1, MDUnlocked = 0, RSUnlocked = 0, LVUnlocked = 0
    })
end

function ServerPlayerTierHandler.setPlayerTier(admin, args)
  if not admin:isAccessLevel("admin") then
      sendServerCommand(admin, "PlayerTierHandler", "tierSetResponse",
          { message = "Error: Only admins can set player tiers." })
      return
  end

  -- Get the target player by username
  local targetUsername = args.targetUsername
  local targetPlayer = nil

  -- Find the target player in the online players
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

  -- Validate tier is in the available tiers
  local validTier = false
  local tierValue = 1
  local availableTiers = { "Newbies", "Adventurer", "Veteran", "Champion", "Legend", "Immortal", "Mythic", "Godlike" }

  -- FIX: Don't use the same variable name for the loop counter and flag
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

  -- Update target player's tier
  local modData = targetPlayer:getModData()
  modData.PlayerTier = tier
  modData.PlayerTierValue = tierValue
  modData.TierSetManually = true

  -- Save the tier to the server tier file
  local filePath = "server-player-tier-manual.ini"
  local fileWriter = getFileWriter(filePath, true, false)
  if fileWriter then
      fileWriter:write(targetUsername .. "," .. tier .. "," .. tierValue .. "\n")
      fileWriter:close()
  end

  -- Notify admin of success
  sendServerCommand(admin, "PlayerTierHandler", "tierSetResponse",
      { message = "Successfully set " .. targetUsername .. "'s tier to " .. tier })

  -- Notify target player of tier change
  sendServerCommand(targetPlayer, "PlayerTierHandler", "tierUpdated",
      { tier = tier, tierValue = tierValue,
        message = "An admin has set your tier to " .. tier })

  print("[ServerPlayerTierHandler] Admin " .. admin:getUsername() ..
        " set " .. targetUsername .. "'s tier to " .. tier)
end


Events.OnClientCommand.Add(function(module, command, player, args)
  if module == "PlayerTierHandler" then
      if command == "saveSurvivedHours" then
          ServerPlayerTierHandler.savePlayerSurvivedHours(player)
      elseif command == "loadSurvivedHours" then
          ServerPlayerTierHandler.loadPlayerSurvivedHours(player, args)
      elseif command == "saveExoOperatorLevel" then
          ServerPlayerTierHandler.savePlayerExoOperatorLevel(player, args)
      elseif command == "loadExoOperatorLevel" then
          ServerPlayerTierHandler.loadPlayerExoOperatorLevel(player)
      elseif command == "loadPlayerTier" then
          ServerPlayerTierHandler.loadPlayerSurvivedHours(player, args)
      elseif command == "setUnlimitedEnduranceAndTrait" then
          ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
      elseif command == "setPlayerTier" then
          -- Debugging info
          print("[ServerPlayerTierHandler] Received setPlayerTier command from " .. player:getUsername())
          for k, v in pairs(args) do
              print("  " .. k .. " = " .. tostring(v))
          end

          ServerPlayerTierHandler.setPlayerTier(player, args)
      end
  end
end)

Events.EveryDays.Add(function()
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        -- local username = player:getUsername()
        if player then
            ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
        end
    end
end)

return ServerPlayerTierHandler