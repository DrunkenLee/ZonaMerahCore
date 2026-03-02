ZombiesZoneDefinition = ZombiesZoneDefinition or {}

local function ensureZone(name)
	ZombiesZoneDefinition[name] = ZombiesZoneDefinition[name] or {}
	return ZombiesZoneDefinition[name]
end

local function upsertOutfit(zone, key, outfitName, chance)
	local def = zone[key]
	if not def then
		def = { name = outfitName }
		zone[key] = def
	end
	def.name = outfitName
	def.chance = chance
end

local zoneNames = {
	"Army",
	"SecretBase",
	"SecretLab",
	"Prison",
	"Police",
	"PoliceState",
	-- Dedicated type used for the large custom rectangle zone in B42 server script.
	"ZM_AllUniforms"
}

-- All outfits from ZM_ZombieHandlerServer.ZombieTypes
local outfitDefinitions = {
	{ key = "ArmyCamoGreen", outfit = "ArmyCamoGreen", baseChance = 14 },
	{ key = "ArmyCamoDesert", outfit = "ArmyCamoDesert", baseChance = 12 },
	{ key = "Screamer1", outfit = "Screamer1", baseChance = 11 },
	{ key = "Screamer2", outfit = "Screamer2", baseChance = 11 },
	{ key = "Bandit_Late", outfit = "Bandit_Late", baseChance = 9 },
	{ key = "Bandit_Mid", outfit = "Bandit_Mid", baseChance = 9 },
	{ key = "Biker", outfit = "Biker", baseChance = 8 },
	{ key = "CostumeMonsterBride", outfit = "CostumeMonsterBride", baseChance = 6 },
	{ key = "BankRobberSuit", outfit = "BankRobberSuit", baseChance = 8 },
	{ key = "BountyHunter", outfit = "BountyHunter", baseChance = 8 },
	{ key = "CostumeBeastMom", outfit = "CostumeBeastMom", baseChance = 6 },
	{ key = "CostumeChunk", outfit = "CostumeChunk", baseChance = 6 },
	{ key = "CostumeCommandoJohn", outfit = "CostumeCommandoJohn", baseChance = 7 },
	{ key = "Ghillie", outfit = "Ghillie", baseChance = 8 },
	{ key = "Hunter", outfit = "Hunter", baseChance = 8 },
	{ key = "IceHockey_White", outfit = "IceHockey_White", baseChance = 6 },
	{ key = "IceHockey_White_Goalie", outfit = "IceHockey_White_Goalie", baseChance = 5 },
	{ key = "Punk", outfit = "Punk", baseChance = 7 },
	{ key = "StripperNaked", outfit = "StripperNaked", baseChance = 4 }
}

-- Per-zone multipliers to vary spawn chances by area theme.
local zoneChanceMultiplier = {
	Army = {
		ArmyCamoGreen = 1.7,
		ArmyCamoDesert = 1.6,
		Ghillie = 1.4,
		Hunter = 1.3,
		Screamer2 = 1.2
	},
	SecretBase = {
		ArmyCamoGreen = 1.8,
		ArmyCamoDesert = 1.6,
		Screamer1 = 1.2,
		Screamer2 = 1.4,
		CostumeCommandoJohn = 1.3
	},
	SecretLab = {
		Screamer1 = 1.7,
		Screamer2 = 1.8,
		CostumeMonsterBride = 1.5,
		StripperNaked = 1.3,
		ArmyCamoGreen = 1.1
	},
	Prison = {
		Bandit_Late = 1.5,
		Bandit_Mid = 1.5,
		Punk = 1.7,
		Screamer2 = 1.3,
		BankRobberSuit = 1.2
	},
	Police = {
		Screamer1 = 1.6,
		BankRobberSuit = 1.5,
		BountyHunter = 1.4,
		Bandit_Mid = 1.2,
		ArmyCamoDesert = 1.1
	},
	PoliceState = {
		Screamer1 = 1.7,
		Screamer2 = 1.4,
		BankRobberSuit = 1.4,
		BountyHunter = 1.5,
		ArmyCamoGreen = 1.2
	}
}

for _, zoneName in ipairs(zoneNames) do
	local zone = ensureZone(zoneName)
	local multipliers = zoneChanceMultiplier[zoneName] or {}

	for _, def in ipairs(outfitDefinitions) do
		local multiplier = multipliers[def.key] or 1.0
		local chance = math.max(1, math.min(100, math.floor(def.baseChance * multiplier)))
		upsertOutfit(zone, def.key, def.outfit, chance)
	end
end
