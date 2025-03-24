require "PlayerTierHandler"

local restrictExoSkeleton = 1
local minExoOperatorLevel = 2 -- Minimum level required to use basic exoskeletons

local exoNames = {
  "exoskeleton",
  "Exoskeleton",
  "Exoskeleton mk1", -- Note: fixed comma here that was missing in your code
  -- Add other exoskeleton variants here
}

-- Map of exoskeleton types to required operator levels
local exoRequirements = {
  ["exoskeleton"] = 2,
  ["Exoskeleton"] = 2,
  ["Exoskeleton mk1"] = 2,
  ["Exoskeleton mk2"] = 3,
  ["Exoskeleton mk3"] = 4,
  -- Add other variants with their required levels
}

-- Check if player can use a specific exoskeleton
function canUseExo(player, exoName)
  local playerLevel = PlayerTierHandler.getExoOperatorLevel(player)
  local requiredLevel = exoRequirements[exoName] or minExoOperatorLevel

  return playerLevel >= requiredLevel
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
          if not canUseExo(player, item:getDisplayName()) then
            -- Remove the item and place back in inventory
            player:removeWornItem(item)
            inventory:AddItem(item)
            player:Say("You need to be Exo Operator Level " ..
              (exoRequirements[item:getDisplayName()] or minExoOperatorLevel) ..
              " to use this exoskeleton.")
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
        if not canUseExo(player, item:getDisplayName()) then
          context:removeLastOption() -- Remove the "Wear" option
          -- Add a grayed-out option explaining why
          local option = context:addOption(getText("ContextMenu_Wear"), nil)
          option.notAvailable = true
          local tooltip = ISInventoryPaneContextMenu.addToolTip()
          tooltip:setName("Requires Exo Operator Level")
          tooltip.description = "You need to be Exo Operator Level " ..
            (exoRequirements[item:getDisplayName()] or minExoOperatorLevel) ..
            " to use this exoskeleton."
          option.toolTip = tooltip
          break
        end
      end
    end
  end
end)

return ZMEquipmentHandler