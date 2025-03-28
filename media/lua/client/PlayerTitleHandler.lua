PlayerTitleHandler = {}

local titlesValue = {1, 2, 3}
-- 1 = VIP, 2 = VVIP, 3 = MVP

-- Function to assign a title to a player
function PlayerTitleHandler.assignPlayerTitle(player, title)
    if not player then return end
    local modData = player:getModData()
    local username = player:getUsername()

    -- Update local player data
    modData.PlayerTitle = title

    -- Send command to server to save the title
    sendClientCommand("PlayerTitleHandler", "savePlayerTitle", {
        username = username,
        title = title
    })

    player:Say("Your grade has been upgraded successfully: " .. title)
end

function PlayerTitleHandler.getPlayerTitle(player)
  if not player then return 0 end

  local modData = player:getModData()
  local title = modData.PlayerTitle

  -- If title exists in modData, return it
  if title ~= nil then
      return title
  end

  -- If title doesn't exist in modData, try to load from server
  local username = player:getUsername()
  print("[ZonaMerahCore] Title not found in modData for " .. username .. ", loading from server")

  -- Initialize a default value
  modData.PlayerTitle = 0

  -- Request title from server asynchronously
  sendClientCommand("PlayerTitleHandler", "loadPlayerTitle", {
      username = username
  })

  return 0
end

Events.OnServerCommand.Add(function(module, command, args)
  if module == "PlayerTitleHandler" then
      if command == "loadPlayerTitleResponse" then
          local player = getPlayer()
          if player and player:getUsername() == args.username then
              local modData = player:getModData()
              local title = tonumber(args.title) or 0
              modData.PlayerTitle = title
              print("[PlayerTitleHandler] Title loaded from server: " .. title .. " for player " .. player:getUsername())
              -- Optional: If you want to trigger an immediate effect when title loads
              if title > 0 then
                  modData.PlayerTitle = title
                  player:Say("Your supporter grade has been loaded: " .. title)
              end
          end
      end
  end
end)

return PlayerTitleHandler