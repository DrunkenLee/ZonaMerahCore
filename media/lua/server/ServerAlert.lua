function SendAlert()
  local players = getOnlinePlayers()
  if players then
      for i = 0, players:size() - 1 do
          local player = players:get(i)
          sendServerCommand(player, "ServerAlert", "alert", { name = "TEST NAME" })
      end
  end
end

local function OnClientCommand(module, command, player, args)
    SendAlert()
end

Events.OnClientCommand.Add(OnClientCommand)