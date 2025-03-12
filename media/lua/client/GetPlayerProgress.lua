-- -- Function to get and save the player's XP to mod data
-- function savePlayerXPToModData()
--   -- Get the current player (assumes single player)
--   local player = getPlayer()

--   -- Get the player's XP
--   local xpTable = {
--       claimable = true,
--       data = {}
--   }
--   local allPerks = PerkFactory.PerkList
--   for i = 0, allPerks:size() - 1 do
--       local perk = allPerks:get(i)
--       xpTable.data[perk:getType():toString()] = player:getXp():getXP(perk)
--   end

--   -- Save the XP data to the mod data
--   player:getModData().playerXP = xpTable

--   -- Print the XP data to the log for verification
--   for perk, xp in pairs(xpTable.data) do
--       print("Player's " .. perk .. " XP: " .. xp)
--   end
--   print("Claimable: " .. tostring(xpTable.claimable))
-- end

-- -- Function to load the player's XP from mod data if claimable
-- function loadPlayerXPFromModData()
--   -- Get the current player (assumes single player)
--   local player = getPlayer()
--   local xpTable = player:getModData().playerXP

--   -- Check if the XP data is claimable
--   if xpTable and xpTable.claimable then
--       local allPerks = PerkFactory.PerkList
--       for i = 0, allPerks:size() - 1 do
--           local perk = allPerks:get(i)
--           local perkType = perk:getType():toString()
--           if xpTable.data[perkType] then
--               local savedXP = xpTable.data[perkType]
--               if player:getXp() then
--                   local currentXP = player:getXp():getXP(perk)
--                   local xpToAdd = savedXP - currentXP
--                   print("Current XP for perk " .. perkType .. ": " .. currentXP)
--                   print("XP to add for perk " .. perkType .. ": " .. xpToAdd)
--                   if xpToAdd > 0 then
--                       local success, err = pcall(function()
--                           player:getXp():AddXP(perk, xpToAdd)
--                       end)
--                       if not success then
--                           print("Error adding XP for perk " .. perkType .. ": " .. err)
--                       end
--                   else
--                       print("No XP to add for perk " .. perkType)
--                   end
--               else
--                   print("Error: player:getXp() is nil")
--               end
--           else
--               print("Error: xpTable.data[perkType] is nil for perkType: " .. perkType)
--           end
--       end

--       -- Set claimable to false after claiming the XP
--       xpTable.claimable = false
--       player:getModData().playerXP = xpTable

--       -- Print confirmation to the log
--       print("Player's XP has been claimed and updated.")
--   else
--       print("XP data is not claimable or does not exist.")
--   end
-- end

-- -- /setaccesslevel DrunkenLee admin