ZM_ZombieHandlerServer = ZM_ZombieHandlerServer or {}

local ZM_GEM_DROP_CHANCE = 5 -- percent per item (5/100)
local ZM_GEM_DROP_ITEMS = {
    "Base.Diamond",
    "Base.Emerald",
    "Base.Ruby",
    "Base.Sapphire",
    "Base.Amethyst"
}

local ZM_GEM_DROP_TYPES = {
    elite = true,
    screamer1 = true,
    screamer2 = true
}

local function isNightmareZombie(zombie, zombieOutfit)
    if not zombie then return false end
    local modData = zombie:getModData()
    if modData and modData.ZM_ZombieType == "nightmares" then
        return true
    end
    return zombieOutfit == "StripperNaked"
end

-- Send zombie health to the attacker client for immediate sync
function ZM_ZombieHandlerServer.syncZombieHealthToClient(attacker, zombie)
    if not attacker or not zombie then return end
    if not isServer or not isServer() then return end
    if attacker.isPlayer and attacker:isPlayer() then
        sendServerCommand(attacker, "ZM_ZombieHandler", "syncZombieHealth", {
            zombieID = zombie:getOnlineID(),
            health = zombie:getHealth()
        })
    end
end

-- Hit handler for special zombie abilities (shared to keep client/server in sync)
function ZM_ZombieHandlerServer.onZombieHit(zombie, attacker, bodyPart, weapon)
    if not zombie or not attacker then return end

    local zombieOutfit = zombie:getOutfitName()
    if not zombieOutfit then return end

    -- Defer sprint walk types until the zombie is hit for the first time
    local modData = zombie:getModData()
    if modData and modData.ZM_DesiredWalkType and not modData.ZM_WalkTypeSet then
        local desiredWalkType = modData.ZM_DesiredWalkType
        if desiredWalkType == "sprint1" or desiredWalkType == "sprint2" then
            zombie:setWalkType(desiredWalkType)
            modData.ZM_WalkTypeSet = true
        end
    end

    if isNightmareZombie(zombie, zombieOutfit) then
        local isStomp = false
        if attacker and attacker.isDoStomp then
            isStomp = attacker:isDoStomp()
            -- print("Nightmare hit detected. IsStomp: " .. tostring(isStomp))
        end

        if isStomp then
            local stompWeapon = nil
            if weapon and instanceof(weapon, "HandWeapon") then
                stompWeapon = weapon
            end
            if zombie.setAvoidDamage then
                zombie:setAvoidDamage(false)
            end

            if not zombie:isDead() then
                zombie:setHealth(0)
                if zombie.Kill then
                    zombie:Kill(stompWeapon, attacker)
                end
            end
            ZM_ZombieHandlerServer.syncZombieHealthToClient(attacker, zombie)
            local nightmareData = zombie:getModData()
            nightmareData.ZM_NightmareHealth = zombie:getHealth()
        else
            if zombie.setAvoidDamage then
                zombie:setAvoidDamage(true)
            end
            local nightmareData = zombie:getModData()
            local storedHealth = nightmareData.ZM_NightmareHealth or zombie:getHealth()
            if zombie:getHealth() < storedHealth then
                zombie:setHealth(storedHealth)
            end
            nightmareData.ZM_NightmareHealth = storedHealth

            if weapon and weapon.isRanged and not weapon:isRanged() then
                zombie:hitConsequences(weapon, attacker, true, 0.0, false)
            end
            return
        end
    end

    -- ArmyCamoGreen zombie: ranged hits only have a 10% chance; melee only works with "Legend" weapons
    if zombieOutfit == "ArmyCamoGreen" then
        zombie:setSprinting(true)
        zombie:setWalkType("WTSprint2")

        local isRanged = weapon and weapon.isRanged and weapon:isRanged()
        local weaponName = ""
        if weapon then
            if weapon.getDisplayName then
                weaponName = weapon:getDisplayName()
            elseif weapon.getName then
                weaponName = weapon:getName()
            end
        end
        local isLegendWeapon = weaponName ~= "" and string.find(weaponName, "Legend") ~= nil

        if isRanged then
            local damageChance = 10 -- 10% chance to take damage from ranged
            local damageRoll = ZombRand(100)
            if damageRoll >= damageChance then
                if zombie.setAvoidDamage then
                    zombie:setAvoidDamage(true)
                end
                -- print("[ZM_ZombieHandler] ArmyCamoGreen resisted ranged damage (roll: " .. damageRoll .. " >= " .. damageChance .. ")")
            else
                if zombie.setAvoidDamage then
                    zombie:setAvoidDamage(false)
                end
            end
        else
            if isLegendWeapon then
                if zombie.setAvoidDamage then
                    zombie:setAvoidDamage(false)
                end
            else
                if zombie.setAvoidDamage then
                    zombie:setAvoidDamage(true)
                end
                if weapon and not (weapon.isRanged and weapon:isRanged()) then
                    zombie:hitConsequences(weapon, attacker, true, 0.0, false)
                end
                if weaponName ~= "" then
                    -- print("[ZM_ZombieHandler] ArmyCamoGreen resisted melee damage from " .. weaponName)
                else
                    -- print("[ZM_ZombieHandler] ArmyCamoGreen resisted melee damage")
                end
            end
        end
    end

    -- Screamer1 zombie: 40% chance to take damage (all weapons)
    if zombieOutfit == "Screamer1" then
        local hitChance = 40
        local hitRoll = ZombRand(100)
        if hitRoll >= hitChance then
            if zombie.setAvoidDamage then
                zombie:setAvoidDamage(true)
            end
        else
            if zombie.setAvoidDamage then
                zombie:setAvoidDamage(false)
            end
        end
    end

    -- Screamer2 zombie: deflects melee damage back; ranged hits only land 50% of the time
    if zombieOutfit == "Screamer2" then
        local isRanged = weapon and weapon.isRanged and weapon:isRanged()
        local specialStatusChance = 5  -- 5% chance for panic effect

        if isRanged then
            local hitChance = 50
            local hitRoll = ZombRand(100)
            if hitRoll >= hitChance then
                if zombie.setAvoidDamage then
                    zombie:setAvoidDamage(true)
                end
            else
                if zombie.setAvoidDamage then
                    zombie:setAvoidDamage(false)
                end
            end
        else
            local damageAmount = 15  -- Fixed damage amount to deflect
            local deflectRoll = ZombRand(100)
            if attacker:getBodyDamage() then
                attacker:getBodyDamage():AddDamage(BodyPartType.Head, damageAmount)
                -- print("[ZM_ZombieHandler] Screamer2 deflected " .. damageAmount .. " melee damage to attacker")
            end
        end
    end
end

Events.OnHitZombie.Add(ZM_ZombieHandlerServer.onZombieHit)
