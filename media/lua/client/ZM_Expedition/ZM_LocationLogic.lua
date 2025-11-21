-- Location Logic for Zona Merah Expeditions

ZM_LocationLogic = ZM_LocationLogic or {}

ZM_LocationLogic.GenerateRandomCode = function()
    local code = ZM_ExpeditionClient.requestRandomCode() or "000000"
    if isDebugEnabled() then
        print("[ZM_LocationLogic] Generated Random Code: " .. code)
    end
    local player = getPlayer()
    if player then
        player:Say("Expedition Code: " .. code)
    end
    return code
end