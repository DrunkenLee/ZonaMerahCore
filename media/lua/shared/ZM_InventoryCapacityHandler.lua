ZM_InventoryCapacityHandler = ZM_InventoryCapacityHandler or {}

local MODULE = "ZM_InventoryCapacityHandler"
local CMD_REQUEST_SET = "requestSetCurrentCapacity"
local CMD_REQUEST_CLEAR = "requestClearCurrentCapacity"
local CMD_REQUEST_SYNC = "requestSyncCurrentCapacity"
local CMD_SYNC = "syncCurrentCapacity"
local CMD_SET_RESPONSE = "setCurrentCapacityResponse"
local CMD_CLEAR_RESPONSE = "clearCurrentCapacityResponse"
local MODDATA_KEY = "ZM_ForcedInventoryCapacity"

local function isClientRuntime()
    return type(isClient) == "function" and isClient()
end

local function isServerRuntime()
    return type(isServer) == "function" and isServer()
end

local function toSafeCapacity(value)
    local n = tonumber(value)
    if n == nil then
        return nil
    end

    n = math.floor(n)
    if n < 1 then
        n = 1
    end

    return n
end

local function shouldPersistOverride(persistOverride)
    if persistOverride == nil then
        return true
    end
    return persistOverride ~= false
end

local function applyCapacityToPlayer(playerObj, capacity)
    if not playerObj then
        return false, "Player is nil."
    end

    local safeCapacity = toSafeCapacity(capacity)
    if not safeCapacity then
        return false, "Invalid capacity value."
    end

    playerObj:setMaxWeightBase(safeCapacity)
    playerObj:setMaxWeight(safeCapacity)
    return true, safeCapacity
end

local function buildSyncPayload(playerObj)
    if not playerObj then
        return nil
    end

    local modData = playerObj:getModData()
    local forcedCapacity = toSafeCapacity(modData and modData[MODDATA_KEY] or nil)
    local baseCapacity = toSafeCapacity(playerObj:getMaxWeightBase())
    local currentCapacity = toSafeCapacity(playerObj:getMaxWeight())

    if not currentCapacity then
        currentCapacity = baseCapacity
    end

    return {
        username = playerObj:getUsername(),
        hasOverride = forcedCapacity ~= nil,
        forcedCapacity = forcedCapacity,
        maxWeightBase = baseCapacity,
        maxWeight = currentCapacity
    }
end

local function syncCapacityToClient(playerObj)
    if not isServerRuntime() or not playerObj then
        return false
    end

    local payload = buildSyncPayload(playerObj)
    if not payload then
        return false
    end

    sendServerCommand(playerObj, MODULE, CMD_SYNC, payload)
    return true
end

function ZM_InventoryCapacityHandler.syncCurrentCapacityToClient(playerObj)
    if not isServerRuntime() then
        return false, "syncCurrentCapacityToClient is server-only."
    end

    if not playerObj then
        return false, "Player is nil."
    end

    return syncCapacityToClient(playerObj)
end

function ZM_InventoryCapacityHandler.setCurrentCapacityAndSync(playerObj, capacity)
    if not isServerRuntime() then
        return false, "setCurrentCapacityAndSync is server-only."
    end

    local success, valueOrMessage = applyCapacityToPlayer(playerObj, capacity)
    if not success then
        return false, valueOrMessage
    end

    syncCapacityToClient(playerObj)
    return true, valueOrMessage
end

function ZM_InventoryCapacityHandler.setCurrentPlayerCapacityByForce(playerObj, capacity, persistOverride)
    if not isServerRuntime() then
        return false, "setCurrentPlayerCapacityByForce is server-only."
    end

    local success, valueOrMessage = applyCapacityToPlayer(playerObj, capacity)
    if not success then
        return false, valueOrMessage
    end

    local modData = playerObj:getModData()
    if shouldPersistOverride(persistOverride) then
        modData[MODDATA_KEY] = valueOrMessage
    else
        modData[MODDATA_KEY] = nil
    end

    syncCapacityToClient(playerObj)
    return true, valueOrMessage
end

function ZM_InventoryCapacityHandler.clearCurrentPlayerCapacityOverride(playerObj)
    if not isServerRuntime() then
        return false, "clearCurrentPlayerCapacityOverride is server-only."
    end
    if not playerObj then
        return false, "Player is nil."
    end

    local modData = playerObj:getModData()
    modData[MODDATA_KEY] = nil
    syncCapacityToClient(playerObj)
    return true
end

function ZM_InventoryCapacityHandler.applyPersistedCapacity(playerObj)
    if not isServerRuntime() then
        return false, "applyPersistedCapacity is server-only."
    end
    if not playerObj then
        return false, "Player is nil."
    end

    local modData = playerObj:getModData()
    local forcedCapacity = toSafeCapacity(modData and modData[MODDATA_KEY] or nil)
    if not forcedCapacity then
        syncCapacityToClient(playerObj)
        return false, "No persisted capacity override."
    end

    local success, valueOrMessage = applyCapacityToPlayer(playerObj, forcedCapacity)
    if success then
        syncCapacityToClient(playerObj)
    end
    return success, valueOrMessage
end

function ZM_InventoryCapacityHandler.requestSetCurrentCapacity(capacity, persistOverride)
    if not isClientRuntime() then
        return false, "requestSetCurrentCapacity is client-only."
    end

    sendClientCommand(MODULE, CMD_REQUEST_SET, {
        capacity = capacity,
        persistOverride = persistOverride
    })
    return true
end

function ZM_InventoryCapacityHandler.requestClearCurrentCapacity()
    if not isClientRuntime() then
        return false, "requestClearCurrentCapacity is client-only."
    end

    sendClientCommand(MODULE, CMD_REQUEST_CLEAR, {})
    return true
end

function ZM_InventoryCapacityHandler.requestSyncCurrentCapacity()
    if not isClientRuntime() then
        return false, "requestSyncCurrentCapacity is client-only."
    end

    sendClientCommand(MODULE, CMD_REQUEST_SYNC, {})
    return true
end

if isServerRuntime() and Events and Events.OnClientCommand then
    Events.OnClientCommand.Add(function(module, command, playerObj, args)
        if module ~= MODULE then
            return
        end
        if not playerObj then
            return
        end

        if command == CMD_REQUEST_SET then
            local success, valueOrMessage = ZM_InventoryCapacityHandler.setCurrentPlayerCapacityByForce(
                playerObj,
                args and args.capacity,
                args and args.persistOverride
            )

            sendServerCommand(playerObj, MODULE, CMD_SET_RESPONSE, {
                success = success,
                capacity = success and valueOrMessage or nil,
                message = success and ("Inventory capacity set to " .. tostring(valueOrMessage) .. ".") or tostring(valueOrMessage)
            })
        elseif command == CMD_REQUEST_CLEAR then
            local success, message = ZM_InventoryCapacityHandler.clearCurrentPlayerCapacityOverride(playerObj)
            sendServerCommand(playerObj, MODULE, CMD_CLEAR_RESPONSE, {
                success = success,
                message = success and "Inventory capacity override cleared." or tostring(message)
            })
        elseif command == CMD_REQUEST_SYNC then
            ZM_InventoryCapacityHandler.applyPersistedCapacity(playerObj)
        end
    end)
end

if isClientRuntime() and Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= MODULE then
            return
        end

        if command == CMD_SYNC then
            local playerObj = getPlayer()
            if not playerObj then
                return
            end

            local safeBase = toSafeCapacity(args and args.maxWeightBase or nil)
            local safeCurrent = toSafeCapacity(args and args.maxWeight or nil) or safeBase
            if safeBase then
                playerObj:setMaxWeightBase(safeBase)
                playerObj:setMaxWeight(safeCurrent)
            end
        elseif command == CMD_SET_RESPONSE or command == CMD_CLEAR_RESPONSE then
            local playerObj = getPlayer()
            if playerObj and args and args.message then
                playerObj:Say(tostring(args.message))
            end
        end
    end)
end

if isServerRuntime() and Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
        local player = playerObj or getSpecificPlayer(playerIndex)
        if not player then
            return
        end
        ZM_InventoryCapacityHandler.applyPersistedCapacity(player)
    end)
end

if isClientRuntime() and Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
        local player = playerObj or getSpecificPlayer(playerIndex) or getPlayer()
        if not player then
            return
        end
        ZM_InventoryCapacityHandler.requestSyncCurrentCapacity()
    end)
end

if isClientRuntime() then
    if not _G.zmSetInventoryCapacity then
        _G.zmSetInventoryCapacity = ZM_InventoryCapacityHandler.requestSetCurrentCapacity
    end

    if not _G.zmClearInventoryCapacityOverride then
        _G.zmClearInventoryCapacityOverride = ZM_InventoryCapacityHandler.requestClearCurrentCapacity
    end
end

return ZM_InventoryCapacityHandler
