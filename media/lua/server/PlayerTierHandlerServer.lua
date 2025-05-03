require "PlayerConfig"
require "PlayerTierHandler"
require "PlayerTitleHandler"

ServerPlayerTierHandler = {}

function ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
    local tier = PlayerTierHandler.getPlayerTier(player) or "NO_TIER"
    if tier == "Godlike" then
        player:setUnlimitedEndurance(false)
        if not player:HasTrait("Desensitized") then
            player:getTraits():add("Desensitized")
        end
        player:setUnlimitedEndurance(true)
    elseif tier == "Mythic" then
        player:setUnlimitedEndurance(false)
    elseif tier == "Immortal" then
        player:setUnlimitedEndurance(false)
    elseif tier == "Legend" then
        player:setUnlimitedEndurance(false)
    elseif tier == "Newbies" then
        player:setUnlimitedEndurance(false)
    end
end

function ServerPlayerTierHandler.savePlayerSurvivedHours(player)
  if not player then return end
  local username = player:getUsername()
  local hoursSurvived = player:getHoursSurvived()
  local zombieKills = player:getZombieKills()

  local filePath = "server-player-tier.ini"
  local data = {}

  local file = getFileReader(filePath, true)
  if file then
      local line = file:readLine()
      while line do
          local user, hours, kills = line:match("([^,]+),([^,]+),([^,]*)")
          data[user] = { hours = tonumber(hours), kills = tonumber(kills) or 0 }
          line = file:readLine()
      end
      file:close()
  end

  data[username] = { hours = hoursSurvived, kills = zombieKills }

  local fileWriter = getFileWriter(filePath, true, false)
  if fileWriter then
      for user, userData in pairs(data) do
          fileWriter:write(string.format("%s,%d,%d\n", user, userData.hours, userData.kills))
      end
      fileWriter:close()
      print("[ServerPlayerTierHandler] Saved tier data for user: " .. username)
      sendServerCommand(player, "PlayerTierHandler", "saveSurvivedHoursResponse",
        { username = username, hours = hoursSurvived, zombieKills = zombieKills })
  else
      error("Failed to open file for writing: " .. filePath)
  end
end

function ServerPlayerTierHandler.loadPlayerSurvivedHours(player, args)
  if not player then return end
  local username = args and args.username or player:getUsername()

  local filePath = "server-player-tier.ini"
  local file = getFileReader(filePath, true)
  if not file then
      print("[ServerPlayerTierHandler] No saved data found for user: " .. username)
      sendServerCommand(player, "PlayerTierHandler", "loadSurvivedHoursResponse",
          { username = username, hours = 0, zombieKills = 0 })
      return 0, 0
  end

  local data = {}
  local line = file:readLine()
  while line do
      local user, hours, kills = line:match("([^,]+),([^,]+),([^,]*)")
      data[user] = { hours = tonumber(hours), kills = tonumber(kills) or 0 }
      line = file:readLine()
  end
  file:close()

  local userData = data[username] or { hours = 0, kills = 0 }
  print("[ServerPlayerTierHandler] Loaded tier data for user: " .. username ..
      " - Hours: " .. userData.hours .. ", Kills: " .. userData.kills)

  sendServerCommand(player, "PlayerTierHandler", "loadSurvivedHoursResponse",
      { username = username, hours = userData.hours, zombieKills = userData.kills })

  return userData.hours, userData.kills
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
  local data = {}

  -- Read existing data from the file
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
  if not player then return end
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

  -- Send response back to client
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
  local availableTiers = { "Newbies", "Adventurer", "Veteran", "Champion", "Legend", "Immortal", "Mythic", "Godlike" }

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
  modData.TierSetManually = true

  local filePath = "server-player-tier-manual.ini"
  local fileWriter = getFileWriter(filePath, true, false)
  if fileWriter then
      fileWriter:write(targetUsername .. "," .. tier .. "," .. tierValue .. "\n")
      fileWriter:close()
  end

  sendServerCommand(admin, "PlayerTierHandler", "tierSetResponse",
      { message = "Successfully set " .. targetUsername .. "'s tier to " .. tier })

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
        if player then
            ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
        end
    end
end)

return ServerPlayerTierHandler