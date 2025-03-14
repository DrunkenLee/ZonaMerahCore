require "PlayerConfig"
require "ISContextMenu"
require "Translate/EN/Sandbox_EN"
require "SpeedFramework"
require "PlayerKillCountServer"

PlayerTierHandler = {
  historyData = {}
}
local availableTiers = { "Newbies", "Adventurer", "Veteran", "Champion", "Legend", "Immortal", "Mythic", "Godlike" }

function PlayerTierHandler.checkPlayerKillScore(player)
  local username = player:getUsername()
  local killCount = PlayerKillCountServer.loadKillCountFromFile(username) or 0
  player:Say("Your current kill score is: " .. killCount)
end

function PlayerTierHandler.claimKillReward(player)
  local username = player:getUsername()
  local killCount = PlayerKillCountServer.loadKillCountFromFile(username)
  local survivorHours = (killCount / 100) * 10
  local survivorHoursDecimal = string.format("%.2f", survivorHours)

  -- Reset kill count to 0
  PlayerKillCountServer.saveKillCountToFile(username, 0)

  -- Set survived hours
  player:setHoursSurvived(player:getHoursSurvived() + survivorHours)
  player:Say("You have claimed your kill reward! Your kill score has been reset, and you have gained " .. survivorHoursDecimal .. " survival hours.")
end

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

function PlayerTierHandler.recordPlayerTier(player)
  if not player then return nil end
  local username = player:getUsername()
  local tierValue = PlayerTierHandler.getPlayerTierValue(player)
  local hoursSurvived = player:getHoursSurvived()
  local recordedTier = {
      hoursSurvived = hoursSurvived,
      tierValue = tierValue
  }
  saveTierDataToFile(username, recordedTier)
  player:Say("Tier data is recorded for " .. username)
  return recordedTier
end

function PlayerTierHandler.reassignRecordedTier(player)
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

-- Function to assign tier based on the PlayerConfig file
function PlayerTierHandler.assignPlayerTier(player)
    local modData = player:getModData()
    local username = player:getUsername()

    -- Assign tier from PlayerConfig or default to Tier 1
    local tier = PlayerConfig[username] or availableTiers[1]
    local tierValue = 1
    modData.PlayerTier = tier
    modData.PlayerTierValue = tierValue
end

-- Function to assign a tier to a player dynamically
function PlayerTierHandler.setPlayerTier(admin, targetPlayer, tier)
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

  -- Save the updated tier data to the file
  local username = targetPlayer:getUsername()
  local recordedTier = {
      hoursSurvived = targetPlayer:getHoursSurvived(),
      tierValue = modData.PlayerTierValue
  }
  saveTierDataToFile(username, recordedTier)

  if admin then
      admin:Say("Successfully set " .. targetPlayer:getUsername() .. "'s tier to " .. tier)
  end
  targetPlayer:Say("Your tier has been updated to: " .. tier)
end

-- Function to save a player's progress
function PlayerTierHandler.savePlayerProgress(admin, targetPlayer)
    PlayerTierHandler.recordPlayerTier(targetPlayer)
    if admin then
        admin:Say("Successfully saved " .. targetPlayer:getUsername() .. "'s progress.")
    end
end

-- Function to expose the modData for other mods
function PlayerTierHandler.getPlayerTierValue(player)
  if not player then return nil end
  local modData = player:getModData()
  return modData.PlayerTierValue or 1 -- Default to Tier Value 1 if not set
end

function PlayerTierHandler.getPlayerTier(player)
    if not player then return nil end
    local modData = player:getModData()
    return modData.PlayerTier or "Newbies" -- Default to Tier 1 if not set
end

-- Function to display the player's tier
function PlayerTierHandler.checkPlayerTier(player)
    local tier = PlayerTierHandler.getPlayerTier(player)
    local survivalDays = player:getHoursSurvived() / 24
    local intSurvivalDays = math.floor(survivalDays)
    player:Say("Your current tier is: " .. tier .. " and you have survived for " .. intSurvivalDays .. " days.")
end

-- Function to add tier options for a specific player
function PlayerTierHandler.addTierOptionsToMenu(context, admin, targetPlayer)
    for _, tier in ipairs(availableTiers) do
        context:addOption(
            "Set " .. targetPlayer:getUsername() .. " to " .. tier,
            admin,
            function()
                PlayerTierHandler.setPlayerTier(admin, targetPlayer, tier)
            end
        )
    end
    -- Add option to save player's progress
    context:addOption(
        "Save " .. targetPlayer:getUsername() .. "'s Progress",
        admin,
        function()
            PlayerTierHandler.savePlayerProgress(admin, targetPlayer)
        end
    )
end

-- Function to render the admin menu for assigning tiers
function PlayerTierHandler.addAdminMenu(playerIndex, context)
    local admin = getSpecificPlayer(playerIndex)
    if not admin or not admin:isAccessLevel("admin") then return end

    local submenu = context:getNew(context) -- Create a submenu
    context:addSubMenu(
        context:addOption("Set Player Tier"),
        submenu
    )
    local players = getOnlinePlayers()
    -- Add each connected player to the submenu
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        local username = player:getUsername()
        local subSubMenu = submenu:getNew(submenu)
        submenu:addSubMenu(
            submenu:addOption("Set Tier for " .. username),
            subSubMenu
        )
        PlayerTierHandler.addTierOptionsToMenu(subSubMenu, admin, player)
    end
end

-- Function to add "Check My Tier" option to the player's context menu
function PlayerTierHandler.addPlayerTierMenu(playerIndex, context)
  local player = getSpecificPlayer(playerIndex)
  if not player then return end

  -- Add "Check My Tier" option to the context menu
  context:addOption("Check My Tier", player, PlayerTierHandler.checkPlayerTier, player)

  -- Add "Check My Kill Score" option to the context menu
  context:addOption("Check My Kill Score", player, PlayerTierHandler.checkPlayerKillScore, player)

  -- Add "Claim Kill Reward" option to the context menu
  context:addOption("Claim Kill Reward", player, PlayerTierHandler.claimKillReward, player)
end

function PlayerTierHandler.giveXPBoost(player)
  local tier = PlayerTierHandler.getPlayerTier(player)
  local tierValue = player:getModData().PlayerTierValue
  local bonusMultiplier = 0
  local message = ""

  if tier == "Newbies" then
      bonusMultiplier = 1.0 -- No boost
      message = "No Bonus Applied"
  elseif tier == "Adventurer" then
      bonusMultiplier = 1.1 -- 10% boost
      SpeedFramework.SetPlayerSpeed(player, bonusMultiplier)
      message = "Adventurer Bonus Applied"
  elseif tier == "Veteran" then
      bonusMultiplier = 1.2 -- 20% boost
      SpeedFramework.SetPlayerSpeed(player, bonusMultiplier)
      message = "Veteran Bonus Applied"
  elseif tier == "Champion" then
      bonusMultiplier = 1.3 -- 30% boost
      SpeedFramework.SetPlayerSpeed(player, bonusMultiplier)
      message = "Champion Bonus Applied"
  elseif tier == "Legend" or tierValue >= 5 and tierValue < 6 then
      bonusMultiplier = 1.5 -- 50% boost
      SpeedFramework.SetPlayerSpeed(player, bonusMultiplier)
      message = "Legend Bonus Applied"
  elseif tier == "Immortal" or tierValue >= 6 and tierValue < 7 then
      bonusMultiplier = 1.5 -- 50% boost
      SpeedFramework.SetPlayerSpeed(player, bonusMultiplier)
      message = "Immortal Bonus Applied"
  elseif tier == "Mythic" or tierValue >= 7 and tierValue < 8 then
      bonusMultiplier = 1.5 -- 50% boost
      SpeedFramework.SetPlayerSpeed(player, bonusMultiplier)
      message = "Mythic Bonus Applied"
  elseif tier == "Godlike" or tierValue >= 8 then
      bonusMultiplier = 1.5 -- 50% boost
      SpeedFramework.SetPlayerSpeed(player, bonusMultiplier)
      message = "Godlike Bonus Applied"
  end
  player:Say(message)
end

function PlayerTierHandler.updatePlayerTierBasedOnSurvivalDays(player)
  local modData = player:getModData()
  if modData.TierSetManually then
      return -- Do not update the tier if it was set manually
  end

  local survivalDays = player:getHoursSurvived() / 24
  local newTier = "Newbies"
  local newTierValue = 1

  if survivalDays > 5 and survivalDays <= 15 then
      newTier = "Adventurer"
      newTierValue = 2
  elseif survivalDays > 15 and survivalDays <= 20 then
      newTier = "Veteran"
      newTierValue = 3
  elseif survivalDays > 20 and survivalDays <= 30 then
      newTier = "Champion"
      newTierValue = 4
  elseif survivalDays > 30 and survivalDays <= 36 then
      newTier = "Legend"
      newTierValue = 5
  elseif survivalDays > 36 and survivalDays <= 61 then
      newTier = "Immortal"
      newTierValue = 6
  elseif survivalDays > 61 and survivalDays <= 91 then
      newTier = "Mythic"
      newTierValue = 7
  elseif survivalDays > 91 then
      newTier = "Godlike"
      newTierValue = 8
  end

  local currentTier = modData.PlayerTier
  local currentTierValue = modData.PlayerTierValue
  if currentTier ~= newTier then
      modData.PlayerTier = newTier
      modData.PlayerTierValue = newTierValue
      local intSurvivalDays = math.floor(survivalDays)
      player:Say("You have survived and proved yourself for " .. intSurvivalDays .. " days and have been promoted to " .. newTier)
  end
end

function PlayerTierHandler.debugSetSurvivalTime(player, hours)
  player:setHoursSurvived(hours)
  PlayerTierHandler.updatePlayerTierBasedOnSurvivalDays(player)
  player:Say("Survival time set to " .. hours .. " hours. Tier updated to: " .. PlayerTierHandler.getPlayerTier(player))
end

function PlayerTierHandler.clearHistoryData()
    PlayerTierHandler.historyData = {}
    print("All player tier history data has been cleared.")
end

-- Hook into the EveryTenMinutes event to give XP boost based on tier and update tier based on survival days
Events.EveryHours.Add(function()
  local players = getOnlinePlayers()
  for i = 0, players:size() - 1 do
      local player = players:get(i)
      PlayerTierHandler.updatePlayerTierBasedOnSurvivalDays(player)
      PlayerTierHandler.giveXPBoost(player)
  end
end)

-- Hook into the context menu event for admins and players
Events.OnFillWorldObjectContextMenu.Add(PlayerTierHandler.addAdminMenu)
Events.OnFillWorldObjectContextMenu.Add(PlayerTierHandler.addPlayerTierMenu)

-- Hook into player creation event to assign the tier on spawn
Events.OnCreatePlayer.Add(function(playerIndex, player)
    PlayerTierHandler.assignPlayerTier(player)
end)

return PlayerTierHandler