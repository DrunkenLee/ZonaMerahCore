-- ZM_ExpeditionClient.lua
-- Client-side code management and communication with server

ZM_ExpeditionClient = ZM_ExpeditionClient or {}

-- Local storage for received codes
ZM_ExpeditionClient.cachedCodes = {}
ZM_ExpeditionClient.lastRandomCode = nil
ZM_ExpeditionClient.codeCount = 0

-- ===========================
-- CLIENT REQUEST FUNCTIONS
-- ===========================
-- Request a random code from the server
function ZM_ExpeditionClient.requestRandomCode()
    print("[ZM_ExpeditionClient] Requesting random code from server")
    sendClientCommand("ZM_Expedition", "requestRandomCode", {})
end

-- Request a specific code by ID from the server
function ZM_ExpeditionClient.requestCodeById(id)
    if not id then
        print("[ZM_ExpeditionClient] ERROR: requestCodeById requires id")
        return
    end
    print("[ZM_ExpeditionClient] Requesting code by ID: " .. id)
    sendClientCommand("ZM_Expedition", "requestCodeById", {id = tostring(id)})
end

-- Request all codes from the server
function ZM_ExpeditionClient.requestAllCodes()
    print("[ZM_ExpeditionClient] Requesting all codes from server")
    sendClientCommand("ZM_Expedition", "requestAllCodes", {})
end

-- Request the total code count from the server
function ZM_ExpeditionClient.requestCodeCount()
    print("[ZM_ExpeditionClient] Requesting code count from server")
    sendClientCommand("ZM_Expedition", "requestCodeCount", {})
end

-- Request to create a new code on the server
function ZM_ExpeditionClient.requestCreateCode(id, code)
    if not id or not code then
        print("[ZM_ExpeditionClient] ERROR: requestCreateCode requires id and code")
        return
    end
    print("[ZM_ExpeditionClient] Requesting to create code: " .. id .. "=" .. code)
    sendClientCommand("ZM_Expedition", "createCode", {id = tostring(id), code = tostring(code)})
end

-- Request to update a code on the server
function ZM_ExpeditionClient.requestUpdateCode(id, code)
    if not id or not code then
        print("[ZM_ExpeditionClient] ERROR: requestUpdateCode requires id and code")
        return
    end
    print("[ZM_ExpeditionClient] Requesting to update code: " .. id .. "=" .. code)
    sendClientCommand("ZM_Expedition", "updateCode", {id = tostring(id), code = tostring(code)})
end

-- Request to delete a code on the server
function ZM_ExpeditionClient.requestDeleteCode(id)
    if not id then
        print("[ZM_ExpeditionClient] ERROR: requestDeleteCode requires id")
        return
    end
    print("[ZM_ExpeditionClient] Requesting to delete code with ID: " .. id)
    sendClientCommand("ZM_Expedition", "deleteCode", {id = tostring(id)})
end

-- ===========================
-- DATA ACCESS FUNCTIONS
-- ===========================
-- Get the last random code received
function ZM_ExpeditionClient.getLastRandomCode()
    return ZM_ExpeditionClient.lastRandomCode
end

-- Get a cached code by ID
function ZM_ExpeditionClient.getCachedCode(id)
    return ZM_ExpeditionClient.cachedCodes[tostring(id)]
end

-- Get all cached codes
function ZM_ExpeditionClient.getAllCachedCodes()
    return ZM_ExpeditionClient.cachedCodes
end

-- Get the cached code count
function ZM_ExpeditionClient.getCachedCodeCount()
    return ZM_ExpeditionClient.codeCount
end

-- ===========================
-- SERVER COMMAND HANDLER
-- ===========================
-- OnServerCommand event handler
local function OnServerCommand(module, command, args)
    if module ~= "ZM_Expedition" then return end

    print("[ZM_ExpeditionClient] Received command: " .. command)

    if command == "receiveRandomCode" then
        if args and args.code then
            ZM_ExpeditionClient.lastRandomCode = args.code
            print("[ZM_ExpeditionClient] Received random code: " .. args.code)
        end

    elseif command == "receiveCode" then
        if args and args.id and args.code then
            ZM_ExpeditionClient.cachedCodes[args.id] = args.code
            print("[ZM_ExpeditionClient] Received code (ID: " .. args.id .. "): " .. args.code)
        end

    elseif command == "receiveAllCodes" then
        if args and args.codes then
            ZM_ExpeditionClient.cachedCodes = args.codes
            local count = 0
            for _ in pairs(args.codes) do count = count + 1 end
            print("[ZM_ExpeditionClient] Received all codes (" .. count .. " total)")
        end

    elseif command == "receiveCodeCount" then
        if args and args.count then
            ZM_ExpeditionClient.codeCount = args.count
            print("[ZM_ExpeditionClient] Received code count: " .. args.count)
        end

    elseif command == "codeNotFound" then
        if args and args.id then
            print("[ZM_ExpeditionClient] Code not found for ID: " .. args.id)
        end

    elseif command == "codeCreated" then
        if args and args.success and args.id then
            print("[ZM_ExpeditionClient] Code created successfully: " .. args.id)
        end

    elseif command == "codeUpdated" then
        if args and args.success and args.id then
            print("[ZM_ExpeditionClient] Code updated successfully: " .. args.id)
        end

    elseif command == "codeDeleted" then
        if args and args.success and args.id then
            print("[ZM_ExpeditionClient] Code deleted successfully: " .. args.id)
        end
    end
end

Events.OnServerCommand.Add(OnServerCommand)

-- ===========================
-- EXAMPLE USAGE
-- ===========================
--[[
    -- Request a random code from server
    ZM_ExpeditionClient.requestRandomCode()

    -- Request a specific code by ID
    ZM_ExpeditionClient.requestCodeById(5)

    -- Request all codes
    ZM_ExpeditionClient.requestAllCodes()

    -- Request code count
    ZM_ExpeditionClient.requestCodeCount()

    -- Create a new code
    ZM_ExpeditionClient.requestCreateCode(101, "999999")

    -- Update an existing code
    ZM_ExpeditionClient.requestUpdateCode(1, "888888")

    -- Delete a code
    ZM_ExpeditionClient.requestDeleteCode(101)

    -- Get the last random code received
    local randomCode = ZM_ExpeditionClient.getLastRandomCode()

    -- Get all cached codes
    local allCodes = ZM_ExpeditionClient.getAllCachedCodes()
--]]
