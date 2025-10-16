require "PlayerTierHandler"

-- Initialize the module
ZMEquipmentHandler = {}

-- Configuration
ZMEquipmentHandler.restrictExoSkeleton = true
ZMEquipmentHandler.minExoOperatorLevel = 1

-- List of item types for exoskeletons
ZMEquipmentHandler.exoTypes = {
    "Base.Exoskeleton",
    "Base.ExoskeletonMk1",
    "Base.ExoskeletonCS",
    "Base.ExoskeletonBandits",
    "Base.ExoskeletonBanditsMk1",
    "Base.ExoskeletonBanditsMk2",
    "Base.ExoskeletonBanditsMk21",
    "Base.ExoskeletonCSMk1",
    "Base.ExoskeletonCSMk2",
    "Base.ExoskeletonCSMk21",
    "Base.ExoskeletonDuty",
    "Base.ExoskeletonDutyMk1",
    "Base.ExoskeletonDutyMk2",
    "Base.ExoskeletonDutyMk21",
    "Base.ExoskeletonEcologists",
    "Base.ExoskeletonEcologistsMk1",
    "Base.ExoskeletonEcologistsMk2",
    "Base.ExoskeletonEcologistsMk21",
    "Base.ExoskeletonFreedom",
    "Base.ExoskeletonFreedomMk1",
    "Base.ExoskeletonFreedomMk2",
    "Base.ExoskeletonFreedomMk21",
    "Base.ExoskeletonMercs",
    "Base.ExoskeletonMercsMk1",
    "Base.ExoskeletonMercsMk2",
    "Base.ExoskeletonMercsMk21",
    "Base.ExoskeletonMilitary",
    "Base.ExoskeletonMilitaryMk1",
    "Base.ExoskeletonMilitaryMk2",
    "Base.ExoskeletonMilitaryMk21",
    "Base.ExoskeletonMonolith",
    "Base.ExoskeletonMonolithMk1",
    "Base.ExoskeletonMonolithMk2",
    "Base.ExoskeletonMonolithMk21",
    "Base.ExoskeletonLoner",
    "Base.ExoskeletonLonerMk1",
    "Base.ExoskeletonLonerMk2",
    "Base.ExoskeletonLonerMk21",
    "Base.ExoskeletonMDT1A",
    "Base.ExoskeletonMDT1B",
    "Base.ExoskeletonMDT1C",
    "Base.ExoskeletonRST1A",
    "Base.ExoskeletonRST1B",
    "Base.ExoskeletonRST1C",
    "Base.ExoskeletonLVT1A",
    "Base.ExoskeletonLVT1B",
    "Base.ExoskeletonLVT1C",
    "Base.ExoskeletonAdmin"
}

-- Map of exoskeleton item types to required operator levels
ZMEquipmentHandler.exoRequirements = {
    -- Basic exoskeletons
    ["Base.Exoskeleton"] = 1,
    ["Base.ExoskeletonMk1"] = 1,
    ["Base.ExoskeletonMk2"] = 1,
    ["Base.ExoskeletonMk3"] = 1,

    -- Faction exoskeletons
    ["Base.ExoskeletonCS"] = 1,
    ["Base.ExoskeletonBandits"] = 1,
    ["Base.ExoskeletonBanditsMk1"] = 2,
    ["Base.ExoskeletonBanditsMk2"] = 3,
    ["Base.ExoskeletonBanditsMk21"] = 4,
    ["Base.ExoskeletonCSMk1"] = 2,
    ["Base.ExoskeletonCSMk2"] = 3,
    ["Base.ExoskeletonCSMk21"] = 4,
    ["Base.ExoskeletonDuty"] = 1,
    ["Base.ExoskeletonDutyMk1"] = 2,
    ["Base.ExoskeletonDutyMk2"] = 3,
    ["Base.ExoskeletonDutyMk21"] = 4,
    ["Base.ExoskeletonEcologists"] = 1,
    ["Base.ExoskeletonEcologistsMk1"] = 2,
    ["Base.ExoskeletonEcologistsMk2"] = 3,
    ["Base.ExoskeletonEcologistsMk21"] = 4,
    ["Base.ExoskeletonFreedom"] = 1,
    ["Base.ExoskeletonFreedomMk1"] = 1,
    ["Base.ExoskeletonFreedomMk2"] = 2,
    ["Base.ExoskeletonFreedomMk21"] = 3,
    ["Base.ExoskeletonMercs"] = 1,
    ["Base.ExoskeletonMercsMk1"] = 2,
    ["Base.ExoskeletonMercsMk2"] = 3,
    ["Base.ExoskeletonMercsMk21"] = 4,
    ["Base.ExoskeletonMilitary"] = 1,
    ["Base.ExoskeletonMilitaryMk1"] = 1,
    ["Base.ExoskeletonMilitaryMk2"] = 1,
    ["Base.ExoskeletonMilitaryMk21"] = 1,
    ["Base.ExoskeletonMonolith"] = 1,
    ["Base.ExoskeletonMonolithMk1"] = 1,
    ["Base.ExoskeletonMonolithMk2"] = 1,
    ["Base.ExoskeletonMonolithMk21"] = 1,
    ["Base.ExoskeletonLoner"] = 1,
    ["Base.ExoskeletonLonerMk1"] = 2,
    ["Base.ExoskeletonLonerMk2"] = 3,
    ["Base.ExoskeletonLonerMk21"] = 4,

    -- Location-specific exoskeletons
    ["Base.ExoskeletonMDT1A"] = 2, -- Muldraugh Exo (Level 2)
    ["Base.ExoskeletonMDT1B"] = 2, -- Muldraugh Exo (Level 2)
    ["Base.ExoskeletonMDT1C"] = 2, -- Muldraugh Exo (Level 2)
    ["Base.ExoskeletonRST1A"] = 2, -- Riverside Exo (Level 2)
    ["Base.ExoskeletonRST1B"] = 2, -- Riverside Exo (Level 2)
    ["Base.ExoskeletonRST1sC"] = 2, -- Riverside Exo (Level 2)
    ["Base.ExoskeletonLVT1A"] = 2, -- Louisville Exo (Level 2)
    ["Base.ExoskeletonLVT1B"] = 2, -- Louisville Exo (Level 2)
    ["Base.ExoskeletonLVT1C"] = 2, -- Louisville Exo (Level 2)
    ["Base.ExoskeletonAdmin"] = 4  -- Admin Exo (Level 4)
}

-- Location requirements for exoskeletons
ZMEquipmentHandler.locationExoTypes = {
    ["Base.ExoskeletonMDT1A"] = "MD", -- Muldraugh exoskeleton
    ["Base.ExoskeletonMDT1B"] = "MD", -- Muldraugh exoskeleton
    ["Base.ExoskeletonMDT1C"] = "MD", -- Muldraugh exoskeleton
    ["Base.ExoskeletonRST1A"] = "RS", -- Riverside exoskeleton
    ["Base.ExoskeletonRST1B"] = "RS", -- Riverside exoskeleton
    ["Base.ExoskeletonRST1C"] = "RS", -- Riverside exoskeleton
    ["Base.ExoskeletonLVT1A"] = "LV", -- Louisville exoskeleton
    ["Base.ExoskeletonLVT1B"] = "LV", -- Louisville exoskeleton
    ["Base.ExoskeletonLVT1C"] = "LV", -- Louisville exoskeleton
    ["Base.ExoskeletonAdmin"] = "Admin" -- Admin exoskeleton
}

ZMEquipmentHandler.restrictedGearTypes = {
  ["Base.Ashley"] = true,
  ["Base.Helga0"] = true,
  ["Base.Specialist"] = true,
  ["Base.Tifa"] = true,
  ["Base.ada_wong"] = true,
  ["Base.fbi"] = true,
  ["Base.swat"] = true,
  ["Base.Art_Of_Clown"] = true,
  ["Base.BF2042Antivirus"] = true,
  ["Base.2B"] = true,
  ["Base.Taiho"] = true,
  ["Base.Domestic_Cunt"] = true,
  ["Base.Horned_Slut"] = true,
  ["Base.frog"] = true,
  ["Base.GI_Klee"] = true,
  ["Base.Giyu"] = true,
  ["Base.GoKu"] = true,
  ["Base.King"] = true,
  ["Base.klukai_Girls_Frontline"] = true,
  ["Base.Nexus"] = true,
  ["Base.Nezuko"] = true,
  ["Base.Manusia"] = true,
  ["Exclusive.Silver_Wolf"] = true,
  ["Stranger.Stranger"] = true
}


function ZMEquipmentHandler.logRestrictedGear(player, itemType)
  if player and itemType then
      sendClientCommand("ZonaMerahCore", "LogCheat", {
          username = player:getUsername(),
          cheatType = "RestrictedGear",
          details = "Tried to equip: " .. itemType
      })
      player:Say("You are not allowed to equip this")
  end
end

-- Store and retrieve restricted gear allow flags in globalModData

-- Setter: allow a username to equip a restricted itemType
function ZMEquipmentHandler.setRestrictedGearAllow(username, itemType, allow)
    if not username or not itemType then return end
    local globalModData = ModData.getOrCreate("ZMRestrictedGearAllow")
    if not globalModData[username] then
        globalModData[username] = {}
    end
    globalModData[username][itemType] = allow and true or nil
    ModData.transmit("ZMRestrictedGearAllow")
end

-- Getter: check if a username is allowed to equip a restricted itemType
function ZMEquipmentHandler.isRestrictedGearAllowed(username, itemType)
    if not username or not itemType then return false end
    local globalModData = ModData.getOrCreate("ZMRestrictedGearAllow")
    return globalModData[username] and globalModData[username][itemType] == true
end

-- Function to check if player has the location-specific unlock
function ZMEquipmentHandler.hasLocationUnlock(player, locationType)
    -- Use PlayerTierHandler's hasLocationPermission function
    if locationType == "MD" then
        return PlayerTierHandler.hasLocationPermission(player, "MD")
    elseif locationType == "RS" then
        return PlayerTierHandler.hasLocationPermission(player, "RS")
    elseif locationType == "LV" then
        return PlayerTierHandler.hasLocationPermission(player, "LV")
    elseif locationType == "Admin" then
        return player:isAccessLevel("admin")
    end
    return false
end

-- Function to set location unlock status
function ZMEquipmentHandler.setLocationUnlock(player, locationType, value)
    if not player then return end

    -- Use PlayerTierHandler to set the permission
    PlayerTierHandler.setLocationPermission(player, locationType, value)
end

-- Helper function to check if item is an exoskeleton
function ZMEquipmentHandler.isExoskeleton(item)
    if not item then return false end
    local itemType = item:getFullType()
    return ZMEquipmentHandler.exoRequirements[itemType] ~= nil
end

-- Check if player can use a specific exoskeleton by its type
function ZMEquipmentHandler.canUseExo(player, exoType)
    if not player then return false, "player", nil end

    -- Get player's exo operator level
    local playerLevel = PlayerTierHandler.getExoOperatorLevel(player)
    local requiredLevel = ZMEquipmentHandler.exoRequirements[exoType] or ZMEquipmentHandler.minExoOperatorLevel

    print("Checking exo: " .. exoType .. ", Player level: " .. playerLevel .. ", Required level: " .. requiredLevel)

    -- First check general level requirement
    if playerLevel < requiredLevel then
        print("DENIED: Insufficient level for " .. exoType)
        return false, "level", requiredLevel
    end

    -- Then check location-specific permission if applicable
    local locationType = ZMEquipmentHandler.locationExoTypes[exoType]
    if locationType then
        print("Location requirement: " .. locationType)
        local hasPermission = ZMEquipmentHandler.hasLocationUnlock(player, locationType)
        print("Has permission: " .. tostring(hasPermission))

        if not hasPermission then
            print("DENIED: Missing location permission for " .. locationType)
            return false, "location", locationType
        end
    end

    print("ALLOWED: All requirements met for " .. exoType)
    return true
end

-- This function runs when clothing changes
function ZMEquipmentHandler.onClothingUpdated(player)
    if not ZMEquipmentHandler.restrictExoSkeleton then return end
    ZMEquipmentHandler.setRestrictedGearAllow("inzhani", "Base.Art_Of_Clown", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Jah", "Base.BF2042Antivirus", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Jillian", "Base.BF2042Antivirus", true)
    ZMEquipmentHandler.setRestrictedGearAllow("MarioneLaplusX", "Base.Taiho", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Benihana", "Base.Domestic_Cunt", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Neon", "Base.Horned_Slut", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Noen", "Base.Horned_Slut", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Jah", "Base.Giyu", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Flow", "Base.frog", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Swiper", "Base.GI_Klee", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Goku", "Base.GoKu", true)
    ZMEquipmentHandler.setRestrictedGearAllow("inzhani", "Base.King", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Aruuto", "Base.klukai_Girls_Frontline", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Lenka", "Base.Nexus", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Vefulz", "Base.Nezuko", true)
    ZMEquipmentHandler.setRestrictedGearAllow("CowboyTanaka", "Base.Manusia", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Yuu", "Exclusive.Silver_Wolf", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Stranger", "Stranger.Stranger", true)
    ZMEquipmentHandler.setRestrictedGearAllow("admin", "Base.swat", true)

    local inventory = player:getInventory()
    local wornItems = player:getWornItems()

    for i=0, wornItems:size()-1 do
        local item = wornItems:getItemByIndex(i)
        if item then
            local itemType = item:getFullType()

            -- Restrict and log restricted gear
            local username = player:getUsername()
            if ZMEquipmentHandler.restrictedGearTypes[itemType] and not ZMEquipmentHandler.isRestrictedGearAllowed(username, itemType) then
                player:removeWornItem(item)
                -- inventory:AddItem(item)
                ZMEquipmentHandler.logRestrictedGear(player, itemType)
            end

            -- Check if this is an exoskeleton by type
            if ZMEquipmentHandler.exoRequirements[itemType] then
                -- Found an exoskeleton, check if player is allowed to use it
                local canUse, reason, requirement = ZMEquipmentHandler.canUseExo(player, itemType)
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
                end
            end
        end
    end
end

-- Hook into inventory context menu event
function ZMEquipmentHandler.onFillInventoryContextMenu(playerIndex, context, items)
  local player = getSpecificPlayer(playerIndex)
  if not player then return end

  -- Check if we're dealing with an exoskeleton
  local exoItem = nil
  local exoType = nil

  -- Try to find an exoskeleton in the selected items
  for i,v in ipairs(items) do
      local item = v
      if instanceof(v, "InventoryItem") then
          item = v
      else
          item = v.items[1]
      end

      if item then
          local itemType = item:getFullType()
          if ZMEquipmentHandler.exoRequirements[itemType] then
              exoItem = item
              exoType = itemType
              break
          end
      end
  end

  -- If we found an exoskeleton, check permissions
  if exoItem and exoType then
      local canUse, reason, requirement = ZMEquipmentHandler.canUseExo(player, exoType)

      -- Only intercept when we need to block usage
      if not canUse then
          -- Use a safer approach - track if we modified the menu
          local blockWear = function(option, param1, param2)
              -- This prevents the wear action and shows a message instead
              if reason == "level" then
                  player:Say("You need to be Exo Operator Level " .. requirement .. " to use this exoskeleton.")
              elseif reason == "location" then
                  local locationName = ""
                  if requirement == "MD" then locationName = "Muldraugh"
                  elseif requirement == "RS" then locationName = "Riverside"
                  elseif requirement == "LV" then locationName = "Louisville"
                  elseif requirement == "Admin" then locationName = "Admin"
                  end
                  player:Say("You need to unlock " .. locationName .. " exoskeleton privileges.")
              end
              return false
          end

          -- Override the ISInventoryPaneContextMenu.onWearItems function
          local oldOnWearItems = ISInventoryPaneContextMenu.onWearItems
          ISInventoryPaneContextMenu.onWearItems = function(...)
              local args = {...}
              local items = args[2]

              -- Check if this is our exoskeleton
              for i,v in ipairs(items) do
                  local item = v
                  if instanceof(v, "InventoryItem") then
                      item = v
                  else
                      item = v.items[1]
                  end

                  if item and item == exoItem then
                      if not canUse then
                          blockWear()
                          return
                      end
                  end
              end

              -- If it's not our exoskeleton or we can use it, proceed normally
              oldOnWearItems(...)
          end

          -- Correctly store the function reference for removal
          local restoreFunction = function()
              ISInventoryPaneContextMenu.onWearItems = oldOnWearItems
              Events.OnTick.Remove(restoreFunction) -- Remove using our own reference
          end

          -- Add the function reference to the event
          Events.OnTick.Add(restoreFunction)
      end
  end
end

-- Debug function to show item types in inventory
function ZMEquipmentHandler.debugItemTypes(player)
    if not player then player = getPlayer() end
    local inventory = player:getInventory()
    local items = inventory:getItems()

    print("==== EXOSKELETON DEBUG ====")
    print("Player: " .. player:getUsername())
    print("Exo Operator Level: " .. PlayerTierHandler.getExoOperatorLevel(player))
    print("MD Permission: " .. tostring(PlayerTierHandler.hasLocationPermission(player, "MD")))
    print("RS Permission: " .. tostring(PlayerTierHandler.hasLocationPermission(player, "RS")))
    print("LV Permission: " .. tostring(PlayerTierHandler.hasLocationPermission(player, "LV")))
    print("Admin: " .. tostring(player:isAccessLevel("admin")))
    print("Items in inventory:")

    for i=0, items:size()-1 do
        local item = items:get(i)
        if item then
            local displayName = item:getDisplayName()
            local fullType = item:getFullType()
            print("- " .. displayName .. " = " .. fullType)

            -- Check if this is an exoskeleton
            if ZMEquipmentHandler.isExoskeleton(item) then
                local canUse, reason, requirement = ZMEquipmentHandler.canUseExo(player, fullType)
                print("  (Exo) Can use: " .. tostring(canUse) ..
                     (reason and (", Reason: " .. reason) or "") ..
                     (requirement and (", Requirement: " .. requirement) or ""))
            end
        end
    end

    print("=========================")
    player:Say("Item types printed to console log")
end

-- Manually grant a location permission for testing
function ZMEquipmentHandler.grantLocationPermission(player, location)
    if not player then player = getPlayer() end
    PlayerTierHandler.setLocationPermission(player, location, 1)
    player:Say("Permission granted for " .. location)
    ZMEquipmentHandler.debugItemTypes(player)
end

-- Initialize restricted gear permissions
function ZMEquipmentHandler.initializeRestrictedGearPermissions()
    -- Allow specific users to equip restricted items
    ZMEquipmentHandler.setRestrictedGearAllow("inzhani", "Base.Art_Of_Clown", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Jah", "Base.BF2042Antivirus", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Jillian", "Base.BF2042Antivirus", true)
    ZMEquipmentHandler.setRestrictedGearAllow("MarioneLaplusX", "Base.Taiho", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Benihana", "Base.Domestic_Cunt", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Neon", "Base.Horned_Slut", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Noen", "Base.Horned_Slut", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Jah", "Base.Giyu", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Flow", "Base.frog", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Swiper", "Base.GI_Klee", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Goku", "Base.GoKu", true)
    ZMEquipmentHandler.setRestrictedGearAllow("inzhani", "Base.King", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Aruuto", "Base.klukai_Girls_Frontline", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Lenka", "Base.Nexus", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Vefulz", "Base.Nezuko", true)
    ZMEquipmentHandler.setRestrictedGearAllow("CowboyTanaka", "Base.Manusia", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Yuu", "Exclusive.Silver_Wolf", true)
    ZMEquipmentHandler.setRestrictedGearAllow("Stranger", "Stranger.Stranger", true)
    ZMEquipmentHandler.setRestrictedGearAllow("admin", "Base.swat", true)
end

-- Call initialization when the module loads
ZMEquipmentHandler.initializeRestrictedGearPermissions()

-- Register event handlers
Events.OnClothingUpdated.Add(ZMEquipmentHandler.onClothingUpdated)
Events.OnFillInventoryObjectContextMenu.Add(ZMEquipmentHandler.onFillInventoryContextMenu)

return ZMEquipmentHandler