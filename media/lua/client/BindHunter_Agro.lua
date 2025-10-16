if not isClient() then return end

local RESET_NO_TARGET_SECS = 5
local NOISE_RADIUS = 150
local NOISE_STRENGTH = 200

local function isTargetingPlayer(zed)
    return zed and (zed:getTarget() ~= nil)
end


_G.__ZM_NZ_AGRO_ADDED = _G.__ZM_NZ_AGRO_ADDED or false

local function addAggroHook()
    if _G.__ZM_NZ_AGRO_ADDED then return end
    if not (Events and Events.OnZombieUpdate and Events.OnZombieUpdate.Add) then return end

    -- Events.OnZombieUpdate.Add(function(zed)
    --     if not zed or zed:isDead() then return end

    --     local outfit = zed:getOutfitName()
    --     if outfit ~= "Screamer1" and outfit ~= "BindHunter" then return end

    --     local md = zed:getModData()
    --     local now = getGameTime():getWorldAgeSeconds()
    --     local hasTarget = isTargetingPlayer(zed)


    --     if not hasTarget then
    --         if not md._bh_noTargetSince then
    --             md._bh_noTargetSince = now
    --         elseif (now - md._bh_noTargetSince) >= RESET_NO_TARGET_SECS then
    --             md._bh_hasAggroShouted = false
    --             md._bh_lastTargetOID = nil
    --         end
    --         return
    --     end


    --     local tgt = zed:getTarget()
    --     local tgtOID = tgt and tgt.getOnlineID and tgt:getOnlineID() or 0
    --     if not md._bh_hasAggroShouted or (md._bh_lastTargetOID ~= tgtOID) then
    --         if outfit == "Screamer1" then
    --             zed:playSound("ScreamerII_Agre")
    --         else
    --             zed:playSound("ScreamerII_Charge")
    --         end
    --         addSound(zed, zed:getX(), zed:getY(), zed:getZ(), NOISE_RADIUS, NOISE_STRENGTH)
    --         md._bh_hasAggroShouted = true
    --         md._bh_lastTargetOID = tgtOID
    --     end
    --     md._bh_noTargetSince = nil
    -- end)

    _G.__ZM_NZ_AGRO_ADDED = true
end


-- if Events and Events.OnGameStart and Events.OnGameStart.Add then
--     Events.OnGameStart.Add(addAggroHook)
-- else
--         addAggroHook()
-- end
