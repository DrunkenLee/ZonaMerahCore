-- Function to send a command to the server when the 'K' key is pressed
Events.OnKeyPressed.Add(function(key)
  -- Check if the key pressed is 'K' (key code 37 for 'K')
  if key == 37 then
      print("[TestClient] Sending test command to server...")
      sendClientCommand("TestModule", "TestCommand", { message = "Hello from the client!" })
  end
end)

-- Handle server response
Events.OnServerCommand.Add(function(module, command, args)
  if module == "TestModule" and command == "TestResponse" then
      print("[TestClient] Received response from server: " .. args.message)
  end
end)