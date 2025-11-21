-- if not isClient() then return end

-- local MOD = {}
-- MOD.offFullType = "CrucibleLightsaber.Crucible_OFF"
-- MOD.onFullType  = "CrucibleLightsaber.Crucible"


-- local function isCrucible(item)
--     return item and (item:getFullType() == MOD.offFullType or item:getFullType() == MOD.onFullType)
-- end


-- local function swapItem(inv, oldItem, toFullType, player)
--     if not inv or not oldItem then return nil end
--     if oldItem:getFullType() == toFullType then return oldItem end

--     local wasOnBack = false
--     local attached = player and player:getAttachedItems()
--     if attached then
--         local back = attached:getItem("Back")
--         if back == oldItem then wasOnBack = true end
--     end

--     local newItem = InventoryItemFactory.CreateItem(toFullType)
--     if not newItem then return nil end
--     copyState(oldItem, newItem)
--     inv:AddItem(newItem)
--     inv:DoRemoveItem(oldItem)

--     if wasOnBack and player then
--         player:setAttachedItem("Back", newItem)
--     end
--     return newItem
-- end


-- local function ensureCrucibleState(player)
--     if not player or player:isDead() then return end
--     local inv = player:getInventory(); if not inv then return end
--     local primary   = player:getPrimaryHandItem()
--     local secondary = player:getSecondaryHandItem()

--     -- Pegang → ON
--     if isCrucible(primary) and primary:getFullType() ~= MOD.onFullType then
--         local n = swapItem(inv, primary, MOD.onFullType, player)
--         if n then player:setPrimaryHandItem(n) end
--     end
--     if isCrucible(secondary) and secondary:getFullType() ~= MOD.onFullType then
--         local n = swapItem(inv, secondary, MOD.onFullType, player)
--         if n then player:setSecondaryHandItem(n) end
--     end

--     -- Tidak di tangan → semua ON dikembalikan ke OFF
--     local holdingOn = (primary and primary:getFullType() == MOD.onFullType)
--                    or (secondary and secondary:getFullType() == MOD.onFullType)
--     if not holdingOn then
--         local items = inv:getItems()
--         for i = items:size()-1, 0, -1 do
--             local it = items:get(i)
--             if it and it:getFullType() == MOD.onFullType
--                and it ~= primary and it ~= secondary then
--                 swapItem(inv, it, MOD.offFullType, player)
--             end
--         end
--         local attached = player:getAttachedItems()
--         if attached then
--             local back = attached:getItem("Back")
--             if back and back:getFullType() == MOD.onFullType then
--                 swapItem(inv, back, MOD.offFullType, player)
--             end
--         end
--     end
-- end


-- local function onCreatePlayer(idx, player)
--     if idx ~= 0 then return end -- hanya local player
--     -- Equip event
--     Events.OnEquipPrimary.Add(function(p, item)
--         if p == player and isCrucible(item) then ensureCrucibleState(player) end
--     end)
--     Events.OnEquipSecondary.Add(function(p, item)
--         if p == player and isCrucible(item) then ensureCrucibleState(player) end
--     end)
--     -- Sweep tiap menit (drag/drop safety)
--     Events.EveryOneMinute.Add(function() ensureCrucibleState(player) end)
--     -- Saat mati → OFF
--     Events.OnPlayerDeath.Add(function(pl)
--         if pl == player then ensureCrucibleState(player) end
--     end)
-- end


-- local function syncWeaponData(weapon, player)
--     if not isCrucible(weapon) then return end
--     -- Kirim data ke server (dummy, hanya untuk trigger event server-side)
--     local modData = weapon:getModData()
--     modData.__syncCrucibleState = true
--     weapon:setModData(modData)
--     sendClientCommand(player, "CrucibleLightsaber", "syncWeaponState", {})
-- end

-- Events.OnCreatePlayer.Add(onCreatePlayer)

-- if EventsPlus and EventsPlus.OnActionPerformed then
--     EventsPlus.OnActionPerformed.Add(function(action, player)
--         ensureCrucibleState(player or getSpecificPlayer(0))
--     end)
-- end