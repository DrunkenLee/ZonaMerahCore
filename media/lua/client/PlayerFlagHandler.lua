PlayerFlagHandler = PlayerFlagHandler or {}

function PlayerFlagHandler.giveFlag(flagname, flagValue)
  local player = getPlayer()
  if player and player:getModData() then
      local modData = player:getModData()

      if flagValue == false then
          -- Remove the flag completely
          modData[flagname] = nil
          player:save()
          player:Say("Flag " .. flagname .. " has been removed")
      else
          -- Set the flag to the given value
          modData[flagname] = flagValue
          player:save()
          player:Say("Flag " .. flagname .. " set to " .. tostring(flagValue))
      end
  end
end

function PlayerFlagHandler.getFlag(flagname)
  local player = getPlayer()
  if player and player:getModData() then
      local value = player:getModData()[flagname]
      -- player:Say("Flag " .. flagname .. " is " .. tostring(value))
      return value
  end
end


function PlayerFlagHandler.setFlagOnPlayer(username, flagname, flagValue)
  if not username or username == "" then
    print("[PlayerFlagHandler] Error: Invalid username")
    return false
  end
  if not flagname or flagname == "" then
    print("[PlayerFlagHandler] Error: Invalid flagname")
    return false
  end

  local action = flagValue == false and "remove" or "set"

  print("[PlayerFlagHandler] Sending command to " .. action .. " flag", flagname, "for player", username)
  sendClientCommand("ServerFlagHandler", "giveFlag", {
    username = username,
    flagname = flagname,
    flagValue = flagValue,
    action = action
  })
  return true
end


Events.OnServerCommand.Add(function(module, command, args)
  -- print(string.format(
  --   "[PlayerFlagHandler] Received command from server: command='%s', username=%s, flagname=%s, flagValue=%s, module=%s",
  --   tostring(command),
  --   tostring(args.username or "nil"),
  --   tostring(args.flagname or "nil"),
  --   tostring(args.flagValue or "nil"),
  --   tostring(module or "nil")
  -- ))
  if module == "PlayerFlagHandler" and command == "updateFlag" then
      print("[PlayerFlagHandler] Received server update for flag:", args.flagname)

      -- Get the current player's username
      local player = getPlayer()
      local currentUsername = player and player:getUsername() or ""

      -- Only apply if the update is meant for this player
      if args.username and args.username == currentUsername and args.flagname then
          print("[PlayerFlagHandler] Applying flag update for", currentUsername)
          PlayerFlagHandler.giveFlag(args.flagname, args.flagValue)
      else
          print("[PlayerFlagHandler] Ignoring flag update - not for this player")
      end
  end
end)

return PlayerFlagHandler