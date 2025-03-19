require "PlayerConfig"
require "PlayerTierHandler"
require "PlayerTitleHandler"

ServerPlayerTierHandler = {}

function ServerPlayerTierHandler.setPlayerTier(admin, targetPlayerUsername, tier)
  local targetPlayer = getPlayerFromUsername(targetPlayerUsername)
  if not targetPlayer then
      if admin then
          admin:Say("Player not found: " .. targetPlayerUsername)
      end
      print("[ServerPlayerTierHandler] Player not found: " .. targetPlayerUsername)
      return
  end

  local modData = targetPlayer:getModData()
  modData.PlayerTier = tier

  -- Update survival time based on the tier
  if tier == "Newbies" then
      targetPlayer:setHoursSurvived(5 * 24) -- 5 days
      modData.PlayerTierValue = 1
  elseif tier == "Adventurer" then
      targetPlayer:setHoursSurvived(10 * 24) -- 10 days
      modData.PlayerTierValue = 2
  elseif tier == "Veteran" then
      targetPlayer:setHoursSurvived(17.5 * 24) -- 17.5 days
      modData.PlayerTierValue = 3
  elseif tier == "Champion" then
      targetPlayer:setHoursSurvived(25 * 24) -- 25 days
      modData.PlayerTierValue = 4
  elseif tier == "Legend" then
      targetPlayer:setHoursSurvived(36 * 24) -- 36 days
      modData.PlayerTierValue = 5
  elseif tier == "Immortal" then
      targetPlayer:setHoursSurvived(61 * 24) -- 61 days
      modData.PlayerTierValue = 6
  elseif tier == "Mythic" then
      targetPlayer:setHoursSurvived(91 * 24) -- 91 days
      modData.PlayerTierValue = 7
  elseif tier == "Godlike" then
      targetPlayer:setHoursSurvived(121 * 24) -- 121 days
      modData.PlayerTierValue = 8
  end

  if admin then
      admin:Say("Successfully set " .. targetPlayerUsername .. "'s tier to " .. tier)
  end
  targetPlayer:Say("Your tier has been updated to: " .. tier)
end

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

-- Function to save the player's survived hours to a file
function ServerPlayerTierHandler.savePlayerSurvivedHours(player)
  if not player then return end
  local username = player:getUsername()
  local hoursSurvived = player:getHoursSurvived()

  local filePath = "server-player-tier.ini"
  local data = {}

  -- Read existing data from the file
  local file = getFileReader(filePath, true)
  if file then
      local line = file:readLine()
      while line do
          local user, hours = line:match("([^,]+),([^,]+)")
          data[user] = tonumber(hours)
          line = file:readLine()
      end
      file:close()
  end

  -- Update the data with the current player's survived hours
  data[username] = hoursSurvived

  -- Write the updated data back to the file
  local fileWriter = getFileWriter(filePath, true, false)
  if fileWriter then
      for user, hours in pairs(data) do
          fileWriter:write(string.format("%s,%d\n", user, hours))
      end
      fileWriter:close()
      print("[ServerPlayerTierHandler] Saved survived hours for user: " .. username)
  else
      error("Failed to open file for writing: " .. filePath)
  end
  print("[ServerPlayerTierHandler] Saved to server file survived hours for user: " .. username .. " - " .. hoursSurvived)
  -- sendServerCommand(player, "PlayerTierHandler", "saveSurvivedHoursResponse", { hoursSurvived = hoursSurvived })
end

-- Function to load the player's survived hours from a file
function ServerPlayerTierHandler.loadPlayerSurvivedHours(player)
  if not player then return end
  local username = player:getUsername()

  local filePath = "server-player-tier.ini"
  local file = getFileReader(filePath, true)
  if not file then
      print("[ServerPlayerTierHandler] No saved data found for user: " .. username)
      return 0
  end

  local data = {}
  local line = file:readLine()
  while line do
      local user, hours = line:match("([^,]+),([^,]+)")
      data[user] = tonumber(hours)
      line = file:readLine()
  end
  file:close()

  local hoursSurvived = data[username] or 0
  print("[ServerPlayerTierHandler] Loaded survived hours for user: " .. username .. " - " .. hoursSurvived)
  return hoursSurvived
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

Events.OnClientCommand.Add(function(module, command, player, args)
  if module == "PlayerTierHandler" then
      if command == "saveSurvivedHours" then
          ServerPlayerTierHandler.savePlayerSurvivedHours(player)
      elseif command == "loadSurvivedHours" then
          local hoursSurvived = ServerPlayerTierHandler.loadPlayerSurvivedHours(player)
          player:setHoursSurvived(hoursSurvived)
      elseif command == "setPlayerTier" then
          local admin = player
          local targetPlayerUsername = args.username
          local tier = args.tier
          ServerPlayerTierHandler.setPlayerTier(admin, targetPlayerUsername, tier)
      elseif command == "applyUnlimitedEnduranceAndTrait" then
          local targetPlayer = getPlayerFromUsername(args.username)
          if targetPlayer then
              ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(targetPlayer)
          else
              print("[ServerPlayerTierHandler] Player not found: " .. args.username)
          end
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