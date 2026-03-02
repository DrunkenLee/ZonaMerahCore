ZM_SetDistributions = ZM_SetDistributions or {}

local function shouldApplyDistributions()
    if type(isClient) == "function" then
        return not isClient()
    end
    return true
end

local function ensureDistributionsLoaded()
    if not SuburbsDistributions then
        require "Items/Distributions"
        require "Items/SuburbsDistributions"
    end
    return SuburbsDistributions
end

local function ensureOutfitDistribution(outfitName, rolls)
    local dist = ensureDistributionsLoaded()
    if not dist then return nil end

    dist.all = dist.all or {}
    local key = "Outfit_" .. outfitName
    local outfit = dist.all[key]

    if not outfit then
        outfit = {
            rolls = rolls or 1,
            items = {},
            junk = { rolls = 1, items = {} }
        }
        dist.all[key] = outfit
    end

    outfit.items = outfit.items or {}
    if not outfit.junk then
        outfit.junk = { rolls = 1, items = {} }
    end

    return outfit
end

function ZM_SetDistributions.addOutfitLoot(outfitName, items, opts)
    if type(outfitName) ~= "string" or outfitName == "" then
        return false
    end

    local rolls = opts and opts.rolls or nil
    local outfit = ensureOutfitDistribution(outfitName, rolls)
    if not outfit then return false end

    if opts and opts.clearItems then
        outfit.items = {}
    end

    if items then
        for _, entry in ipairs(items) do
            local itemName = entry[1]
            local weight = entry[2]
            if itemName and weight then
                outfit.items[#outfit.items + 1] = itemName
                outfit.items[#outfit.items + 1] = weight
            end
        end
    end

    if opts and opts.defaultInventoryLoot ~= nil then
        outfit.defaultInventoryLoot = opts.defaultInventoryLoot
    end

    return true
end

local function applyZMOutfitLoot()
    if ZM_SetDistributions._applied then return end
    ZM_SetDistributions._applied = true

    -- Elite (ArmyCamoGreen outfit)
    ZM_SetDistributions.addOutfitLoot("ArmyCamoGreen", {
        { "Base.Diamond", 5 },
        { "Base.Emerald", 5 },
        { "Base.Ruby", 5 },
        { "Base.Sapphire", 5 },
        { "Base.Amethyst", 5 },
        { "ZM_Mungkinkah.JessicaPill_OakRemedy", 2 },
        { "ZM_Mungkinkah.ZM_MysticOrb", 0.3 },
        { "AFKJUALAN.LegendWeaponBlueprint", 0.2 },
        { "NoMi.GomuGomuNoMi", 1 }
    })

    -- Screamer1 outfit
    ZM_SetDistributions.addOutfitLoot("Screamer1", {
        { "Base.Diamond", 20 },
        { "Base.Emerald", 20 },
        { "Base.Ruby", 20 },
        { "Base.Sapphire", 20 },
        { "Base.Amethyst", 20 },
        { "ZM_Mungkinkah.JessicaPill_OakRemedy", 5 },
        { "ZM_Mungkinkah.ZM_MysticOrb", 5 },
        { "AFKJUALAN.LegendWeaponBlueprint", 1 },
        { "Base.WeaponInfuseTicket1", 1 }
    }, { rolls = 1 })

    -- Screamer2 outfit
    ZM_SetDistributions.addOutfitLoot("Screamer2", {
        { "Base.Diamond", 20 },
        { "Base.Emerald", 20 },
        { "Base.Ruby", 20 },
        { "Base.Sapphire", 20 },
        { "Base.Amethyst", 20 },
        { "ZM_Mungkinkah.JessicaPill_OakRemedy", 5 },
        { "ZM_Mungkinkah.ZM_MysticOrb", 5 },
        { "AFKJUALAN.LegendWeaponBlueprint", 1 },
        { "Base.WeaponInfuseTicket1", 1 },
        { "NoMi.GomuGomuNoMi", 1 },
        { "NoMi.BaraBaraNoMi", 1 },
        { "NoMi.MeraMeraNoMi", 1 },
        { "NoMi.GuraGuraNoMi", 1 }
    }, { rolls = 1 })

    -- Elite2 (ArmyCamoDesert outfit)
    ZM_SetDistributions.addOutfitLoot("ArmyCamoDesert", {
        { "NoMi.YamiYamiNoMi", 1 }
    }, { rolls = 1 })

    -- Bandit_Late outfit
    ZM_SetDistributions.addOutfitLoot("Bandit_Late", {

        { "NoMi.BaraBaraNoMi", 5 },
        { "NoMi.MeraMeraNoMi", 5 },
        { "NoMi.GuraGuraNoMi", 5 }
    }, { rolls = 1 })

    -- Bandit_Mid outfit
    ZM_SetDistributions.addOutfitLoot("Bandit_Mid", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })

    -- Biker outfit
    ZM_SetDistributions.addOutfitLoot("Biker", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })

    -- MonsterBride outfit
    ZM_SetDistributions.addOutfitLoot("CostumeMonsterBride", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })

    -- BankRobber outfit
    ZM_SetDistributions.addOutfitLoot("BankRobberSuit", {
        { "NoMi.NekoNekoNoMi", 5 },
        { "NoMi.MochiMochiNoMi", 5 },
        { "NoMi.GoroGoroNoMi", 5 }
    }, { rolls = 1 })

    -- BountyHunter outfit
    ZM_SetDistributions.addOutfitLoot("BountyHunter", {
        { "NoMi.GomuGomuNoMi", 5 },
        { "NoMi.YamiYamiNoMi", 5 }
    }, { rolls = 1 })

    -- BeastMom outfit
    ZM_SetDistributions.addOutfitLoot("CostumeBeastMom", {
        { "NoMi.GomuGomuNoMi", 5 },
        { "NoMi.YamiYamiNoMi", 5 },
        { "NoMi.NikyuNikyuNoMi", 5 },
        { "NoMi.OpeOpeNoMi", 5 },
        { "NoMi.BaraBaraNoMi", 5 },
        { "NoMi.MeraMeraNoMi", 5 }
    }, { rolls = 1 })

    -- Chunk outfit
    ZM_SetDistributions.addOutfitLoot("CostumeChunk", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })

    -- CommandoJohn outfit
    ZM_SetDistributions.addOutfitLoot("CostumeCommandoJohn", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })

    -- Ghillie outfit
    ZM_SetDistributions.addOutfitLoot("Ghillie", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })

    -- Hunter outfit
    ZM_SetDistributions.addOutfitLoot("Hunter", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })

    -- IceHockey_White outfit
    ZM_SetDistributions.addOutfitLoot("IceHockey_White", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })

    -- IceHockey_White_Goalie outfit
    ZM_SetDistributions.addOutfitLoot("IceHockey_White_Goalie", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })

    -- Punk outfit
    ZM_SetDistributions.addOutfitLoot("Punk", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })

    -- Nightmares (StripperNaked outfit)
    ZM_SetDistributions.addOutfitLoot("StripperNaked", {
        { "NoMi.GomuGomuNoMi", 5 }
    }, { rolls = 1 })
end

if shouldApplyDistributions() then
    if Events and Events.OnPostDistributionMerge then
        Events.OnPostDistributionMerge.Add(applyZMOutfitLoot)
    else
        applyZMOutfitLoot()
    end
end

return ZM_SetDistributions
