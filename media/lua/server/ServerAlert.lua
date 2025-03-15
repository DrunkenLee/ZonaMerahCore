function SendAlert(targetPlayer)
  local players = getOnlinePlayers()
  if players then
      for i = 0, players:size() - 1 do
          local player = players:get(i)
          if not targetPlayer or player == targetPlayer then
              sendServerCommand(player, "ServerAlert", "alert", {
                  message = "This is a test alert.",
                  color = "<RGB:1,0,0>", -- Red color
                  username = "Server",
                  options = {
                      showTime = true,
                      serverAlert = true,
                      showAuthor = true,
                  }
              })
          end
      end
  end
end

local function OnClientCommand(module, command, player, args)
  if module == "ServerAlert" and command == "sendAlert" then
      if args.targetPlayer then
          local targetPlayer = getPlayerByUsername(args.targetPlayer)
          SendAlert(targetPlayer)
      else
          SendAlert()
      end
  end
end

Events.OnClientCommand.Add(OnClientCommand)