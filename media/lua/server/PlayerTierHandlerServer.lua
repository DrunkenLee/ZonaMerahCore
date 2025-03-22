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
        if player:HasTrait("FearOfBlood") then
            player:getTraits():remove("FearOfBlood")
        end
        if player:HasTrait("Cowardly") then
            player:getTraits():remove("Cowardly")
        end
        if not player:HasTrait("ThickSkinned") then
            player:getTraits():add("ThickSkinned")
        end
        if not player:HasTrait("LowThirst") then
            player:getTraits():add("LowThirst")
        end
        if not player:HasTrait("LightEater") then
            player:getTraits():add("LightEater")
        end
        if player:HasTrait("ThinSkinned") then
            player:getTraits():remove("ThinSkinned")
        end
        if player:HasTrait("HeartyAppetite") then
            player:getTraits():remove("HeartyAppetite")
        end
        if player:HasTrait("HighThirst") then
            player:getTraits():remove("HighThirst")
        end
        if not player:HasTrait("Resilient") then
          player:getTraits():add("Resilient")
        end
        if not player:HasTrait("Brave") then
          player:getTraits():add("Brave")
        end
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

  -- Read existing data from the file
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

  -- Update the data with the current player's information
  data[username] = { hours = hoursSurvived, kills = zombieKills }

  -- Write the updated data back to the file
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

-- Function to load the player's tier data from a file
function ServerPlayerTierHandler.loadPlayerSurvivedHours(player)
  if not player then return end
  local username = player:getUsername()

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

  -- Send response back to client
  sendServerCommand(player, "PlayerTierHandler", "loadSurvivedHoursResponse",
      { username = username, hours = userData.hours, zombieKills = userData.kills })

  return userData.hours, userData.kills
end

function getPlayerFromUsername(username)
  for i = 0, getNumActivePlayers() - 1 do
      local player = getSpecificPlayer(i)
      if player and player:getUsername() == username then
          print("[ServerPlayerTierHandler] Player found: " .. username)
          return player
      end
  end
  print("[ServerPlayerTierHandler] Player not found: " .. username)
  return nil
end

-- Function to save the player's Exo Operator Level to a file
function ServerPlayerTierHandler.savePlayerExoOperatorLevel(player, args)
  if not player then return end
  local username = player:getUsername()
  -- Use the level passed from client instead of reading from modData
  local level = args.exoLevel

  local filePath = "server-player-exo-level.ini"
  local data = {}

  -- Read existing data from the file
  local file = getFileReader(filePath, true)
  if file then
      local line = file:readLine()
      while line do
          local user, exoLevel = line:match("([^,]+),([^,]+)")
          data[user] = tonumber(exoLevel) or 1
          line = file:readLine()
      end
      file:close()
  end

  -- Update the data with the current player's information
  data[username] = level

  -- Write the updated data back to the file
  local fileWriter = getFileWriter(filePath, true, false)
  if fileWriter then
      for user, userLevel in pairs(data) do
          fileWriter:write(string.format("%s,%d\n", user, userLevel))
      end
      fileWriter:close()
      print("[ServerPlayerTierHandler] Saved exo operator level for user: " .. username .. " - Level: " .. level)
      sendServerCommand(player, "PlayerTierHandler", "saveExoOperatorLevelResponse",
        { username = username, exoLevel = level })
  else
      error("Failed to open file for writing: " .. filePath)
  end
end

-- Function to load the player's Exo Operator Level from a file
function ServerPlayerTierHandler.loadPlayerExoOperatorLevel(player)
  if not player then return end
  local username = player:getUsername()

  local filePath = "server-player-exo-level.ini"
  local file = getFileReader(filePath, true)
  if not file then
      print("[ServerPlayerTierHandler] No saved exo operator level data found for user: " .. username)
      sendServerCommand(player, "PlayerTierHandler", "loadExoOperatorLevelResponse",
        { username = username, exoLevel = 1 })
      return 1
  end

  local data = {}
  local line = file:readLine()
  while line do
      local user, exoLevel = line:match("([^,]+),([^,]+)")
      data[user] = tonumber(exoLevel) or 1
      line = file:readLine()
  end
  file:close()

  local level = data[username] or 1
  print("[ServerPlayerTierHandler] Loaded exo operator level for user: " .. username .. " - Level: " .. level)

  -- Send response back to client
  sendServerCommand(player, "PlayerTierHandler", "loadExoOperatorLevelResponse",
      { username = username, exoLevel = level })

  return level
end

-- Update the OnClientCommand handler to process exo operator level commands
Events.OnClientCommand.Add(function(module, command, player, args)
  if module == "PlayerTierHandler" then
      if command == "saveSurvivedHours" then
          ServerPlayerTierHandler.savePlayerSurvivedHours(player)
      elseif command == "loadSurvivedHours" then
          ServerPlayerTierHandler.loadPlayerSurvivedHours(player)
      elseif command == "saveExoOperatorLevel" then
          ServerPlayerTierHandler.savePlayerExoOperatorLevel(player, args)
      elseif command == "loadExoOperatorLevel" then
          ServerPlayerTierHandler.loadPlayerExoOperatorLevel(player)
      end
  end
end)

-- Helper function to get a player object by username
function getPlayerFromUsername(username)
  for i = 0, getNumActivePlayers() - 1 do
      local player = getSpecificPlayer(i)
      if player and player:getUsername() == username then
          return player
      end
  end
  return nil
end

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