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

local zones1 = { "Army", "SecretBase", "SecretLab", "Prison" }
local zones2 = { "Police", "PoliceState" }

for _, zoneName in ipairs(zones1) do
	local zone = ensureZone(zoneName)
	upsertOutfit(zone, "ArmyCamoGreen", "ArmyCamoGreen", 20)
	upsertOutfit(zone, "Screamer2", "Screamer2", 5)
end

for _, zoneName in ipairs(zones2) do
  local zone = ensureZone(zoneName)
  upsertOutfit(zone, "Screamer1", "Screamer1", 5)
end
