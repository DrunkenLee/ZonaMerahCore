ZM_MedicalCheck = {}
ZM_MedicalCheck.lastFullHealResponse = nil
ZM_MedicalCheck.lastFullCureResponse = nil

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

ZM_MedicalCheck.requestFullHeal = function()
    local player = getPlayer()
    if not player then
        print("[ZonaMerahCore] Full-heal request failed: local player is unavailable.")
        return false
    end

    sendClientCommand("ZonaMerahCore", "RequestFullHeal", {})
    print("[ZonaMerahCore] Full-heal request sent for '" .. player:getUsername() .. "'.")
    return true
end

ZM_MedicalCheck.getLastFullHealResponse = function()
    return ZM_MedicalCheck.lastFullHealResponse
end

ZM_MedicalCheck.requestFullCure = function()
    local player = getPlayer()
    if not player then
        print("[ZonaMerahCore] Full-cure request failed: local player is unavailable.")
        return false
    end

    sendClientCommand("ZonaMerahCore", "RequestFullCure", {})
    print("[ZonaMerahCore] Full-cure request sent for '" .. player:getUsername() .. "'.")
    return true
end

ZM_MedicalCheck.getLastFullCureResponse = function()
    return ZM_MedicalCheck.lastFullCureResponse
end

local function onServerCommand(module, command, args)
    args = args or {}

    if module == "ZonaMerahCore" and command == "ExecuteCommands" then
        print("Received custom commands from server")
        local player = getPlayer()
        if not player then return end
        player:Say("Executing custom commands...")
        local commands = args.commands or {}

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
        return
    end

    if module == "ZonaMerahCore" and command == "FullHealResponse" then
        local success = args.success == true
        local message = args.message or (success and "Full heal completed." or "Full heal failed.")
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")

        ZM_MedicalCheck.lastFullHealResponse = {
            success = success,
            message = message,
            timestamp = timestamp
        }

        print("[ZonaMerahCore] " .. message)

        local player = getPlayer()
        if player and player.Say then
            player:Say(success and "Server full heal complete." or "Server full heal failed.")
        end
        return
    end

    if module == "ZonaMerahCore" and command == "FullCureResponse" then
        local success = args.success == true
        local message = args.message or (success and "Full cure completed." or "Full cure failed.")
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")

        ZM_MedicalCheck.lastFullCureResponse = {
            success = success,
            message = message,
            timestamp = timestamp
        }

        print("[ZonaMerahCore] " .. message)

        local player = getPlayer()
        if player and player.Say then
            player:Say(success and "Server full cure complete." or "Server full cure failed.")
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)

if not _G.fullHeal then
    _G.fullHeal = ZM_MedicalCheck.requestFullHeal
end

if not _G.zmFullHeal then
    _G.zmFullHeal = ZM_MedicalCheck.requestFullHeal
end

if not _G.fullCure then
    _G.fullCure = ZM_MedicalCheck.requestFullCure
end

if not _G.zmFullCure then
    _G.zmFullCure = ZM_MedicalCheck.requestFullCure
end

if not _G.healBiteInfection then
    _G.healBiteInfection = ZM_MedicalCheck.requestFullCure
end

return ZM_MedicalCheck
