Events.OnClientCommand.Add(function(module, command, player, args)
  -- print("[TestServer] Received command from client: " .. command)s
  if module == "TestModule" and command == "TestCommand" then
      print("[TestServer] Received command from client: " .. args.message)
      print("[TestServer] Sending response back to client...")

      -- Send a response back to the client
      sendServerCommand(player, "TestModule", "TestResponse", { message = "Hello from the server!" })
  end
end)