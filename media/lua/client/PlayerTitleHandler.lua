PlayerTitleHandler = {}

local titlesValue = {1, 2, 3}

function PlayerTitleHandler.assignPlayerTitle(player, title)
    if not player then return end
    local modData = player:getModData()
    local username = player:getUsername()

    modData.PlayerTitle = title

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

  if title ~= nil then
      return title
  end

  local username = player:getUsername()
  print("[ZonaMerahCore] Title not found in modData for " .. username .. ", loading from server")

  modData.PlayerTitle = 0

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
              if title > 0 then
                  modData.PlayerTitle = title
                  player:Say("Your supporter grade has been loaded: " .. title)
              end
          end
      end
  end
end)

return PlayerTitleHandler