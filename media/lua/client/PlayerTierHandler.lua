require "PlayerConfig"
require "ISContextMenu"
require "Translate/EN/Sandbox_EN"
require "SpeedFramework"
require "PlayerTitleHandler"
require "PlayerTierPersistence"
require "ISUI/PlayerTierInfoUI"

PlayerTierHandler = {
  historyData = {}
}

local availableTiers = { "Newbies", "Adventurer", "Veteran", "Champion", "Legend", "Immortal", "Mythic", "Godlike", "Beyond Godlike" }
local availableExoOperatorLevel = {1 , 2 , 3 , 4 }
local TIER_SYNC_COOLDOWN_MS = 10000
local tierCatalog = {
  { name = "Newbies", minDays = 0, dayTarget = 0, minKills = 0, extra = "Starter tier" },
  { name = "Adventurer", minDays = 3, dayTarget = 4, minKills = 300, extra = "You getting used to Zona Merah" },
  { name = "Veteran", minDays = 5, dayTarget = 6, minKills = 1000, extra = "Auto Repair Shop Permit, ZM Virtual Garage Permit" },
  { name = "Champion", minDays = 10, dayTarget = 11, minKills = 4000, extra = "Almost There Survivor!" },
  { name = "Legend", minDays = 15, dayTarget = 16, minKills = 8000, extra = "Checkpoint Tier, Equip Legend Weapon" },
  { name = "Immortal", minDays = 15, dayTarget = 16, minKills = 30000, extra = "Add inventory capacity" },
  { name = "Mythic", minDays = 15, dayTarget = 16, minKills = 50000, extra = "Add inventory capacity" },
  { name = "Godlike", minDays = 15, dayTarget = 16, minKills = 75000, extra = "Unlimited endurance, Add inventory capacity" },
  { name = "Beyond Godlike", minDays = 15, dayTarget = 16, minKills = 200000, extra = "Top progression tier, Add inventory capacity" }
}

local function formatNumber(value)
  local numberValue = math.floor(tonumber(value) or 0)
  local sign = ""
  if numberValue < 0 then
    sign = "-"
    numberValue = math.abs(numberValue)
  end

  local result = tostring(numberValue)
  while true do
    local replaced, count = result:gsub("^(%d+)(%d%d%d)", "%1,%2")
    result = replaced
    if count == 0 then
      break
    end
  end
  return sign .. result
end

local function getTierDefinitionByName(tierName)
  for i, def in ipairs(tierCatalog) do
    if def.name == tierName then
      return def, i
    end
  end
  return tierCatalog[1], 1
end

local function getTierBenefitsText(definition)
  if not definition then
    return "No special benefit configured"
  end

  if definition.extra and definition.extra ~= "" then
    return definition.extra
  end

  return "No special benefit configured"
end

local function safeNumber(value, fallback)
  local numberValue = tonumber(value)
  if numberValue == nil then
    return fallback or 0
  end
  return numberValue
end

local function nowMs()
  if getTimestampMs then
    return safeNumber(getTimestampMs(), 0)
  end
  return 0
end

local function getHighestTierFlagValue(modData)
  if not modData then
    return 0
  end

  return math.max(
    safeNumber(modData.PlayerTierHighestFlagValue, 0),
    PlayerTierPersistence.getTierValue(modData.PlayerTierHighestFlagName)
  )
end

local function setHighestTierFlagValue(modData, tierName, tierValue)
  if not modData then
    return
  end

  local resolvedTierValue = math.max(
    safeNumber(tierValue, 0),
    PlayerTierPersistence.getTierValue(tierName)
  )
  if resolvedTierValue < 1 then
    return
  end

  local resolvedTierName = PlayerTierPersistence.getTierName(resolvedTierValue)
  modData.PlayerTierHighestFlagValue = resolvedTierValue
  modData.PlayerTierHighestFlagName = resolvedTierName
end

local function mergeHighestTierFlagValue(modData, tierName, tierValue)
  if not modData then
    return
  end

  local incomingTierValue = math.max(
    safeNumber(tierValue, 0),
    PlayerTierPersistence.getTierValue(tierName)
  )
  if incomingTierValue < 1 then
    return
  end

  if incomingTierValue > getHighestTierFlagValue(modData) then
    setHighestTierFlagValue(modData, tierName, incomingTierValue)
  end
end

local function addTierFlagOnUpgrade(player, previousTierValue, tierName, tierValue)
  if not player then
    return false
  end

  local modData = player:getModData()
  local resolvedTierValue = math.max(
    safeNumber(tierValue, 0),
    PlayerTierPersistence.getTierValue(tierName)
  )
  if resolvedTierValue < 1 then
    return false
  end

  local resolvedTierName = PlayerTierPersistence.getTierName(resolvedTierValue)
  local oldTierValue = safeNumber(previousTierValue, 0)
  local highestFlaggedTierValue = getHighestTierFlagValue(modData)

  if resolvedTierValue <= oldTierValue then
    return false
  end

  if resolvedTierValue <= highestFlaggedTierValue then
    return false
  end

  if not CharacterManager or not CharacterManager.instance or not CharacterManager.instance.addFlag then
    return false
  end

  CharacterManager.instance:addFlag(resolvedTierName)
  setHighestTierFlagValue(modData, resolvedTierName, resolvedTierValue)
  return true
end

local function getReliableTierSnapshot(player)
  local modData = player:getModData()
  local liveHours = safeNumber(player:getHoursSurvived(), 0)
  local liveKills = safeNumber(player:getZombieKills(), 0)
  local storedHours = math.max(
    safeNumber(modData.PersistentHours, 0),
    safeNumber(modData.HoursSurvived, 0)
  )
  local storedKills = math.max(
    safeNumber(modData.PersistentZombieKills, 0),
    safeNumber(modData.ZombieKills, 0)
  )

  local tierValue = math.max(
    safeNumber(modData.PlayerTierValue, 0),
    PlayerTierPersistence.getTierValue(modData.PlayerTier)
  )

  if tierValue < 1 then
    tierValue = 1
  end

  local snapshot = {
    hours = math.max(liveHours, storedHours),
    zombieKills = math.max(liveKills, storedKills),
    tierValue = tierValue,
    tier = modData.PlayerTier,
    updatedAt = nowMs()
  }

  return PlayerTierPersistence.sanitizeSnapshot(snapshot)
end

function PlayerTierHandler.getTierCatalog()
  return tierCatalog
end

function PlayerTierHandler.getTierProgressData(player)
  if not player then
    return nil
  end

  local snapshot = getReliableTierSnapshot(player)
  local currentTier = PlayerTierHandler.getPlayerTier(player)
  local currentTierValue = PlayerTierHandler.getPlayerTierValue(player)
  local currentDef, currentIndex = getTierDefinitionByName(currentTier)
  local nextDef = tierCatalog[currentIndex + 1]
  local daysSurvived = snapshot.hours / 24
  local titleValue = 0

  if PlayerTitleHandler and PlayerTitleHandler.getPlayerTitle then
    titleValue = tonumber(PlayerTitleHandler.getPlayerTitle(player)) or 0
  end

  local data = {
    username = player:getUsername(),
    currentTier = currentTier,
    currentTierValue = currentTierValue,
    currentBenefits = getTierBenefitsText(currentDef),
    hoursSurvived = math.floor(snapshot.hours),
    daysSurvived = daysSurvived,
    zombieKills = math.floor(snapshot.zombieKills),
    titleValue = titleValue,
    nextTier = nil,
    nextTierRequirement = "Max tier reached",
    nextTierBenefits = "No further tier progression",
    daysProgress = 1,
    killsProgress = 1,
    overallProgress = 1,
    daysMissing = 0,
    killsMissing = 0,
    tierRows = {}
  }

  for index, definition in ipairs(tierCatalog) do
    local requirementText
    if definition.dayTarget <= 0 and definition.minKills <= 0 then
      requirementText = "No requirement"
    else
      requirementText = ">" .. tostring(definition.minDays) .. " days and " .. formatNumber(definition.minKills) .. " kills"
    end

    data.tierRows[index] = {
      name = definition.name,
      requirement = requirementText,
      benefits = getTierBenefitsText(definition),
      isCurrent = (index == currentIndex)
    }
  end

  if nextDef then
    local dayTarget = nextDef.dayTarget
    local killTarget = nextDef.minKills
    local dayProgress = 1
    local killsProgress = 1

    if dayTarget > 0 then
      dayProgress = math.min(daysSurvived / dayTarget, 1)
    end
    if killTarget > 0 then
      killsProgress = math.min(snapshot.zombieKills / killTarget, 1)
    end

    data.nextTier = nextDef.name
    data.nextTierRequirement = "Need >" .. tostring(nextDef.minDays) .. " days and " .. formatNumber(nextDef.minKills) .. " kills"
    data.nextTierBenefits = getTierBenefitsText(nextDef)
    data.daysProgress = dayProgress
    data.killsProgress = killsProgress
    data.overallProgress = math.min(dayProgress, killsProgress)
    data.daysMissing = math.max(0, dayTarget - daysSurvived)
    data.killsMissing = math.max(0, killTarget - snapshot.zombieKills)
  end

  return data
end

function PlayerTierHandler.openTierInfoUI(player)
  if not player then
    return
  end

  PlayerTierHandler.requestTierSnapshot(player, false)
  PlayerTierHandler.requestTierInventoryBonusReapply(player)
  local progressData = PlayerTierHandler.getTierProgressData(player)

  if PlayerTierInfoUI and PlayerTierInfoUI.show then
    PlayerTierInfoUI.show(player, progressData)
  else
    player:Say("Tier UI is not available.")
  end
end

-- Utility function to update player stats and store in mod data
function PlayerTierHandler.updatePlayerStats(player, hours, kills)
  if not player then
    return
  end

  local modData = player:getModData()

  if hours ~= nil then
    local safeHours = math.max(0, math.floor(safeNumber(hours, 0)))
    player:setHoursSurvived(safeHours)
    modData.HoursSurvived = safeHours
    modData.PersistentHours = math.max(
      safeNumber(modData.PersistentHours, 0),
      safeHours
    )
  end

  if kills ~= nil then
    local safeKills = math.max(0, math.floor(safeNumber(kills, 0)))
    player:setZombieKills(safeKills)
    modData.ZombieKills = safeKills
    modData.PersistentZombieKills = math.max(
      safeNumber(modData.PersistentZombieKills, 0),
      safeKills
    )
  end
end

function PlayerTierHandler.syncTierSnapshot(player, forceSync)
  if not player or not isClient or not isClient() then
    return
  end

  local modData = player:getModData()
  local currentTime = nowMs()
  local lastSync = safeNumber(modData._lastTierSyncAt, 0)

  if not forceSync and lastSync > 0 and currentTime - lastSync < TIER_SYNC_COOLDOWN_MS then
    return
  end

  local snapshot = getReliableTierSnapshot(player)
  modData.PersistentHours = snapshot.hours
  modData.PersistentZombieKills = snapshot.zombieKills
  modData._lastTierSyncAt = currentTime

  sendClientCommand("PlayerTierHandler", "syncTierSnapshot", {
    username = player:getUsername(),
    hours = snapshot.hours,
    zombieKills = snapshot.zombieKills,
    tier = snapshot.tier,
    tierValue = snapshot.tierValue,
    updatedAt = snapshot.updatedAt
  })
end

function PlayerTierHandler.requestTierSnapshot(player, forceRequest)
  if not player or not isClient or not isClient() then
    return
  end

  local modData = player:getModData()
  local currentTime = nowMs()
  local lastRequest = safeNumber(modData._lastTierRequestAt, 0)

  if not forceRequest and lastRequest > 0 and currentTime - lastRequest < TIER_SYNC_COOLDOWN_MS then
    return
  end

  modData._lastTierRequestAt = currentTime
  sendClientCommand("PlayerTierHandler", "requestTierSnapshot", {
    username = player:getUsername()
  })
end

function PlayerTierHandler.requestTierInventoryBonusReapply(player)
  if not player or not isClient or not isClient() then
    return
  end

  sendClientCommand("PlayerTierHandler", "reapplyTierInventoryBonus", {
    username = player:getUsername()
  })
end

function PlayerTierHandler.getPlayerEquippedGloves(player)
    if not player then return nil end

    local inventory = player:getInventory()

    local equipItems = inventory:getItems()
    for i = 0, equipItems:size() - 1 do
        local item = equipItems:get(i)
        if item:isEquipped() and item:getBodyLocation() == "Hands" then
            return item
        end
    end
    player:Say("You have no equipped gloves.")
    return nil
end

function PlayerTierHandler.improveGloves(player)
    if not player then return end

    local tier = PlayerTierHandler.getPlayerTier(player)
    local gloves = PlayerTierHandler.getPlayerEquippedGloves(player)

    if not gloves then
        player:Say("You don't have gloves equipped!")
        return
    end

    local scratchDef = gloves:getScratchDefense()
    local biteDef = gloves:getBiteDefense()
    local bulletDef = gloves:getBulletDefense()
    local combatSpeedMod = gloves:getCombatSpeedModifier()

    local RandomCombatSpeedMod = ZombRand(10)
    local RandomBonus =  ZombRand(10, 30)
    print ("Random Bonus: " .. RandomBonus)

    gloves:setScratchDefense(RandomBonus)
    gloves:setBiteDefense(RandomBonus)
    gloves:setBulletDefense(RandomBonus)

    player:Say("Your gloves have been enhanced!")
end

function PlayerTierHandler.getPlayerEquippedBackpack(player)
    if not player then return nil end

    -- Get the player's inventory
    local inventory = player:getInventory()


    local equipItems = inventory:getItems()
    for i = 0, equipItems:size() - 1 do
        local item = equipItems:get(i)
        if item:isEquipped() and item:getCategory() == "Container" then
            print(item)
            return item
        end
    end
    player:Say("You have no equipped backpack.")
    return nil -- No backpack found
end

function PlayerTierHandler.recordPlayerTier(player)
  if not player then return nil end

  PlayerTierHandler.syncTierSnapshot(player, true)

  player:Say("Your tier data has been recorded on the server.")
end

function PlayerTierHandler.loadPlayerTierFromFile(player)
  if not player then return nil end

  PlayerTierHandler.requestTierSnapshot(player, true)

  player:Say("Requesting your tier data from the server...")
end

-- New function to explicitly request tier data from server
function PlayerTierHandler.loadTierFromServer(player)
  if not player then return end
  PlayerTierHandler.requestTierSnapshot(player, true)

  player:Say("Requesting your tier data from the server...")
end

function PlayerTierHandler.reassignRecordedTier(player)
  if not player then return nil end
  PlayerTierHandler.requestTierSnapshot(player, true)

  player:Say("Requesting your tier data from the server...")
end

-- Function to assign tier based on the PlayerConfig file
function PlayerTierHandler.assignPlayerTier(player)
    local modData = player:getModData() or {}
    local username = player:getUsername()

    -- Assign tier from PlayerConfig or default to Tier 1
    -- local tier = PlayerConfig[username] or availableTiers[1]
    -- local tierValue = 1
    -- modData.PlayerTier = tier
    -- modData.PlayerTierValue = tierValue
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
  return math.max(
    safeNumber(modData.PlayerTierValue, 0),
    PlayerTierPersistence.getTierValue(modData.PlayerTier)
  )
end

function PlayerTierHandler.getPlayerTier(player)
    if not player then return nil end
    local modData = player:getModData()
    local tierValue = PlayerTierHandler.getPlayerTierValue(player)
    local tierName = modData.PlayerTier
    if not tierName or tierName == "" then
      tierName = PlayerTierPersistence.getTierName(tierValue)
      modData.PlayerTier = tierName
      modData.PlayerTierValue = tierValue
    end
    return tierName
end

-- Function to display the player's tier
function PlayerTierHandler.checkPlayerTier(player)
    if not player then
      return
    end
    PlayerTierHandler.openTierInfoUI(player)
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
        -- PlayerTierHandler.addTierOptionsToMenu(subSubMenu, admin, player)
    end
end

function PlayerTierHandler.updateTierAndGiveXPBoost(player)
  if not player then return end
  -- player:Say("Updating your tier and applying XP boost if eligible...")
  local tierUpdated = PlayerTierHandler.updatePlayerTier(player)
  PlayerTierHandler.giveXPBoost(player)
  PlayerTierHandler.requestTierInventoryBonusReapply(player)
  if tierUpdated then
    PlayerTierHandler.syncTierSnapshot(player, true)
  end

  local tier = PlayerTierHandler.getPlayerTier(player)

  if tier == "Godlike" then
    player:setUnlimitedEndurance(true)
    player:Say("You are already at the godlike tier: " .. tier)
  end

  sendClientCommand("PlayerTierHandler", "setUnlimitedEnduranceAndTrait", { username = player:getUsername() })
end

-- Function to add "Check My Tier" option to the player's context menu
function PlayerTierHandler.addPlayerTierMenu(playerIndex, context)
  local player = getSpecificPlayer(playerIndex)
  if not player then return end

    -- Check if player has title level >= 1
  local playerTitle = tonumber(PlayerTitleHandler.getPlayerTitle(player)) or 0
  if not playerTitle or playerTitle < 1 then
    context:addOption("Check My Tier", player, PlayerTierHandler.openTierInfoUI, player)
    context:addOption("Update My Tier and Get Boost", player, PlayerTierHandler.updateTierAndGiveXPBoost, player)
  else
    context:addOption("Check My Tier", player, PlayerTierHandler.openTierInfoUI, player)
    context:addOption("Update My Tier and Get Boost", player, PlayerTierHandler.updateTierAndGiveXPBoost, player)
    -- context:addOption("VIP: (DANGER!) Update My Tier To Minimum VIP Min Tier", player, PlayerTierHandler.loadTierFromServer, player)
  end

  -- Add admin-only options
  if player:isAccessLevel("admin") then
    context:addOption("Admin: Test Book Bonus (Mechanics)", player, function() PlayerTierHandler.testBookBonus("Mechanics") end)
  end
end

function PlayerTierHandler.giveXPBoost(player)
  if not player then return end

  local tier = PlayerTierHandler.getPlayerTier(player)
  local tierValue = player:getModData().PlayerTierValue or 1
  local bonusMultiplier = 0
  local xpMultiplier = 1.0
  local message = ""

  -- Define tier-based XP multipliers
  if tier == "Newbies" then
      bonusMultiplier = 1.01 -- 1% speed boost
      xpMultiplier = 1.1 -- 10% XP boost
      message = "Newbie Bonus Applied (+1% Speed, +10% XP)"
  elseif tier == "Adventurer" then
      bonusMultiplier = 1.04 -- 4% speed boost
      xpMultiplier = 1.15 -- 15% XP boost
      message = "Adventurer Bonus Applied (+4% Speed, +15% XP)"
  elseif tier == "Veteran" then
      bonusMultiplier = 1.09 -- 9% speed boost
      xpMultiplier = 1.25 -- 25% XP boost
      message = "Veteran Bonus Applied (+9% Speed, +25% XP)"
  elseif tier == "Champion" then
      bonusMultiplier = 1.13 -- 13% speed boost
      xpMultiplier = 1.35 -- 35% XP boost
      message = "Champion Bonus Applied (+13% Speed, +35% XP)"
  elseif tier == "Legend" then
      bonusMultiplier = 1.17 -- 17% speed boost
      xpMultiplier = 1.45 -- 45% XP boost
      message = "Legend Bonus Applied (+17% Speed, +45% XP)"
  elseif tier == "Immortal" then
      bonusMultiplier = 1.21 -- 21% speed boost
      xpMultiplier = 1.55 -- 55% XP boost
      message = "Immortal Bonus Applied (+21% Speed, +55% XP)"
  elseif tier == "Mythic" then
      bonusMultiplier = 1.26 -- 26% speed boost
      xpMultiplier = 1.65 -- 65% XP boost
      message = "Mythic Bonus Applied (+26% Speed, +65% XP)"
  elseif tier == "Godlike" then
      bonusMultiplier = 1.3 -- 30% speed boost
      xpMultiplier = 1.75 -- 75% XP boost
      message = "Godlike Bonus Applied (+30% Speed, +75% XP)"
  elseif tier == "Beyond Godlike" then
      bonusMultiplier = 1.5
      xpMultiplier = 2
      message = "Beyond Godlike Bonus Applied (+50% Speed, +100% XP)"
  end

end

function PlayerTierHandler.updatePlayerTier(player, forceUpdate)
  if not player then
    return false
  end

  local modData = player:getModData()
  local snapshot = getReliableTierSnapshot(player)
  local survivalDays = snapshot.hours / 24
  local zombieKills = snapshot.zombieKills

  if snapshot.hours > safeNumber(player:getHoursSurvived(), 0) or
     snapshot.zombieKills > safeNumber(player:getZombieKills(), 0) then
    PlayerTierHandler.updatePlayerStats(player, snapshot.hours, snapshot.zombieKills)
  end

  local playerTitle = 0
  if isClient and isClient() and PlayerTitleHandler and PlayerTitleHandler.getPlayerTitle then
    playerTitle = tonumber(PlayerTitleHandler.getPlayerTitle(player)) or 0
  end

  local statsChanged = false

  if playerTitle == 1 then
    local minDays = 15
    local minKills = 4001

    if survivalDays < minDays then
      local minHours = minDays * 24
      PlayerTierHandler.updatePlayerStats(player, minHours, nil)
      survivalDays = minDays
      statsChanged = true
    end

    if zombieKills < minKills then
      PlayerTierHandler.updatePlayerStats(player, nil, minKills)
      zombieKills = minKills
      statsChanged = true
    end

    if statsChanged then
      player:Say("Your stats have been boosted to match your VIP status!")
    end
  end

  if playerTitle >= 2 then
    local minDays = 16
    local minKills = 8001

    if survivalDays < minDays then
      local minHours = minDays * 24
      PlayerTierHandler.updatePlayerStats(player, minHours, nil)
      survivalDays = minDays
      statsChanged = true
    end

    if zombieKills < minKills then
      PlayerTierHandler.updatePlayerStats(player, nil, minKills)
      zombieKills = minKills
      statsChanged = true
    end

    if statsChanged then
      player:Say("Your stats have been boosted to match your VVIP/MVP status!")
    end
  end

  local newTier = "Newbies"
  local newTierValue = 1

  if survivalDays > 3 and zombieKills >= 300 then
    newTier = "Adventurer"
    newTierValue = 2
  end
  if survivalDays > 5 and zombieKills >= 1000 then
    newTier = "Veteran"
    newTierValue = 3
  end
  if survivalDays > 10 and zombieKills >= 4000 then
    newTier = "Champion"
    newTierValue = 4
  end
  if survivalDays > 15 and zombieKills >= 8000 then
    newTier = "Legend"
    newTierValue = 5
  end
  if survivalDays > 15 and zombieKills >= 30000 then
    newTier = "Immortal"
    newTierValue = 6
  end
  if survivalDays > 15 and zombieKills >= 50000 then
    newTier = "Mythic"
    newTierValue = 7
  end
  if survivalDays > 15 and zombieKills >= 75000 then
    newTier = "Godlike"
    newTierValue = 8
  end
  if survivalDays > 15 and zombieKills >= 200000 then
    newTier = "Beyond Godlike"
    newTierValue = 9

    if ZMEquipmentHandler and ZMEquipmentHandler.setRestrictedGearAllow and getPlayer() then
      ZMEquipmentHandler.setRestrictedGearAllow(getPlayer():getUsername(), "Base.BF2042Antivirus", true)
    end
  end

  if playerTitle == 1 and newTierValue < 4 then
    newTier = "Champion"
    newTierValue = 4
  end

  if playerTitle >= 2 and newTierValue < 5 then
    newTier = "Legend"
    newTierValue = 5
  end

  local currentTierValue = PlayerTierHandler.getPlayerTierValue(player)
  if not forceUpdate and newTierValue < currentTierValue then
    newTierValue = currentTierValue
    newTier = PlayerTierPersistence.getTierName(newTierValue)
  end

  local currentTier = modData.PlayerTier or PlayerTierPersistence.getTierName(currentTierValue)

  local mergedHours = math.max(
    safeNumber(modData.PersistentHours, 0),
    safeNumber(modData.HoursSurvived, 0),
    math.floor(survivalDays * 24)
  )
  local mergedKills = math.max(
    safeNumber(modData.PersistentZombieKills, 0),
    safeNumber(modData.ZombieKills, 0),
    math.floor(zombieKills)
  )

  modData.PersistentHours = mergedHours
  modData.PersistentZombieKills = mergedKills

  if currentTier ~= newTier or currentTierValue ~= newTierValue or statsChanged or forceUpdate == true then
    modData.PlayerTier = newTier
    modData.PlayerTierValue = newTierValue
    addTierFlagOnUpgrade(player, currentTierValue, newTier, newTierValue)

    if (playerTitle == 1 and newTierValue == 4 and survivalDays <= 20) or
       (playerTitle >= 2 and newTierValue == 5 and survivalDays <= 30) then
      player:Say("Your tier was boosted due to your Supporter status!")
    end

    return true
  end

  return false
end

function PlayerTierHandler.giveBookXPBoost(player, skillName)
    if not player then
        print("Error: Player is nil")
        return false
    end

    local skillToBook = {
        ["Mechanics"] = { perk = Perks.Mechanics, maxMultiplier = 3 },
        ["Electricity"] = { perk = Perks.Electrical, maxMultiplier = 3 },
        ["Carpentry"] = { perk = Perks.Woodwork, maxMultiplier = 3 },
        ["Cooking"] = { perk = Perks.Cooking, maxMultiplier = 3 },
        ["Farming"] = { perk = Perks.Farming, maxMultiplier = 3 },
        ["FirstAid"] = { perk = Perks.Doctor, maxMultiplier = 3 },
        ["Tailoring"] = { perk = Perks.Tailoring, maxMultiplier = 3 },
        ["MetalWelding"] = { perk = Perks.MetalWelding, maxMultiplier = 3 },
        ["Blacksmith"] = { perk = Perks.Blacksmith, maxMultiplier = 3 },
        ["Foraging"] = { perk = Perks.PlantScavenging, maxMultiplier = 3 }
    }

    local bookData = skillToBook[skillName]
    if not bookData then
        print("Error: Unknown skill name. Available skills: Mechanics, Electronics, Carpentry, Cooking, Farming, FirstAid, Tailoring, MetalWelding, Blacksmith, Foraging")
        return false
    end

    local currentLevel = player:getPerkLevel(bookData.perk)

    local bookLevel = 1
    if currentLevel >= 8 then
        bookLevel = 9
    elseif currentLevel >= 6 then
        bookLevel = 7
    elseif currentLevel >= 4 then
        bookLevel = 5
    elseif currentLevel >= 2 then
        bookLevel = 3
    end

    local multiplier = bookData.maxMultiplier
    local maxLevel = bookLevel + 2

    player:getXp():addXpMultiplier(bookData.perk, multiplier, bookLevel, maxLevel)

    local tier = PlayerTierHandler.getPlayerTier(player)
    local tierMultiplier = 1.0

    if tier == "Newbies" then
        tierMultiplier = 1.1
    elseif tier == "Adventurer" then
        tierMultiplier = 1.15
    elseif tier == "Veteran" then
        tierMultiplier = 1.25
    elseif tier == "Champion" then
        tierMultiplier = 1.35
    elseif tier == "Legend" then
        tierMultiplier = 1.45
    elseif tier == "Immortal" then
        tierMultiplier = 1.55
    elseif tier == "Mythic" then
        tierMultiplier = 1.65
    elseif tier == "Godlike" then
        tierMultiplier = 1.75
    end

    if tierMultiplier > 1.0 then
        local bonusXP = (tierMultiplier - 1.0) * 10
        player:getXp():AddXP(bookData.perk, bonusXP)
    end

    player:Say("XP bonus applied for " .. skillName .. "! (Level " .. bookLevel .. " book, Tier: " .. tier .. ")")
    print("Applied " .. skillName .. " book boost to " .. player:getUsername() .. " (Multiplier: " .. multiplier .. ", Tier bonus: " .. tierMultiplier .. ")")
    return true
end

function PlayerTierHandler.consoleGiveBookBoost(skillName)
    local player = getPlayer()
    if not player then
        print("Error: No player found")
        return
    end
    return PlayerTierHandler.giveBookXPBoost(player, skillName)
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
local function applyServerTierSnapshot(player, args, showMessage)
  if not player or not args then
    return
  end

  if args.username and player:getUsername() ~= args.username then
    return
  end

  local modData = player:getModData()
  local serverSnapshot = PlayerTierPersistence.sanitizeSnapshot({
    hours = args.hours,
    zombieKills = args.zombieKills,
    tier = args.tier,
    tierValue = args.tierValue,
    updatedAt = args.updatedAt
  })
  local mergedSnapshot = PlayerTierPersistence.mergeSnapshots(
    getReliableTierSnapshot(player),
    serverSnapshot
  )

  PlayerTierHandler.updatePlayerStats(player, mergedSnapshot.hours, mergedSnapshot.zombieKills)
  modData.PersistentHours = mergedSnapshot.hours
  modData.PersistentZombieKills = mergedSnapshot.zombieKills

  local currentTierValue = PlayerTierHandler.getPlayerTierValue(player)
  if mergedSnapshot.tierValue > currentTierValue then
    modData.PlayerTier = mergedSnapshot.tier
    modData.PlayerTierValue = mergedSnapshot.tierValue
    addTierFlagOnUpgrade(player, currentTierValue, mergedSnapshot.tier, mergedSnapshot.tierValue)
  end

  mergeHighestTierFlagValue(modData, args.highestTierFlagName, args.highestTierFlagValue)

  local tierWasUpdated = PlayerTierHandler.updatePlayerTier(player, false)
  PlayerTierHandler.giveXPBoost(player)
  if tierWasUpdated then
    PlayerTierHandler.syncTierSnapshot(player, true)
  end

  if showMessage then
    local survivalDays = math.floor(mergedSnapshot.hours / 24)
    player:Say(
      "Tier data synced: " .. survivalDays .. " days survived and " ..
      mergedSnapshot.zombieKills .. " zombie kills."
    )
  end

  if PlayerTierInfoUI and PlayerTierInfoUI.instance and PlayerTierInfoUI.instance.refreshData then
    PlayerTierInfoUI.instance:refreshData()
  end
end

Events.OnServerCommand.Add(function(module, command, args)
  if module ~= "PlayerTierHandler" then
    return
  end

  local player = getPlayer()
  if not player then
    return
  end

  if command == "tierSetResponse" then
    player:Say(args.message)
  elseif command == "tierUpdated" then
    local modData = player:getModData()
    local previousTierValue = PlayerTierHandler.getPlayerTierValue(player)
    modData.PlayerTier = args.tier
    modData.PlayerTierValue = safeNumber(args.tierValue, 1)
    addTierFlagOnUpgrade(player, previousTierValue, args.tier, args.tierValue)
    mergeHighestTierFlagValue(modData, args.highestTierFlagName, args.highestTierFlagValue)
    modData.TierSetManually = true
    player:Say(args.message)
    PlayerTierHandler.syncTierSnapshot(player, true)
  elseif command == "loadPlayerTierResponse" then
    applyServerTierSnapshot(player, args, true)
  elseif command == "loadSurvivedHoursResponse" then
    applyServerTierSnapshot(player, args, true)
  elseif command == "tierSnapshotResponse" then
    applyServerTierSnapshot(player, args, false)
  elseif command == "saveSurvivedHoursResponse" then
    applyServerTierSnapshot(player, args, false)
  end
end)

-- Hook into the EVERY DAY event to give XP boost based on tier and update tier based on survival days
Events.EveryHours.Add(function()
  if isServer and isServer() then
    return
  end

  local player = getPlayer()
  if not player then
    return
  end

  local wasUpdated = PlayerTierHandler.updatePlayerTier(player)
  PlayerTierHandler.giveXPBoost(player)
  PlayerTierHandler.syncTierSnapshot(player, wasUpdated)
end)

-- Hook into the context menu event for admins and players
Events.OnFillWorldObjectContextMenu.Add(PlayerTierHandler.addAdminMenu)
Events.OnFillWorldObjectContextMenu.Add(PlayerTierHandler.addPlayerTierMenu)

Events.EveryTenMinutes.Add(function()
  if not isClient or not isClient() then
    return
  end

  local player = getPlayer()
  if player then
    PlayerTierHandler.syncTierSnapshot(player, false)
  end
end)

Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
  local player = playerObj or getSpecificPlayer(playerIndex) or getPlayer()
  if not player then
    return
  end

  if PlayerTitleHandler and PlayerTitleHandler.requestPlayerTitle then
    PlayerTitleHandler.requestPlayerTitle(player, true)
  end

  PlayerTierHandler.requestTierSnapshot(player, true)
  PlayerTierHandler.syncTierSnapshot(player, true)
end)

-- Function to test book XP bonus (for console use)
function PlayerTierHandler.testBookBonus(skillName)
  local player = getPlayer()
  if not player then
    print("No player found")
    return
  end

  return PlayerTierHandler.giveBookXPBoost(player, skillName or "Mechanics")
end

-- Function to check active book bonuses
function PlayerTierHandler.checkActiveBookBonuses()
  local player = getPlayer()
  if not player then
    print("No player found")
    return
  end

  local modData = player:getModData()
  if not modData.BookBonuses then
    player:Say("No active book bonuses")
    return
  end

  local currentTime = getGameTime():getWorldAgeHours() * 60
  local count = 0

  for perkStr, bonus in pairs(modData.BookBonuses) do
    if bonus.expiry and currentTime <= bonus.expiry then
      local timeLeft = math.floor((bonus.expiry - currentTime) / 60)
      player:Say("Active: " .. bonus.bookName .. " (+" .. math.floor((bonus.multiplier - 1) * 100) .. "% XP, " .. timeLeft .. "h left)")
      count = count + 1
    end
  end

  if count == 0 then
    player:Say("No active book bonuses")
  end
end

return PlayerTierHandler
