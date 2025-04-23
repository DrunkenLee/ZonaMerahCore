require "PlayerConfig"
require "ISContextMenu"
require "Translate/EN/Sandbox_EN"
require "SpeedFramework"
require "PlayerTitleHandler"

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

  -- Trigger server-side save
  sendClientCommand("PlayerTierHandler", "saveSurvivedHours", {})

  player:Say("Your tier data has been recorded on the server.")
end

function PlayerTierHandler.loadPlayerTierFromFile(player)
  if not player then return nil end

  -- Trigger server-side load
  sendClientCommand("PlayerTierHandler", "loadSurvivedHours", {})

  player:Say("Requesting your tier data from the server...")
end

-- New function to explicitly request tier data from server
function PlayerTierHandler.loadTierFromServer(player)
  if not player then return end
  local username = player:getUsername()

  sendClientCommand("PlayerTierHandler", "loadPlayerTier", {
      username = username
  })

  player:Say("Requesting your tier data from the server...")
end

function PlayerTierHandler.reassignRecordedTier(player)
  if not player then return nil end
  local username = player:getUsername()

  -- Trigger server-side load (includes zombie kills now)
  sendClientCommand("PlayerTierHandler", "loadSurvivedHours", {
    username = username
  })

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
  -- Send command to server instead of modifying directly
  print("Sending request to set " .. targetPlayer:getUsername() .. "'s tier to " .. tier)
  sendClientCommand("PlayerTierHandler", "setPlayerTier", {
    adminUsername = admin:getUsername(),
    targetUsername = targetPlayer:getUsername(),
    tier = tier
  })

  admin:Say("Sending request to set " .. targetPlayer:getUsername() .. "'s tier to " .. tier)
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

function PlayerTierHandler.updateTierAndGiveXPBoost(player)
  PlayerTierHandler.updatePlayerTier(player)
  PlayerTierHandler.giveXPBoost(player)
  -- Send command to server to set unlimited endurance and trait if needed
  sendClientCommand("PlayerTierHandler", "setUnlimitedEnduranceAndTrait", { username = player:getUsername() })
  -- player:Say("Your tier has been updated and boost applied.")
end

-- Function to add "Check My Tier" option to the player's context menu
function PlayerTierHandler.addPlayerTierMenu(playerIndex, context)
  local player = getSpecificPlayer(playerIndex)
  if not player then return end


    -- Check if player has title level >= 1
  local playerTitle = tonumber(PlayerTitleHandler.getPlayerTitle(player)) or 0
  if not playerTitle or playerTitle < 1 then
    context:addOption("Check My Tier", player, PlayerTierHandler.checkPlayerTier, player)
    context:addOption("Update My Tier and Get Boost", player, PlayerTierHandler.updateTierAndGiveXPBoost, player)
  else
    context:addOption("Check My Tier", player, PlayerTierHandler.checkPlayerTier, player)
    context:addOption("Update My Tier and Get Boost", player, PlayerTierHandler.updateTierAndGiveXPBoost, player)
    context:addOption("VIP: (DANGER!) Update My Tier To Minimum VIP Min Tier", player, PlayerTierHandler.loadTierFromServer, player)
  end
end

function PlayerTierHandler.giveXPBoost(player)
  local tier = PlayerTierHandler.getPlayerTier(player)
  local tierValue = player:getModData().PlayerTierValue
  local bonusMultiplier = 0
  local message = ""

  if tier == "Newbies" then
      bonusMultiplier = 1.01 -- No boost (0%)
      message = "No Bonus Applied"
  elseif tier == "Adventurer" then
      bonusMultiplier = 1.04 -- 4% boost
      message = "Adventurer Bonus Applied (+4%)"
  elseif tier == "Veteran" then
      bonusMultiplier = 1.09 -- 9% boost
      message = "Veteran Bonus Applied (+9%)"
  elseif tier == "Champion" then
      bonusMultiplier = 1.13 -- 13% boost
      message = "Champion Bonus Applied (+13%)"
  elseif tier == "Legend" then
      bonusMultiplier = 1.17 -- 17% boost
      message = "Legend Bonus Applied (+17%)"
  elseif tier == "Immortal" then
      bonusMultiplier = 1.21 -- 21% boost
      message = "Immortal Bonus Applied (+21%)"
  elseif tier == "Mythic" then
      bonusMultiplier = 1.26 -- 26% boost
      message = "Mythic Bonus Applied (+26%)"
  elseif tier == "Godlike" then
      bonusMultiplier = 1.3 -- 30% boost
      message = "Godlike Bonus Applied (+30%)"
  end

  SpeedFramework.SetPlayerSpeed(player, bonusMultiplier)
  -- player:Say(message)
end

function PlayerTierHandler.updatePlayerTier(player, forceUpdate)
  if not player then return false end
  local modData = player:getModData()

  local survivalDays = player:getHoursSurvived() / 24
  local zombieKills = player:getZombieKills()

  -- Check player title and apply minimum stats for VIPs
  local playerTitle = 0
  if isClient and PlayerTitleHandler and PlayerTitleHandler.getPlayerTitle then
    playerTitle = tonumber(PlayerTitleHandler.getPlayerTitle(player)) or 0
    playerTitle = tonumber(PlayerTitleHandler.getPlayerTitle(player))
  end
  local statsChanged = false

  -- Title = 1 (VIP) must have at least Champion stats
  if playerTitle == 1 then
    local minDays = 21  -- > 20 days needed for Champion
    local minKills = 2000

    if survivalDays < minDays then
      local minHours = minDays * 24
      player:setHoursSurvived(minHours)
      modData.HoursSurvived = minHours
      survivalDays = minDays
      statsChanged = true
    end

    if zombieKills < minKills then
      player:setZombieKills(minKills)
      modData.ZombieKills = minKills
      zombieKills = minKills
      statsChanged = true
    end

    if statsChanged then
      player:Say("Your stats have been boosted to match your VIP status!")
    end
  end

  -- Title >= 2 (VVIP or MVP) must have at least Legend stats
  if playerTitle >= 2 then
    local minDays = 31  -- > 30 days needed for Legend
    local minKills = 4000

    if survivalDays < minDays then
      local minHours = minDays * 24
      player:setHoursSurvived(minHours)
      modData.HoursSurvived = minHours
      survivalDays = minDays
      statsChanged = true
    end

    if zombieKills < minKills then
      player:setZombieKills(minKills)
      modData.ZombieKills = minKills
      zombieKills = minKills
      statsChanged = true
    end

    if statsChanged then
      player:Say("Your stats have been boosted to match your VVIP/MVP status!")
    end
  end

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

  -- We still check minimum tier requirements as a safety measure
  -- Title = 1 (VIP) must be at least Champion
  if playerTitle == 1 and newTierValue < 4 then
      newTier = "Champion"
      newTierValue = 4
  end

  -- Title >= 2 (VVIP or MVP) must be at least Legend
  if playerTitle >= 2 and newTierValue < 5 then
      newTier = "Legend"
      newTierValue = 5
  end

  local currentTier = modData.PlayerTier
  local currentTierValue = modData.PlayerTierValue

  -- Update if tier changed OR stats changed OR forceUpdate is true
  if currentTier ~= newTier or statsChanged or forceUpdate == true then
      modData.PlayerTier = newTier
      modData.PlayerTierValue = newTierValue
      local intSurvivalDays = math.floor(survivalDays)
      -- player:Say("You have survived for " .. intSurvivalDays .. " days with " .. zombieKills .. " zombie kills and have been promoted to " .. newTier)

      -- Add message if tier was upgraded due to title status
      if (playerTitle == 1 and newTierValue == 4 and survivalDays <= 20) or
         (playerTitle >= 2 and newTierValue == 5 and survivalDays <= 30) then
          player:Say("Your tier was boosted due to your Supporter status!")
      end

      return true -- Return true if tier was updated
  end

  return false -- Return false if no update occurred
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

      -- Initialize location permissions if they don't exist
      if not modData.MDExoUnlocked then modData.MDExoUnlocked = 0 end
      if not modData.RSExoUnlocked then modData.RSExoUnlocked = 0 end
      if not modData.LVExoUnlocked then modData.LVExoUnlocked = 0 end

      player:Say("Your Exo Operator Level has been set to: " .. level)

      -- Save to server-side file
      local username = player:getUsername()
      sendClientCommand("PlayerTierHandler", "saveExoOperatorLevel", {
          username = username,
          exoLevel = level,
          MDUnlocked = modData.MDExoUnlocked,
          RSUnlocked = modData.RSExoUnlocked,
          LVUnlocked = modData.LVExoUnlocked
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
  -- Extra safety checks for player
  if not player then return 0 end

  -- Convert player index to player object if needed
  if type(player) == "number" then
    player = getSpecificPlayer(player)
    if not player then return 0 end
  end

  -- Double check that we have a valid player
  if not player.getModData then return 0 end

  -- Get modData with error handling
  local status, modData = pcall(function() return player:getModData() end)
  if not status or not modData then return 0 end

  -- Initialize if it doesn't exist
  if not modData.ExoOperatorLevel then
    modData.ExoOperatorLevel = 0
  end

  return modData.ExoOperatorLevel
end

-- Function to set location-specific permissions
function PlayerTierHandler.setLocationPermission(player, location, value)
  if not player then return false end
  local modData = player:getModData()

  -- Initialize general level if it doesn't exist
  if not modData.ExoOperatorLevel then
    modData.ExoOperatorLevel = 1
  end

  -- Initialize all location permissions if they don't exist
  if not modData.MDExoUnlocked then modData.MDExoUnlocked = 0 end
  if not modData.RSExoUnlocked then modData.RSExoUnlocked = 0 end
  if not modData.LVExoUnlocked then modData.LVExoUnlocked = 0 end

  -- Set permission for the specified location
  if location == "MD" then
    modData.MDExoUnlocked = value
  elseif location == "RS" then
    modData.RSExoUnlocked = value
  elseif location == "LV" then
    modData.LVExoUnlocked = value
  else
    return false
  end

  -- Save to server-side file
  local username = player:getUsername()
  sendClientCommand("PlayerTierHandler", "saveExoOperatorLevel", {
      username = username,
      exoLevel = modData.ExoOperatorLevel,
      MDUnlocked = modData.MDExoUnlocked,
      RSUnlocked = modData.RSExoUnlocked,
      LVUnlocked = modData.LVExoUnlocked
  })

  player:Say(location .. " exoskeleton permission has been " .. (value == 1 and "granted" or "revoked"))
  return true
end

-- Function to check if player has location permission
function PlayerTierHandler.hasLocationPermission(player, location)
  if not player then return false end
  local modData = player:getModData()

  -- Initialize all location permissions if they don't exist
  if not modData.MDExoUnlocked then modData.MDExoUnlocked = 0 end
  if not modData.RSExoUnlocked then modData.RSExoUnlocked = 0 end
  if not modData.LVExoUnlocked then modData.LVExoUnlocked = 0 end

  if location == "MD" then
    return modData.MDExoUnlocked == 1
  elseif location == "RS" then
    return modData.RSExoUnlocked == 1
  elseif location == "LV" then
    return modData.LVExoUnlocked == 1
  elseif location == "Admin" then
    return player:isAccessLevel("admin")
  end

  return false
end

-- Function for admins to set location permissions
function PlayerTierHandler.adminSetLocationPermission(admin, targetPlayer, location, value)
  if not admin or not targetPlayer then return end

  if not admin:isAccessLevel("admin") then
    admin:Say("Only admins can set location permissions.")
    return false
  end

  if PlayerTierHandler.setLocationPermission(targetPlayer, location, value) then
    admin:Say("Successfully " .. (value == 1 and "granted" or "revoked") .. " " .. location .. " exoskeleton permission for " .. targetPlayer:getUsername())
    return true
  else
    admin:Say("Failed to set " .. location .. " permission for " .. targetPlayer:getUsername())
    return false
  end
end

-- Enhanced admin menu for exo operator levels and permissions
function PlayerTierHandler.addExoOperatorMenu(context, admin, targetPlayer)
  -- Create a submenu for exo operator settings
  local mainOption = context:addOption("Exo Operator Settings")
  local mainSubMenu = context:getNew(context)
  context:addSubMenu(mainOption, mainSubMenu)

  -- General level submenu
  local levelOption = mainSubMenu:addOption("Set General Level")
  local levelSubMenu = mainSubMenu:getNew(mainSubMenu)
  mainSubMenu:addSubMenu(levelOption, levelSubMenu)

  for _, level in ipairs(availableExoOperatorLevel) do
      levelSubMenu:addOption(
          "Level " .. level,
          admin,
          function()
              PlayerTierHandler.adminSetExoOperatorLevel(admin, targetPlayer, level)
          end
      )
  end

  -- Location permissions submenus
  local locations = {
    { name = "Muldraugh", code = "MD" },
    { name = "Riverside", code = "RS" },
    { name = "Louisville", code = "LV" }
  }

  for _, loc in ipairs(locations) do
    local locOption = mainSubMenu:addOption(loc.name .. " Permission")
    local locSubMenu = mainSubMenu:getNew(mainSubMenu)
    mainSubMenu:addSubMenu(locOption, locSubMenu)

    locSubMenu:addOption(
      "Grant Permission",
      admin,
      function()
        PlayerTierHandler.adminSetLocationPermission(admin, targetPlayer, loc.code, 1)
      end
    )

    locSubMenu:addOption(
      "Revoke Permission",
      admin,
      function()
        PlayerTierHandler.adminSetLocationPermission(admin, targetPlayer, loc.code, 0)
      end
    )
  end
end

function PlayerTierHandler.checkExoPermissions(player)
  if not player then return end
  local modData = player:getModData()

  -- Initialize all location permissions if they don't exist
  if not modData.MDExoUnlocked then modData.MDExoUnlocked = 0 end
  if not modData.RSExoUnlocked then modData.RSExoUnlocked = 0 end
  if not modData.LVExoUnlocked then modData.LVExoUnlocked = 0 end
  if not modData.ExoOperatorLevel then modData.ExoOperatorLevel = 1 end

  player:Say("Exo Operator Level: " .. modData.ExoOperatorLevel)
  player:Say("Muldraugh (MD) Permission: " .. (modData.MDExoUnlocked == 1 and "Granted" or "Not Granted"))
  player:Say("Riverside (RS) Permission: " .. (modData.RSExoUnlocked == 1 and "Granted" or "Not Granted"))
  player:Say("Louisville (LV) Permission: " .. (modData.LVExoUnlocked == 1 and "Granted" or "Not Granted"))
end

-- Enhanced server command handler to properly process all responses
Events.OnServerCommand.Add(function(module, command, args)
  if module == "PlayerTierHandler" then
      if command == "tierSetResponse" then
          -- Display response to admin
          local player = getPlayer()
          if player then
              player:Say(args.message)
          end
      elseif command == "tierUpdated" then
          -- Update local player data
          local player = getPlayer()
          if player then
              local modData = player:getModData()
              modData.PlayerTier = args.tier
              modData.PlayerTierValue = args.tierValue or 1
              modData.TierSetManually = true
              player:Say(args.message)
          end
      elseif command == "loadPlayerTierResponse" then
          -- Handle loaded tier data
          local player = getPlayer()
          if player and player:getUsername() == args.username and args.tier then
              local modData = player:getModData()
              modData.PlayerTier = args.tier
              modData.PlayerTierValue = args.tierValue or 1
              modData.TierSetManually = true
              player:Say("Your tier has been loaded: " .. args.tier)
          elseif player and player:getUsername() == args.username then
              player:Say("No tier data found on server.")
          end
      elseif command == "loadSurvivedHoursResponse" then
          -- Handle loaded survival hours and zombie kills
          local player = getPlayer()
          if player and player:getUsername() == args.username then
              -- Update player stats with data from server
              PlayerTierHandler.updatePlayerStats(player, args.hours, args.zombieKills)

              -- Force update tier based on new stats
              PlayerTierHandler.updatePlayerTier(player, true) -- Pass true to force update

              local survivalDays = math.floor(args.hours / 24)
              player:Say("Data loaded from server: " .. survivalDays .. " days survived and " .. args.zombieKills .. " zombie kills.")
              player:Say("Your tier is now: " .. PlayerTierHandler.getPlayerTier(player))
          end
      end
  end
end)

-- Hook into the EVERY DAY event to give XP boost based on tier and update tier based on survival days
Events.EveryHours.Add(function()
  if isServer() then return end
  local players = getOnlinePlayers()
  for i = 0, players:size() - 1 do
      local player = players:get(i)
      PlayerTierHandler.updatePlayerTier(player)
      PlayerTierHandler.giveXPBoost(player)
  end
end)

-- Hook into the context menu event for admins and players
Events.OnFillWorldObjectContextMenu.Add(PlayerTierHandler.addAdminMenu)
Events.OnFillWorldObjectContextMenu.Add(PlayerTierHandler.addPlayerTierMenu)

Events.OnCreatePlayer.Add(function(playerIndex, player)
    PlayerTierHandler.assignPlayerTier(player)
end)

return PlayerTierHandler