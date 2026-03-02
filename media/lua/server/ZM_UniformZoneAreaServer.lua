ZM_UniformZoneAreaServer = ZM_UniformZoneAreaServer or {}

local AREA_X1 = 838
local AREA_X2 = 3227
local AREA_Y1 = 5318
local AREA_Y2 = 7468
local AREA_Z = 0

local ZONE_NAME = "ZM_AllUniforms_Area_838_3227_5318_7468"
local ZONE_TYPE = "ZM_AllUniforms"

-- Performance-oriented auto spawn settings.
local AUTO_SPAWN_ENABLED = true
local AUTO_SPAWN_INTERVAL_MINUTES = 30          -- game minutes
local AUTO_SPAWN_GLOBAL_CAP = 420               -- max zombies inside this zone
local AUTO_SPAWN_TARGET_PER_PLAYER = 65         -- desired local density per player
local AUTO_SPAWN_LOCAL_RADIUS = 70              -- local density check radius
local AUTO_SPAWN_MAX_PER_PLAYER_PER_TICK = 12   -- burst limit per player
local AUTO_SPAWN_MAX_PER_TICK = 36              -- total burst limit per tick
local AUTO_SPAWN_MIN_DISTANCE = 24              -- avoid popping zombies too close
local AUTO_SPAWN_MAX_DISTANCE = 72
local AUTO_SPAWN_ATTEMPTS_PER_ZED = 6
local AUTO_SPAWN_DEBUG = false

local _lastAutoSpawnWorldMinute = -99999999

local function uniformLog(msg)
	print("[ZonaMerah][UniformZone] " .. tostring(msg))
end

local function getAreaWidth()
	return (AREA_X2 - AREA_X1) + 1
end

local function getAreaHeight()
	return (AREA_Y2 - AREA_Y1) + 1
end

local function getWorldAgeMinutes()
	local gameTime = getGameTime and getGameTime()
	if gameTime and gameTime.getWorldAgeHours then
		return math.floor(gameTime:getWorldAgeHours() * 60)
	end
	return 0
end

local function isInsideArea(x, y, z)
	if z ~= AREA_Z then return false end
	return x >= AREA_X1 and x <= AREA_X2 and y >= AREA_Y1 and y <= AREA_Y2
end

local function collectPlayersInArea()
	local playersInArea = {}
	local onlinePlayers = getOnlinePlayers and getOnlinePlayers()
	if not onlinePlayers then return playersInArea end

	for i = 0, onlinePlayers:size() - 1 do
		local player = onlinePlayers:get(i)
		if player and not player:isDead() then
			local px, py, pz = player:getX(), player:getY(), player:getZ()
			if isInsideArea(px, py, pz) then
				playersInArea[#playersInArea + 1] = {
					player = player,
					x = px,
					y = py,
					z = pz
				}
			end
		end
	end

	return playersInArea
end

local function buildZoneSpawnEntries()
	local entries = {}
	local totalWeight = 0
	local seenOutfits = {}

	local zoneDef = ZombiesZoneDefinition and ZombiesZoneDefinition[ZONE_TYPE]
	if not zoneDef then
		return entries, totalWeight
	end

	local outfitToType = {}
	if ZM_ZombieHandlerServer and ZM_ZombieHandlerServer.ZombieTypes then
		for zombieType, zombieData in pairs(ZM_ZombieHandlerServer.ZombieTypes) do
			if type(zombieData) == "table" and type(zombieData.outfit) == "string" and zombieData.outfit ~= "" then
				outfitToType[zombieData.outfit] = zombieType
			end
		end
	end

	for _, def in pairs(zoneDef) do
		if type(def) == "table" and type(def.name) == "string" and def.name ~= "" then
			if not seenOutfits[def.name] then
				seenOutfits[def.name] = true
				local weight = math.max(1, math.floor(tonumber(def.chance) or 1))
				entries[#entries + 1] = {
					outfit = def.name,
					zombieType = outfitToType[def.name],
					weight = weight
				}
				totalWeight = totalWeight + weight
			end
		end
	end

	return entries, totalWeight
end

local function pickWeightedSpawnEntry(entries, totalWeight)
	if not entries or #entries == 0 or totalWeight <= 0 then return nil end

	local roll = ZombRand(totalWeight) + 1
	local running = 0

	for _, entry in ipairs(entries) do
		running = running + entry.weight
		if roll <= running then
			return entry
		end
	end

	return entries[1]
end

local function scanZonePopulation(playersInArea)
	local zoneCount = 0
	local localCounts = {}
	local radiusSq = AUTO_SPAWN_LOCAL_RADIUS * AUTO_SPAWN_LOCAL_RADIUS

	for i = 1, #playersInArea do
		localCounts[i] = 0
	end

	local cell = getCell and getCell()
	if not cell or not cell.getZombieList then
		return zoneCount, localCounts
	end

	local zombieList = cell:getZombieList()
	if not zombieList then
		return zoneCount, localCounts
	end

	for i = 0, zombieList:size() - 1 do
		local zombie = zombieList:get(i)
		if zombie then
			local zx, zy, zz = zombie:getX(), zombie:getY(), zombie:getZ()
			if isInsideArea(zx, zy, zz) then
				zoneCount = zoneCount + 1
				for pIndex, playerData in ipairs(playersInArea) do
					local dx = zx - playerData.x
					local dy = zy - playerData.y
					if (dx * dx + dy * dy) <= radiusSq then
						localCounts[pIndex] = localCounts[pIndex] + 1
					end
				end
			end
		end
	end

	return zoneCount, localCounts
end

local function trySpawnOneNearPlayer(playerData, entries, totalWeight)
	if not playerData or not entries or #entries == 0 then
		return false
	end

	local cell = getCell and getCell()
	if not cell then return false end

	for _ = 1, AUTO_SPAWN_ATTEMPTS_PER_ZED do
		local angle = ZombRand(0, 360) * math.pi / 180
		local distance = ZombRand(AUTO_SPAWN_MIN_DISTANCE, AUTO_SPAWN_MAX_DISTANCE + 1)
		local x = math.floor(playerData.x + (math.cos(angle) * distance))
		local y = math.floor(playerData.y + (math.sin(angle) * distance))

		if isInsideArea(x, y, AREA_Z) then
			if ZM_ZombieHandlerServer and ZM_ZombieHandlerServer.isPlayerNearby and
				ZM_ZombieHandlerServer.isPlayerNearby(x, y, AREA_Z, AUTO_SPAWN_MIN_DISTANCE) then
				-- Too close to any player, retry another position.
			else
				local square = cell:getGridSquare(x, y, AREA_Z)
				if square then
					local entry = pickWeightedSpawnEntry(entries, totalWeight)
					if entry then
						if entry.zombieType and ZM_ZombieHandlerServer and ZM_ZombieHandlerServer.createZombie then
							local zombie = ZM_ZombieHandlerServer.createZombie(square, entry.zombieType)
							if zombie then return true end
						else
							local zombieList = addZombiesInOutfitArea(x, y, x, y, AREA_Z, 1, entry.outfit, nil)
							if zombieList and zombieList:size() > 0 then
								return true
							end
						end
					end
				end
			end
		end
	end

	return false
end

function ZM_UniformZoneAreaServer.autoSpawnTick()
	if not AUTO_SPAWN_ENABLED then return end

	local nowWorldMinute = getWorldAgeMinutes()
	if nowWorldMinute < (_lastAutoSpawnWorldMinute + AUTO_SPAWN_INTERVAL_MINUTES) then
		return
	end
	_lastAutoSpawnWorldMinute = nowWorldMinute

	local playersInArea = collectPlayersInArea()
	if #playersInArea == 0 then
		return
	end

	local entries, totalWeight = buildZoneSpawnEntries()
	if #entries == 0 or totalWeight <= 0 then
		uniformLog("No spawn entries found for zone type '" .. ZONE_TYPE .. "'.")
		return
	end

	local zoneCount, localCounts = scanZonePopulation(playersInArea)
	local globalBudget = math.min(AUTO_SPAWN_MAX_PER_TICK, math.max(0, AUTO_SPAWN_GLOBAL_CAP - zoneCount))
	if globalBudget <= 0 then
		if AUTO_SPAWN_DEBUG then
			uniformLog("Auto-spawn skipped; zone cap reached (" .. tostring(zoneCount) .. "/" .. tostring(AUTO_SPAWN_GLOBAL_CAP) .. ").")
		end
		return
	end

	local totalSpawned = 0
	for i, playerData in ipairs(playersInArea) do
		if globalBudget <= 0 then break end

		local currentLocal = localCounts[i] or 0
		local deficit = AUTO_SPAWN_TARGET_PER_PLAYER - currentLocal
		if deficit > 0 then
			local playerBudget = math.min(deficit, AUTO_SPAWN_MAX_PER_PLAYER_PER_TICK, globalBudget)
			local playerSpawned = 0

			for _ = 1, playerBudget do
				if trySpawnOneNearPlayer(playerData, entries, totalWeight) then
					playerSpawned = playerSpawned + 1
					totalSpawned = totalSpawned + 1
					globalBudget = globalBudget - 1
					if globalBudget <= 0 then break end
				end
			end

			if AUTO_SPAWN_DEBUG and playerSpawned > 0 then
				uniformLog("Spawned " .. tostring(playerSpawned) .. " near " .. tostring(playerData.player:getUsername()) ..
					" (local was " .. tostring(currentLocal) .. ").")
			end
		end
	end

	if totalSpawned > 0 then
		uniformLog("Auto-spawned " .. tostring(totalSpawned) .. " zombie(s); zone population before tick was " .. tostring(zoneCount) .. ".")
	end
end

-- Manual hook for server console testing: runs a single throttled-safe tick now.
function ZM_UniformZoneAreaServer.debugRunAutoSpawnNow()
	_lastAutoSpawnWorldMinute = -99999999
	ZM_UniformZoneAreaServer.autoSpawnTick()
end

function ZM_UniformZoneAreaServer.registerUniformAreaZone()
	local world = getWorld and getWorld()
	if not world then
		uniformLog("World is not ready; zone registration skipped.")
		return
	end

	local width = getAreaWidth()
	local height = getAreaHeight()
	if width <= 0 or height <= 0 then
		uniformLog("Invalid area size; zone registration skipped.")
		return
	end

	-- Try duplicate detection, but keep it non-fatal because some Java methods
	-- can be unavailable depending on build/binding.
	local existing = nil
	local okExisting, existingOrErr = pcall(function()
		local metaGrid = world:getMetaGrid()
		if not metaGrid then return nil end
		return metaGrid:getZoneWithBoundsAndType(AREA_X1, AREA_Y1, AREA_Z, width, height, ZONE_TYPE)
	end)
	if okExisting then
		existing = existingOrErr
	elseif AUTO_SPAWN_DEBUG then
		uniformLog("Existing-zone lookup skipped: " .. tostring(existingOrErr))
	end

	if existing then
		uniformLog("Existing zone found; skipping duplicate registration.")
		return
	end

	-- Preferred API from current Java docs: IsoWorld.registerZone(...)
	local zone = nil
	local worldErr = nil
	local okWorldRegister, worldRegisterResult = pcall(function()
		return world:registerZone(ZONE_NAME, ZONE_TYPE, AREA_X1, AREA_Y1, AREA_Z, width, height)
	end)
	if okWorldRegister then
		zone = worldRegisterResult
	else
		worldErr = worldRegisterResult
	end

	-- Fallback to IsoMetaGrid.registerZone(...) if needed.
	if not zone then
		local okMetaRegister, metaRegisterResult = pcall(function()
			local metaGrid = world:getMetaGrid()
			if not metaGrid then return nil end
			return metaGrid:registerZone(ZONE_NAME, ZONE_TYPE, AREA_X1, AREA_Y1, AREA_Z, width, height)
		end)
		if okMetaRegister then
			zone = metaRegisterResult
		elseif AUTO_SPAWN_DEBUG then
			uniformLog("MetaGrid register fallback failed: " .. tostring(metaRegisterResult))
		end
	end

	if zone ~= nil then
		uniformLog("Registered zone '" .. ZONE_NAME .. "' type '" .. ZONE_TYPE ..
			"' at (" .. AREA_X1 .. "," .. AREA_Y1 .. "," .. AREA_Z .. ") size " .. width .. "x" .. height .. ".")
	else
		uniformLog("Failed to register zone '" .. ZONE_NAME .. "'. worldErr=" .. tostring(worldErr))
	end
end

function ZM_UniformZoneAreaServer.spawnAllDefinedUniformsNow(zLevel, countPerOutfit)
	local entries, totalWeight = buildZoneSpawnEntries()
	if #entries == 0 or totalWeight <= 0 then
		uniformLog("No outfits found in ZombiesZoneDefinition['" .. ZONE_TYPE .. "'].")
		return 0
	end

	local z = math.floor(zLevel or AREA_Z)
	local perOutfit = math.max(1, math.floor(countPerOutfit or 1))
	local spawned = 0

	for _, entry in ipairs(entries) do
		for _ = 1, perOutfit do
			local x = ZombRand(AREA_X1, AREA_X2 + 1)
			local y = ZombRand(AREA_Y1, AREA_Y2 + 1)
			local square = getCell() and getCell():getGridSquare(x, y, z)
			if square then
				if entry.zombieType and ZM_ZombieHandlerServer and ZM_ZombieHandlerServer.createZombie then
					local zombie = ZM_ZombieHandlerServer.createZombie(square, entry.zombieType)
					if zombie then
						spawned = spawned + 1
					end
				else
					local zombieList = addZombiesInOutfitArea(x, y, x, y, z, 1, entry.outfit, nil)
					if zombieList and zombieList:size() > 0 then
						spawned = spawned + zombieList:size()
					end
				end
			end
		end
	end

	uniformLog("Spawned " .. spawned .. " zombie(s) from " .. #entries ..
		" outfit(s) in the custom rectangle area.")
	return spawned
end

if Events and Events.OnLoadMapZones then
	Events.OnLoadMapZones.Add(ZM_UniformZoneAreaServer.registerUniformAreaZone)
else
	uniformLog("Events.OnLoadMapZones is unavailable; zone registration disabled.")
end

-- Correct event name per Lua docs: EveryTenMinutes (no 'On' prefix).
if Events and Events.EveryTenMinutes then
	Events.EveryTenMinutes.Add(ZM_UniformZoneAreaServer.autoSpawnTick)
else
	uniformLog("Events.EveryTenMinutes is unavailable; auto-spawn disabled.")
end

return ZM_UniformZoneAreaServer
