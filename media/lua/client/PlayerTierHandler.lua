require "PlayerConfig"
require "ISContextMenu"
require "Translate/EN/Sandbox_EN"
require "SpeedFramework"

PlayerTierHandler = {
  historyData = {}
}

local availableTiers = { "Newbies", "Adventurer", "Veteran", "Champion", "Legend", "Immortal", "Mythic", "Godlike" }
local availableExoOperatorLevel = {1 , 2 , 3 , 4 }

-- Utility function to update player stats and store in mod data
function PlayerTierHandler.updatePlayerStats(player, hours, kills)
  if hours then
    player:setHoursSurvived(hours)
    player:getModData().HoursSurvived = hours
  end

  if kills then
    player:setZombieKills(kills)
    player:getModData().ZombieKills = kills
  end
end

function PlayerTierHandler.recordPlayerTier(player)
  if not player then return nil end
  -- Trigger server-side save with both hours and zombie kills
  local username = player:getUsername()
  local hours = player:getHoursSurvived()
  local zombieKills = player:getZombieKills()
  sendClientCommand("PlayerTierHandler", "saveSurvivedHours", {
    username = username,
    hours = hours,
    zombieKills = zombieKills
  })

  Events.OnServerCommand.Add(function(module, command, args)
    if module == "PlayerTierHandler" and command == "saveSurvivedHoursResponse" then
        username = args.username
        hours = args.hours
        zombieKills = args.zombieKills
        print("[ServerResponse] Player: " .. username .. " has survived for " .. hours .. " hours with " .. zombieKills .. " zombie kills.")
    end
  end)
  player:Say("Your tier data has been recorded on the server.")
end

function PlayerTierHandler.reassignRecordedTier(player)
  if not player then return nil end
  local username = player:getUsername()

  -- Trigger server-side load (includes zombie kills now)
  sendClientCommand("PlayerTierHandler", "loadSurvivedHours", {
    username = username
  })

  -- Setup a one-time event listener for the server response
  local eventListener = function(module, command, args)
    if module == "PlayerTierHandler" and command == "loadSurvivedHoursResponse" then
      if args.username == username then
        -- Remove this listener after we've handled our response
        Events.OnServerCommand.Remove(eventListener)

        if args.hours > 0 or args.zombieKills > 0 then
          -- Update player stats with the loaded data
          player:setHoursSurvived(args.hours)
          player:setZombieKills(args.zombieKills)

          -- Also store in modData for reference
          local modData = player:getModData()
          modData.HoursSurvived = args.hours
          modData.ZombieKills = args.zombieKills

          -- Run tier update to make sure tier matches the loaded stats
          PlayerTierHandler.updatePlayerTier(player)

          local survivalDays = math.floor(args.hours / 24)
          player:Say("Loaded tier data: " .. survivalDays .. " days survived with " .. args.zombieKills .. " zombie kills")
        else
          player:Say("No previous tier data found on server.")
        end
      end
    end
  end

  Events.OnServerCommand.Add(eventListener)
  player:Say("Requesting your tier data from the server...")
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
  modData.TierSetManually = true

  -- Update survival time and zombie kills based on the tier
  if tier == "Newbies" then
      PlayerTierHandler.updatePlayerStats(targetPlayer, 5 * 24, 0) -- 5 days
      modData.PlayerTierValue = 1
  elseif tier == "Adventurer" then
      PlayerTierHandler.updatePlayerStats(targetPlayer, 10 * 24, 150) -- 10 days
      modData.PlayerTierValue = 2
  elseif tier == "Veteran" then
      PlayerTierHandler.updatePlayerStats(targetPlayer, 17.5 * 24, 500) -- 17.5 days
      modData.PlayerTierValue = 3
  elseif tier == "Champion" then
      PlayerTierHandler.updatePlayerStats(targetPlayer, 25 * 24, 2000) -- 25 days
      modData.PlayerTierValue = 4
  elseif tier == "Legend" then
      PlayerTierHandler.updatePlayerStats(targetPlayer, 36 * 24, 4000) -- 36 days
      modData.PlayerTierValue = 5
  elseif tier == "Immortal" then
      PlayerTierHandler.updatePlayerStats(targetPlayer, 61 * 24, 8000) -- 61 days
      modData.PlayerTierValue = 6
  elseif tier == "Mythic" then
      PlayerTierHandler.updatePlayerStats(targetPlayer, 91 * 24, 10000) -- 91 days
      modData.PlayerTierValue = 7
  elseif tier == "Godlike" then
      PlayerTierHandler.updatePlayerStats(targetPlayer, 121 * 24, 12000) -- 121 days
      modData.PlayerTierValue = 8
  end

  if admin then
      admin:Say("Successfully set " .. targetPlayer:getUsername() .. "'s tier to " .. tier)
  end
  targetPlayer:Say("Your tier has been updated to: " .. tier .. " with appropriate survival time and zombie kills")
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
  -- Existing tier options
  for _, tier in ipairs(availableTiers) do
      context:addOption(
          "Set " .. targetPlayer:getUsername() .. " to " .. tier,
          admin,
          function()
              PlayerTierHandler.setPlayerTier(admin, targetPlayer, tier)
          end
      )
  end

  -- Add Exo Operator Level submenu
  local exoOption = context:addOption("Set " .. targetPlayer:getUsername() .. "'s Exo Operator Level")
  local exoSubMenu = ISContextMenu:getNew(context)
  context:addSubMenu(exoOption, exoSubMenu)

  for _, level in ipairs(availableExoOperatorLevel) do
      exoSubMenu:addOption(
          "Level " .. level,
          admin,
          function()
              PlayerTierHandler.adminSetExoOperatorLevel(admin, targetPlayer, level)
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

  -- Create the main submenu with a label that indicates both options are available
  local submenu = context:getNew(context)
  context:addSubMenu(
      context:addOption("Player Tier Management"),
      submenu
  )

  -- Get online players
  local players = getOnlinePlayers()
  for i = 0, players:size() - 1 do
      local player = players:get(i)
      local username = player:getUsername()
      -- Create a submenu for this player
      local playerSubMenu = submenu:getNew(submenu)
      submenu:addSubMenu(
          submenu:addOption("Manage " .. username),
          playerSubMenu
      )
      -- Add tier options and exo operator level options to this player's submenu
      PlayerTierHandler.addTierOptionsToMenu(playerSubMenu, admin, player)
  end
end

function PlayerTierHandler.updateTierAndGiveXPBoost(player)
  PlayerTierHandler.updatePlayerTier(player)
  PlayerTierHandler.giveXPBoost(player)
  player:Say("Your tier has been updated and boost applied.")
end

-- Function to add "Check My Tier" option to the player's context menu
function PlayerTierHandler.addPlayerTierMenu(playerIndex, context)
  local player = getSpecificPlayer(playerIndex)
  if not player then return end

  -- Add "Check My Tier" option to the context menu
  context:addOption("Check My Tier", player, PlayerTierHandler.checkPlayerTier, player)

  -- Add "Update My Tier and Get XP Boost" option to the context menu
  context:addOption("Update My Tier and Get Boost", player, PlayerTierHandler.updateTierAndGiveXPBoost, player)
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

function PlayerTierHandler.updatePlayerTier(player)
  local modData = player:getModData()
  if modData.TierSetManually then
      return -- Do not update the tier if it was set manually
  end

  local survivalDays = player:getHoursSurvived() / 24
  local zombieKills = player:getZombieKills()
  local newTier = "Newbies"
  local newTierValue = 1

  -- Both survival days AND zombie kills must be met to advance tiers
  if (survivalDays > 5 and zombieKills >= 150) then
      newTier = "Adventurer"
      newTierValue = 2
  end
  if (survivalDays > 15 and zombieKills >= 500) then
      newTier = "Veteran"
      newTierValue = 3
  end
  if (survivalDays > 20 and zombieKills >= 2000) then
      newTier = "Champion"
      newTierValue = 4
  end
  if (survivalDays > 30 and zombieKills >= 4000) then
      newTier = "Legend"
      newTierValue = 5
  end
  if (survivalDays > 36 and zombieKills >= 8000) then
      newTier = "Immortal"
      newTierValue = 6
  end
  if (survivalDays > 61 and zombieKills >= 10000) then
      newTier = "Mythic"
      newTierValue = 7
  end
  if (survivalDays > 91 and zombieKills >= 12000) then
      newTier = "Godlike"
      newTierValue = 8
  end

  local currentTier = modData.PlayerTier
  local currentTierValue = modData.PlayerTierValue
  if currentTier ~= newTier then
      modData.PlayerTier = newTier
      modData.PlayerTierValue = newTierValue
      local intSurvivalDays = math.floor(survivalDays)
      player:Say("You have survived for " .. intSurvivalDays .. " days with " .. zombieKills .. " zombie kills and have been promoted to " .. newTier)
  end
end

function PlayerTierHandler.debugSetSurvivalTime(player, hours)
  PlayerTierHandler.updatePlayerStats(player, hours, nil)
  PlayerTierHandler.updatePlayerTier(player)
  player:Say("Survival time set to " .. hours .. " hours. Tier updated to: " .. PlayerTierHandler.getPlayerTier(player))
end

function PlayerTierHandler.clearHistoryData()
    PlayerTierHandler.historyData = {}
    print("All player tier history data has been cleared.")
end

function PlayerTierHandler.setExoOperatorLevel(player, level)
  if not player then return end
  local modData = player:getModData()

  -- Validate the level is valid
  local validLevel = false
  for _, validValue in ipairs(availableExoOperatorLevel) do
      if level == validValue then
          validLevel = true
          break
      end
  end

  if validLevel then
      modData.ExoOperatorLevel = level
      player:Say("Your Exo Operator Level has been set to: " .. level)

      -- Save to server-side file
      local username = player:getUsername()
      sendClientCommand("PlayerTierHandler", "saveExoOperatorLevel", {
          username = username,
          exoLevel = level
      })

      -- Set up a one-time event listener to confirm save
      local eventListener = function(module, command, args)
          if module == "PlayerTierHandler" and command == "saveExoOperatorLevelResponse" then
              if args.username == username then
                  -- Remove this listener after we've handled our response
                  Events.OnServerCommand.Remove(eventListener)
                  print("[PlayerTierHandler] Successfully saved Exo Operator Level " .. args.exoLevel .. " for " .. username)
              end
          end
      end

      Events.OnServerCommand.Add(eventListener)
      return true
  else
      print("Invalid Exo Operator Level: " .. tostring(level))
      return false
  end
end

function PlayerTierHandler.getExoOperatorLevel(player)
  if not player then return 1 end -- Default to level 1
  local modData = player:getModData()

  -- First check if we already have the value in modData
  if modData.ExoOperatorLevel then
    return modData.ExoOperatorLevel
  end

  -- If not in modData, try to load from server
  local username = player:getUsername()
  sendClientCommand("PlayerTierHandler", "loadExoOperatorLevel", {
    username = username
  })

  -- Set up a one-time event listener for the server response
  local eventListener = function(module, command, args)
    if module == "PlayerTierHandler" and command == "loadExoOperatorLevelResponse" then
      if args.username == username then
        -- Remove this listener after we've handled our response
        Events.OnServerCommand.Remove(eventListener)

        if args.exoLevel and args.exoLevel > 0 then
          -- Store the level in modData for future reference
          modData.ExoOperatorLevel = args.exoLevel
          print("[PlayerTierHandler] Loaded Exo Operator Level for " .. username .. ": " .. args.exoLevel)

          -- Optional notification - remove if not desired
          player:Say("Exo Operator Level synced from server: Level " .. args.exoLevel)
        end
      end
    end
  end

  Events.OnServerCommand.Add(eventListener)

  -- Return the local value (either from modData or default) while waiting for server
  return modData.ExoOperatorLevel or 1
end

-- Function for admins to set Exo Operator Level
function PlayerTierHandler.adminSetExoOperatorLevel(admin, targetPlayer, level)
  if not admin or not targetPlayer then return end

  if PlayerTierHandler.setExoOperatorLevel(targetPlayer, level) then
      admin:Say("Successfully set " .. targetPlayer:getUsername() .. "'s Exo Operator Level to " .. level)
  else
      admin:Say("Failed to set Exo Operator Level for " .. targetPlayer:getUsername())
  end
end

-- Add Exo Operator level options to the admin menu
function PlayerTierHandler.addExoOperatorLevelMenu(context, admin, targetPlayer)
  -- Create a submenu for exo operator levels
  local subMenu = context:getNew(context)
  context:addSubMenu(context:addOption("Set Exo Operator Level"), subMenu)

  -- Add option for each level
  for _, level in ipairs(availableExoOperatorLevel) do
      subMenu:addOption(
          "Level " .. level,
          admin,
          function()
              PlayerTierHandler.adminSetExoOperatorLevel(admin, targetPlayer, level)
          end
      )
  end
end

-- Hook into the EVERY DAY event to give XP boost based on tier and update tier based on survival days
Events.EveryHours.Add(function()
  local players = getOnlinePlayers()
  for i = 0, players:size() - 1 do
      local player = players:get(i)
      PlayerTierHandler.updatePlayerTier(player)
      PlayerTierHandler.giveXPBoost(player)
      ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
  end
end)

-- Hook into the context menu event for admins and players
Events.OnFillWorldObjectContextMenu.Add(PlayerTierHandler.addAdminMenu)
Events.OnFillWorldObjectContextMenu.Add(PlayerTierHandler.addPlayerTierMenu)


Events.OnCreatePlayer.Add(function(playerIndex, player)
    PlayerTierHandler.assignPlayerTier(player)
end)

return PlayerTierHandler