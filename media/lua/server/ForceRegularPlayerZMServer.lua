ForceRegularPlayerZMServer = ForceRegularPlayerZMServer or {}
-- overided 1
-- Handle client commands
local function OnClientCommand(module, command, player, args)
    if module == "ZonaMerahCore" then
        if command == "LogCheat" then
            print("[ZonaMerahCore] CHEAT DETECTED - Player: " .. args.username .. " | Type: " .. args.cheatType .. " | Details: " .. args.details)
        elseif command == "RequestInvisible" then
            -- Toggle invisibility using force parameter to bypass permission checks
            -- local currentlyInvisible = player:isInvisible()

            -- -- Force invisibility/ghost mode (second parameter bypasses access checks)
            player:setInvisible(false, true)
            -- player:setGhostMode(not currentlyInvisible, true)
            -- player:setZombiesDontAttack(not currentlyInvisible)

            print("[ZonaMerahCore] Toggled invisibility for: " .. player:getUsername() .. " (now: " .. tostring(not currentlyInvisible) .. ")")
        elseif command == "SetEndurance" then
          -- Set endurance to maximum for NenekLincah
              local stats = player:getStats()
              player:setUnlimitedAmmo(true)
              if stats then
                  stats:setLastEndurance(1.0)
                  local enduranceStat = CharacterStat.getById("Endurance")
                  if enduranceStat then
                      stats:add(enduranceStat, 1.0)
                  end
                  -- print("[ZonaMerahCore] Set endurance to max for: " .. player:getUsername())
              end
        end
    end
end

Events.OnClientCommand.Add(OnClientCommand)