require "PlayerConfig"

local availableTiers = { "Newbies", "Adventurer", "Veteran", "Champion", "Legend", "Immortal", "Mythic", "Godlike" }

local function saveTierDataToFile(username, tierData)
  local filePath = "player_tier_data.ini"
  local data = {}

  -- Read existing data from file if it exists
  local file = getFileReader(filePath, true)
  if file then
      local line = file:readLine()
      while line do
          local user, hoursSurvived, tierValue = line:match("([^,]+),([^,]+),([^,]+)")
          data[user] = { hoursSurvived = tonumber(hoursSurvived), tierValue = tonumber(tierValue) }
          line = file:readLine()
      end
      file:close()
  end

  -- Update data with new tier data
  data[username] = tierData

  -- Write updated data back to file
  local fileWriter = getFileWriter(filePath, true, false)
  if fileWriter then
      for user, tierData in pairs(data) do
          fileWriter:write(string.format("%s,%d,%d\n", user, tierData.hoursSurvived, tierData.tierValue))
      end
      fileWriter:close()
  else
      error("Failed to open file for writing: " .. filePath)
  end
end

local function loadTierDataFromFile(username)
  local filePath = "player_tier_data.ini"
  local file = getFileReader(filePath, true)
  if not file then return nil end

  local data = {}
  local line = file:readLine()
  while line do
      local user, hoursSurvived, tierValue = line:match("([^,]+),([^,]+),([^,]+)")
      data[user] = { hoursSurvived = tonumber(hoursSurvived), tierValue = tonumber(tierValue) }
      line = file:readLine()
  end
  file:close()

  return data[username]
end

function PlayerTierServer.recordPlayerTier(player)
  if not player then return nil end
  local username = player:getUsername()
  local tierValue = PlayerTierServer.getPlayerTierValue(player)
  local hoursSurvived = player:getHoursSurvived()
  local recordedTier = {
      hoursSurvived = hoursSurvived,
      tierValue = tierValue
  }
  print("Recorded tier data: " .. username .. " - " .. hoursSurvived .. " - " .. tierValue)
  saveTierDataToFile(username, recordedTier)
  player:Say("Tier data is recorded for " .. username)
  return recordedTier
end

function PlayerTierServer.reassignRecordedTier(player)
  if not player then return nil end
  local username = player:getUsername()
  local recordedTier = loadTierDataFromFile(username)

  if recordedTier then
      player:setHoursSurvived(recordedTier.hoursSurvived)
      local modData = player:getModData()
      modData.PlayerTierValue = recordedTier.tierValue
      player:Say("Your tier and survival time have been reassigned based on recorded data.")
  else
      player:Say("No recorded tier data found for reassignment.")
  end
end

function PlayerTierServer.assignPlayerTier(player)
    local modData = player:getModData()
    local username = player:getUsername()

    -- Assign tier from PlayerConfig or default to Tier 1
    local tier = PlayerConfig[username] or availableTiers[1]
    local tierValue = 1
    modData.PlayerTier = tier
    modData.PlayerTierValue = tierValue
end

function PlayerTierServer.getPlayerTierValue(player)
  if not player then return nil end
  local modData = player:getModData()
  return modData.PlayerTierValue or 1 -- Default to Tier Value 1 if not set
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "PlayerTierHandler" then
        if command == "recordPlayerTier" then
            PlayerTierServer.recordPlayerTier(player)
        elseif command == "reassignRecordedTier" then
            PlayerTierServer.reassignRecordedTier(player)
        elseif command == "assignPlayerTier" then
            PlayerTierServer.assignPlayerTier(player)
        end
    end
end)