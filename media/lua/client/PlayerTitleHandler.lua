PlayerTitleHandler = {}

local titlesValue = {1, 2, 3}
-- 1 = VIP, 2 = VVIP, 3 = MVP

-- Function to assign a title to a player
function PlayerTitleHandler.assignPlayerTitle(player, title)
    local modData = player:getModData()
    modData.PlayerTitle = title
    player:Say("Your grade has been upgraded successfully: " .. title)
end

-- Function to get a player's title
function PlayerTitleHandler.getPlayerTitle(player)
    local modData = player:getModData()
    local title = modData.PlayerTitle or 0 -- Default to 0 if no title is set
    print("[ZonaMerahCore] Player: " .. player:getUsername() .. " has title: " .. title)
    return title
end

return PlayerTitleHandler