-- ZM_ExpeditionServer.lua
-- CRUD Operations for Random Codes from randomcodes.ini

ZM_ExpeditionServer = ZM_ExpeditionServer or {}

-- File path for the random codes
local CODES_FILE_PATH = "randomcodes.ini"

-- ===========================
-- CREATE
-- ===========================
-- Adds a new code entry to the file
function ZM_ExpeditionServer.createCode(id, code)
    if not id or not code then
        print("[ZM_ExpeditionServer] ERROR: createCode requires id and code")
        return false
    end

    -- First, read all existing codes
    local codes = ZM_ExpeditionServer.readAllCodes()
    if not codes then
        codes = {}
    end

    -- Add new code
    codes[tostring(id)] = tostring(code)

    -- Write all codes back to file
    local writer = getFileWriter(CODES_FILE_PATH, true, false)
    if not writer then
        print("[ZM_ExpeditionServer] ERROR: Could not open file for writing")
        return false
    end

    for key, value in pairs(codes) do
        writer:write(key .. "=" .. value .. "\n")
    end

    writer:close()
    print("[ZM_ExpeditionServer] Code created: " .. id .. "=" .. code)
    return true
end

-- ===========================
-- READ
-- ===========================
-- Reads all codes from the file
function ZM_ExpeditionServer.readAllCodes()
    local filePath = CODES_FILE_PATH
    local file = getFileReader(filePath, true)

    if not file then
        print("[ZM_ExpeditionServer] ERROR: Could not open file for reading")
        return nil
    end

    local codes = {}
    local line = file:readLine()

    while line ~= nil do
        -- Parse line format: id=code
        local equals = string.find(line, "=")
        if equals then
            local id = string.sub(line, 1, equals - 1)
            local code = string.sub(line, equals + 1)
            codes[id] = code
        end
        line = file:readLine()
    end

    file:close()
    print("[ZM_ExpeditionServer] Read " .. tostring(#codes) .. " codes from file")
    return codes
end

-- Reads a specific code by ID
function ZM_ExpeditionServer.readCodeById(id)
    if not id then
        print("[ZM_ExpeditionServer] ERROR: readCodeById requires id")
        return nil
    end

    local codes = ZM_ExpeditionServer.readAllCodes()
    if not codes then
        return nil
    end

    local code = codes[tostring(id)]
    if code then
        print("[ZM_ExpeditionServer] Found code for id " .. id .. ": " .. code)
    else
        print("[ZM_ExpeditionServer] No code found for id: " .. id)
    end

    return code
end

-- ===========================
-- UPDATE
-- ===========================
-- Updates an existing code entry
function ZM_ExpeditionServer.updateCode(id, newCode)
    if not id or not newCode then
        print("[ZM_ExpeditionServer] ERROR: updateCode requires id and newCode")
        return false
    end

    -- Read all codes
    local codes = ZM_ExpeditionServer.readAllCodes()
    if not codes then
        print("[ZM_ExpeditionServer] ERROR: Could not read codes")
        return false
    end

    -- Check if code exists
    if not codes[tostring(id)] then
        print("[ZM_ExpeditionServer] ERROR: Code with id " .. id .. " does not exist")
        return false
    end

    -- Update the code
    codes[tostring(id)] = tostring(newCode)

    -- Write back to file
    local writer = getFileWriter(CODES_FILE_PATH, true, false)
    if not writer then
        print("[ZM_ExpeditionServer] ERROR: Could not open file for writing")
        return false
    end

    for key, value in pairs(codes) do
        writer:write(key .. "=" .. value .. "\n")
    end

    writer:close()
    print("[ZM_ExpeditionServer] Code updated: " .. id .. "=" .. newCode)
    return true
end

-- ===========================
-- DELETE
-- ===========================
-- Deletes a code entry by ID
function ZM_ExpeditionServer.deleteCode(id)
    if not id then
        print("[ZM_ExpeditionServer] ERROR: deleteCode requires id")
        return false
    end

    -- Read all codes
    local codes = ZM_ExpeditionServer.readAllCodes()
    if not codes then
        print("[ZM_ExpeditionServer] ERROR: Could not read codes")
        return false
    end

    -- Check if code exists
    if not codes[tostring(id)] then
        print("[ZM_ExpeditionServer] ERROR: Code with id " .. id .. " does not exist")
        return false
    end

    -- Remove the code
    codes[tostring(id)] = nil

    -- Write back to file
    local writer = getFileWriter(CODES_FILE_PATH, true, false)
    if not writer then
        print("[ZM_ExpeditionServer] ERROR: Could not open file for writing")
        return false
    end

    for key, value in pairs(codes) do
        writer:write(key .. "=" .. value .. "\n")
    end

    writer:close()
    print("[ZM_ExpeditionServer] Code deleted: " .. id)
    return true
end

-- ===========================
-- SPECIAL FUNCTION
-- ===========================
-- Gets a random code from the file
function ZM_ExpeditionServer.getRandomCode()
    local filePath = CODES_FILE_PATH
    local file = getFileReader(filePath, true)

    if not file then
        print("[ZM_ExpeditionServer] ERROR: Could not open file for reading")
        return nil
    end

    local codes = {}
    local line = file:readLine()

    -- Read all codes into array
    while line ~= nil do
        local equals = string.find(line, "=")
        if equals then
            local code = string.sub(line, equals + 1)
            table.insert(codes, code)
        end
        line = file:readLine()
    end

    file:close()

    if #codes == 0 then
        print("[ZM_ExpeditionServer] ERROR: No codes found in file")
        return nil
    end

    -- Get random index
    local randomIndex = ZombRand(1, #codes + 1)
    local randomCode = codes[randomIndex]

    print("[ZM_ExpeditionServer] Random code selected: " .. randomCode)
    return randomCode
end

-- ===========================
-- UTILITY FUNCTIONS
-- ===========================
-- Gets the total count of codes in the file
function ZM_ExpeditionServer.getCodeCount()
    local codes = ZM_ExpeditionServer.readAllCodes()
    if not codes then
        return 0
    end

    local count = 0
    for _ in pairs(codes) do
        count = count + 1
    end

    return count
end

-- ===========================
-- SERVER-CLIENT COMMUNICATION
-- ===========================
-- Send a random code to a specific player
function ZM_ExpeditionServer.sendRandomCodeToPlayer(player)
    local code = ZM_ExpeditionServer.getRandomCode()
    if code then
        sendServerCommand(player, "ZM_Expedition", "receiveRandomCode", {code = code})
        print("[ZM_ExpeditionServer] Sent random code to player: " .. code)
    end
end

-- Send a specific code by ID to a player
function ZM_ExpeditionServer.sendCodeByIdToPlayer(player, id)
    local code = ZM_ExpeditionServer.readCodeById(id)
    if code then
        sendServerCommand(player, "ZM_Expedition", "receiveCode", {id = id, code = code})
        print("[ZM_ExpeditionServer] Sent code (ID: " .. id .. ") to player: " .. code)
    else
        sendServerCommand(player, "ZM_Expedition", "codeNotFound", {id = id})
    end
end

-- Send all codes to a player
function ZM_ExpeditionServer.sendAllCodesToPlayer(player)
    local codes = ZM_ExpeditionServer.readAllCodes()
    if codes then
        sendServerCommand(player, "ZM_Expedition", "receiveAllCodes", {codes = codes})
        print("[ZM_ExpeditionServer] Sent all codes to player")
    end
end

-- Send code count to a player
function ZM_ExpeditionServer.sendCodeCountToPlayer(player)
    local count = ZM_ExpeditionServer.getCodeCount()
    sendServerCommand(player, "ZM_Expedition", "receiveCodeCount", {count = count})
    print("[ZM_ExpeditionServer] Sent code count to player: " .. count)
end

-- OnClientCommand event handler
local function OnClientCommand(module, command, player, args)
    if module ~= "ZM_Expedition" then return end

    print("[ZM_ExpeditionServer] Received command: " .. command .. " from player: " .. player:getUsername())

    if command == "requestRandomCode" then
        ZM_ExpeditionServer.sendRandomCodeToPlayer(player)

    elseif command == "requestCodeById" then
        if args and args.id then
            ZM_ExpeditionServer.sendCodeByIdToPlayer(player, args.id)
        else
            print("[ZM_ExpeditionServer] ERROR: requestCodeById missing id parameter")
        end

    elseif command == "requestAllCodes" then
        ZM_ExpeditionServer.sendAllCodesToPlayer(player)

    elseif command == "requestCodeCount" then
        ZM_ExpeditionServer.sendCodeCountToPlayer(player)

    elseif command == "createCode" then
        if args and args.id and args.code then
            local success = ZM_ExpeditionServer.createCode(args.id, args.code)
            sendServerCommand(player, "ZM_Expedition", "codeCreated", {success = success, id = args.id})
        else
            print("[ZM_ExpeditionServer] ERROR: createCode missing parameters")
        end

    elseif command == "updateCode" then
        if args and args.id and args.code then
            local success = ZM_ExpeditionServer.updateCode(args.id, args.code)
            sendServerCommand(player, "ZM_Expedition", "codeUpdated", {success = success, id = args.id})
        else
            print("[ZM_ExpeditionServer] ERROR: updateCode missing parameters")
        end

    elseif command == "deleteCode" then
        if args and args.id then
            local success = ZM_ExpeditionServer.deleteCode(args.id)
            sendServerCommand(player, "ZM_Expedition", "codeDeleted", {success = success, id = args.id})
        else
            print("[ZM_ExpeditionServer] ERROR: deleteCode missing id parameter")
        end
    end
end

Events.OnClientCommand.Add(OnClientCommand)
