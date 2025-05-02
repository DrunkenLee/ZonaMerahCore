ServerFlagHandler = ServerFlagHandler or {}

function ServerFlagHandler.executeClientSideGiveFlag(player, username, flagname, flagValue)
  sendServerCommand(player, "PlayerFlagHandler", "updateFlag", {
    username = username,  -- Include the username for validation
    flagname = flagname,
    flagValue = flagValue
  })
end

Events.OnClientCommand.Add(function(module, command, player, args)
  -- print(string.format(
  --   "[ServerFlagHandler] Received command from client: command='%s', player='%s', username=%s, flagname=%s, flagValue=%s, module=%s",
  --   tostring(command),
  --   tostring(player and player:getUsername() or "nil"),
  --   tostring(args.username or "nil"),
  --   tostring(args.flagname or "nil"),
  --   tostring(args.flagValue or "nil"),
  --   tostring(module or "nil")
  -- ))

  if module == "ServerFlagHandler" and command == "giveFlag" then
      if args.username and args.flagname then
          ServerFlagHandler.executeClientSideGiveFlag(player, args.username, args.flagname, args.flagValue)
      end
  end
end)

return ServerFlagHandler