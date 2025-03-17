PlayerTitleHandler = {}

local titlesValue = {1, 2, 3}
-- 1 = VIP, 2 = VVIP, 3 = MVP

function PlayerTitleHandler.assignPlayerTitle(player, title)
    local username = player:getUsername()
    PlayerTitleHandler[username] = title
    player:Say("Your grade has been upgraded successfully: " .. title)
end

function PlayerTitleHandler.getPlayerTitle(player)
    local username = player:getUsername()
    local title = PlayerTitleHandler[username] or 0
    print("[ZonaMerahCore] Player: " .. username .. " has title: " .. title)
    return title
end

return PlayerTitleHandler