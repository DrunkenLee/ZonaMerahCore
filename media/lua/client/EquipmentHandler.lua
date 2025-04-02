require "PlayerTierHandler"

local restrictExoSkeleton = 1
local minExoOperatorLevel = 1 -- Minimum level required for general exoskeletons

-- Location unlocks flags (to be set by other parts of the code)
local MDExoUnlocked = 0 -- Muldraugh exoskeleton unlock status
local RSExoUnlocked = 0 -- Riverside exoskeleton unlock status
local LVExoUnlocked = 0 -- Louisville exoskeleton unlock status

local exoNames = {
    "exoskeleton",
    "Exoskeleton",
    "Exoskeletonmk1",
    "ExoskeletonCS",
    "ExoskeletonBandits",
    "ExoskeletonBanditsMk1",
    "ExoskeletonBanditsMk2",
    "ExoskeletonBanditsMk21",
    "ExoskeletonCSMk1",
    "ExoskeletonCSMk2",
    "ExoskeletonCSMk21",
    "ExoskeletonDuty",
    "ExoskeletonDutyMk1",
    "ExoskeletonDutyMk2",
    "ExoskeletonDutyMk21",
    "ExoskeletonEcologists",
    "ExoskeletonEcologistsMk1",
    "ExoskeletonEcologistsMk2",
    "ExoskeletonEcologistsMk21",
    "ExoskeletonFreedom",
    "ExoskeletonFreedomMk1",
    "ExoskeletonFreedomMk2",
    "ExoskeletonFreedomMk21",
    "ExoskeletonMercs",
    "ExoskeletonMercsMk1",
    "ExoskeletonMercsMk2",
    "ExoskeletonMercsMk21",
    "ExoskeletonMilitary",
    "ExoskeletonMilitaryMk1",
    "ExoskeletonMilitaryMk2",
    "ExoskeletonMilitaryMk21",
    "ExoskeletonMonolith",
    "ExoskeletonMonolithMk1",
    "ExoskeletonMonolithMk2",
    "ExoskeletonMonolithMk21",
    "ExoskeletonLoner",
    "ExoskeletonLonerMk1",
    "ExoskeletonLonerMk2",
    "ExoskeletonLonerMk21",
    -- Location-specific exoskeletons
    "ExoskeletonMDT1", -- Muldraugh T1
    "ExoskeletonRST1", -- Riverside T1
    "ExoskeletonLVT1", -- Louisville T1
    "ExoskeletonAdmin", -- Admin exoskeleton
    -- Add other exoskeleton variants here
}

-- Map of exoskeleton types to required operator levels
local exoRequirements = {
  -- Basic exoskeletons
  ["exoskeleton"] = 1,
  ["Exoskeleton"] = 1,
  ["Exoskeletonmk1"] = 1,
  ["Exoskeleton mk1"] = 1,
  ["Exoskeleton mk2"] = 1,
  ["Exoskeleton mk3"] = 1,

  -- Faction exoskeletons (all require general level 1)
  ["ExoskeletonCS"] = 1,
  ["ExoskeletonBandits"] = 1,
  ["ExoskeletonBanditsMk1"] = 1,
  ["ExoskeletonBanditsMk2"] = 1,
  ["ExoskeletonBanditsMk21"] = 1,
  ["ExoskeletonCSMk1"] = 1,
  ["ExoskeletonCSMk2"] = 1,
  ["ExoskeletonCSMk21"] = 1,
  ["ExoskeletonDuty"] = 1,
  ["ExoskeletonDutyMk1"] = 1,
  ["ExoskeletonDutyMk2"] = 1,
  ["ExoskeletonDutyMk21"] = 1,
  ["ExoskeletonEcologists"] = 1,
  ["ExoskeletonEcologistsMk1"] = 1,
  ["ExoskeletonEcologistsMk2"] = 1,
  ["ExoskeletonEcologistsMk21"] = 1,
  ["ExoskeletonFreedom"] = 1,
  ["ExoskeletonFreedomMk1"] = 1,
  ["ExoskeletonFreedomMk2"] = 1,
  ["ExoskeletonFreedomMk21"] = 1,
  ["ExoskeletonMercs"] = 1,
  ["ExoskeletonMercsMk1"] = 1,
  ["ExoskeletonMercsMk2"] = 1,
  ["ExoskeletonMercsMk21"] = 1,
  ["ExoskeletonMilitary"] = 1,
  ["ExoskeletonMilitaryMk1"] = 1,
  ["ExoskeletonMilitaryMk2"] = 1,
  ["ExoskeletonMilitaryMk21"] = 1,
  ["ExoskeletonMonolith"] = 1,
  ["ExoskeletonMonolithMk1"] = 1,
  ["ExoskeletonMonolithMk2"] = 1,
  ["ExoskeletonMonolithMk21"] = 1,
  ["ExoskeletonLoner"] = 1,
  ["ExoskeletonLonerMk1"] = 1,
  ["ExoskeletonLonerMk2"] = 1,
  ["ExoskeletonLonerMk21"] = 1,

  -- Location-specific exoskeletons with their tiers
  ["ExoskeletonMDT1"] = 2, -- Novice Muldraugh Exo-Operator (T2MD)
  ["ExoskeletonRST1"] = 2, -- Novice Riverside Exo-Operator (T2RS)
  ["ExoskeletonLVT1"] = 2, -- Novice Louisville Exo-Operator (T2LV)
  ["ExoskeletonAdmin"] = 4, -- Admin Exo-Operator (T4)
}

-- Location requirements for exoskeletons
local locationExoTypes = {
  ["ExoskeletonMDT1"] = "MD", -- Muldraugh exoskeleton
  ["ExoskeletonRST1"] = "RS", -- Riverside exoskeleton
  ["ExoskeletonLVT1"] = "LV", -- Louisville exoskeleton
  ["ExoskeletonAdmin"] = "Admin", -- Admin exoskeleton
}

-- Function to check if player has the location-specific unlock
function hasLocationUnlock(player, locationType)
  if locationType == "MD" then
    return MDExoUnlocked == 1
  elseif locationType == "RS" then
    return RSExoUnlocked == 1
  elseif locationType == "LV" then
    return LVExoUnlocked == 1
  elseif locationType == "Admin" then
    return PlayerTierHandler.isAdmin(player) -- Assuming there's an admin check function
  end
  return false
end

-- Check if player can use a specific exoskeleton
function canUseExo(player, exoName)
  local playerLevel = PlayerTierHandler.getExoOperatorLevel(player)
  local requiredLevel = exoRequirements[exoName] or minExoOperatorLevel

  -- First check general level requirement
  if playerLevel < requiredLevel then
    return false, "level", requiredLevel
  end

  -- Then check location-specific permission if applicable
  local locationType = locationExoTypes[exoName]
  if locationType then
    if not hasLocationUnlock(player, locationType) then
      return false, "location", locationType
    end
  end

  return true
end

-- Function to set location unlock status (to be called from elsewhere in your code)
function setLocationUnlock(locationType, value)
  if locationType == "MD" then
    MDExoUnlocked = value
  elseif locationType == "RS" then
    RSExoUnlocked = value
  elseif locationType == "LV" then
    LVExoUnlocked = value
  end
end

-- This function runs when clothing changes
function onClothingUpdated(player)
  if not restrictExoSkeleton then return end

  -- Check all equipped items
  local inventory = player:getInventory()
  local wornItems = player:getWornItems()

  for i=0, wornItems:size()-1 do
    local item = wornItems:getItemByIndex(i)
    if item then
      for _, exoName in ipairs(exoNames) do
        if item:getDisplayName() and string.find(item:getDisplayName(), exoName) then
          -- Found an exoskeleton, check if player is allowed to use it
          local canUse, reason, requirement = canUseExo(player, item:getDisplayName())
          if not canUse then
            -- Remove the item and place back in inventory
            player:removeWornItem(item)
            inventory:AddItem(item)

            -- Show appropriate message based on reason
            if reason == "level" then
              player:Say("You need to be Exo Operator Level " .. requirement .. " to use this exoskeleton.")
            elseif reason == "location" then
              local locationName = ""
              if requirement == "MD" then locationName = "Muldraugh"
              elseif requirement == "RS" then locationName = "Riverside"
              elseif requirement == "LV" then locationName = "Louisville"
              elseif requirement == "Admin" then locationName = "Admin"
              end
              player:Say("You don't have permission to use " .. locationName .. " exoskeletons.")
            end
            break
          end
        end
      end
    end
  end
end

-- Hook into the clothing updated event
Events.OnClothingUpdated.Add(onClothingUpdated)

-- Hook into wear context menu event
Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items)
  for i,v in ipairs(items) do
    local item = v
    -- Handle the case where we're given an inventory item
    if instanceof(v, "InventoryItem") then
      item = v
    else
      item = v.items[1]
    end

    -- Check if this is an exoskeleton
    for _, exoName in ipairs(exoNames) do
      if item:getDisplayName() and string.find(item:getDisplayName(), exoName) then
        -- Found an exoskeleton, check if player can use it
        local canUse, reason, requirement = canUseExo(player, item:getDisplayName())
        if not canUse then
          context:removeLastOption() -- Remove the "Wear" option
          -- Add a grayed-out option explaining why
          local option = context:addOption(getText("ContextMenu_Wear"), nil)
          option.notAvailable = true
          local tooltip = ISInventoryPaneContextMenu.addToolTip()

          if reason == "level" then
            tooltip:setName("Requires Exo Operator Level")
            tooltip.description = "You need to be Exo Operator Level " .. requirement .. " to use this exoskeleton."
          elseif reason == "location" then
            local locationName = ""
            if requirement == "MD" then locationName = "Muldraugh"
            elseif requirement == "RS" then locationName = "Riverside"
            elseif requirement == "LV" then locationName = "Louisville"
            elseif requirement == "Admin" then locationName = "Admin"
            end
            tooltip:setName("Location Restricted Exoskeleton")
            tooltip.description = "You need to unlock " .. locationName .. " exoskeleton privileges."
          end

          option.toolTip = tooltip
          break
        end
      end
    end
  end
end)

-- Export functions for use in other scripts
local ZMEquipmentHandler = {}
ZMEquipmentHandler.setLocationUnlock = setLocationUnlock
ZMEquipmentHandler.canUseExo = canUseExo

return ZMEquipmentHandler