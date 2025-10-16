-- ZM_StageOne.lua
-- Death Forest Stage 1 Area Management

ZM_StageOne = ZM_StageOne or {}

-- Stage 1 area coordinates based on the provided image
local STAGE_ONE_AREA = {
    minX = 19614,
    maxX = 19627,
    minY = 15747,
    maxY = 15765,
    z = 0 -- Ground level
}

-- Function to check if coordinates are within Stage 1 area
function ZM_StageOne.isInStageOneArea(x, y, z)
    z = z or 0
    return x >= STAGE_ONE_AREA.minX and x <= STAGE_ONE_AREA.maxX and
           y >= STAGE_ONE_AREA.minY and y <= STAGE_ONE_AREA.maxY and
           z == STAGE_ONE_AREA.z
end

-- Function to check if an item is food
local function isFood(item)
    if not item then return false end

    -- 1) Class check (best signal)
    if instanceof and instanceof(item, "Food") then
        return true
    end

    -- 2) Script type check (authoritative in item scripts)
    local si = item.getScriptItem and item:getScriptItem() or nil
    if si then
        -- Some builds expose getTypeString(); others need tostring(getType()).
        if (si.getTypeString and si:getTypeString() == "Food")
            or (si.getType and tostring(si:getType()) == "Food") then
            return true
        end
    end

    -- 3) Fallback: raw category (NOT display category; display can be localized/overridden)
    if item.getCategory and item:getCategory() == "Food" then
        return true
    end

    -- Do NOT rely on displayCategory, hunger change, or name prefixes:
    -- - displayCategory is localized / mod-defined
    -- - hunger change can be 0 or positive (uncooked, rotten, etc.)
    -- - name prefixes break on mod items
    return false
end


-- Function to scan all food items in Stage 1 area
function ZM_StageOne.scanFoodInArea()
    print("[ZM_StageOne] Starting food scan in Stage 1 area...")
    print(string.format("[ZM_StageOne] Area: X=%d-%d, Y=%d-%d, Z=%d",
        STAGE_ONE_AREA.minX, STAGE_ONE_AREA.maxX,
        STAGE_ONE_AREA.minY, STAGE_ONE_AREA.maxY,
        STAGE_ONE_AREA.z))

    local cell = getCell()
    if not cell then
        print("[ZM_StageOne] ERROR: Could not get cell")
        return {}
    end

    local foodItems = {}
    local totalItems, foodCount = 0, 0
    local squaresScanned, squaresWithItems, containersFound = 0, 0, 0

    local function addFood(item, x, y, z, src)
        -- Safe stats (only exist on Food in many builds)
        local hunger  = item.getHungChange and item:getHungChange() or nil
        local carbs   = item.getCarbohydrates and item:getCarbohydrates() or nil
        local protein = item.getProteins and item:getProteins() or nil
        local fat     = item.getLipids and item:getLipids() or nil

        table.insert(foodItems, {
            item        = item,
            x           = x, y = y, z = z,
            source      = src, -- e.g. "Ground", "Fridge", "Corpse", etc.
            type        = (item.getFullType and item:getFullType()) or "UNKNOWN",
            displayName = (item.getDisplayName and item:getDisplayName()) or "UNKNOWN",
            hunger      = hunger, carbs = carbs, protein = protein, fat = fat
        })
        foodCount = foodCount + 1
    end

    -- Helper: process an ItemContainer
    local function scanContainer(container, obj, x, y)
        if not container then return end
        containersFound = containersFound + 1

        local cname = (container.getType and container:getType()) or
                      (obj and obj.getObjectName and obj:getObjectName()) or
                      (obj and obj.getSprite and obj:getSprite() and obj:getSprite():getName()) or
                      "Container"

        local items = container.getItems and container:getItems()
        if items and items:size() > 0 then
            for j = 0, items:size() - 1 do
                local it = items:get(j)
                if it then
                    totalItems = totalItems + 1
                    if isFood(it) then
                        print(string.format("[ZM_StageOne] ✓ FOOD in %s: %s", cname,
                            (it.getDisplayName and it:getDisplayName()) or "UNKNOWN"))
                        addFood(it, x, y, STAGE_ONE_AREA.z, cname)
                    end
                end
            end
            return true
        end
        return false
    end

    for x = STAGE_ONE_AREA.minX, STAGE_ONE_AREA.maxX do
        for y = STAGE_ONE_AREA.minY, STAGE_ONE_AREA.maxY do
            local square = cell:getGridSquare(x, y, STAGE_ONE_AREA.z)
            squaresScanned = squaresScanned + 1
            local hadItemsHere = false

            if square then
                -- 1) Ground loot (IsoWorldInventoryObject)
                local worldObjs = square.getWorldObjects and square:getWorldObjects()
                if worldObjs and worldObjs:size() > 0 then
                    for i = 0, worldObjs:size() - 1 do
                        local wobj = worldObjs:get(i)
                        if wobj and wobj.getItem then
                            local it = wobj:getItem()
                            if it then
                                hadItemsHere = true
                                totalItems = totalItems + 1
                                if isFood(it) then
                                    print(string.format("[ZM_StageOne] ✓ FOOD on ground: %s",
                                        (it.getDisplayName and it:getDisplayName()) or "UNKNOWN"))
                                    addFood(it, x, y, STAGE_ONE_AREA.z, "Ground")
                                end
                            end
                        end
                    end
                end

                -- 2) Furniture / world objects with containers (multi-container safe)
                local objs = square.getObjects and square:getObjects()
                if objs and objs:size() > 0 then
                    for i = 0, objs:size() - 1 do
                        local obj = objs:get(i)
                        if obj then
                            local ccount = obj.getContainerCount and obj:getContainerCount() or 0
                            if ccount > 0 then
                                for ci = 0, ccount - 1 do
                                    if scanContainer(obj:getContainerByIndex(ci), obj, x, y) then
                                        hadItemsHere = true
                                    end
                                end
                            else
                                -- Fallback for objects exposing only getContainer()
                                if obj.getContainer then
                                    if scanContainer(obj:getContainer(), obj, x, y) then
                                        hadItemsHere = true
                                    end
                                end
                            end
                        end
                    end
                end

                -- 3) Corpses (IsoDeadBody has an ItemContainer)
                local movers = square.getStaticMovingObjects and square:getStaticMovingObjects()
                if movers and movers:size() > 0 then
                    for i = 0, movers:size() - 1 do
                        local m = movers:get(i)
                        if m and instanceof and instanceof(m, "IsoDeadBody") then
                            local cont = m.getContainer and m:getContainer()
                            if scanContainer(cont, m, x, y) then
                                hadItemsHere = true
                            end
                        end
                    end
                end

                if hadItemsHere then
                    squaresWithItems = squaresWithItems + 1
                end
            else
                -- Square not streamed; normal in PZ unless a player is near
                -- print(string.format("[ZM_StageOne] Unloaded square (%d,%d,%d)", x, y, STAGE_ONE_AREA.z))
            end
        end
    end

    print("[ZM_StageOne] ===== SCAN SUMMARY =====")
    print(string.format("[ZM_StageOne] Squares scanned: %d", squaresScanned))
    print(string.format("[ZM_StageOne] Squares with items: %d", squaresWithItems))
    print(string.format("[ZM_StageOne] Containers found: %d", containersFound))
    print(string.format("[ZM_StageOne] Total items inspected: %d", totalItems))
    print(string.format("[ZM_StageOne] Food items found: %d", foodCount))
    print("[ZM_StageOne] ========================")

    return foodItems
end

-- Function to check if there are at least 100 food items in Stage 1 area
function ZM_StageOne.hasEnoughFood()
    local foodItems = ZM_StageOne.scanFoodInArea()
    return #foodItems >= 100
end

-- Function to print detailed food report
function ZM_StageOne.printFoodReport()
    local foodItems = ZM_StageOne.scanFoodInArea()

    if #foodItems == 0 then
        print("[ZM_StageOne] No food items found in Stage 1 area")
        return
    end

    print(string.format("[ZM_StageOne] ===== FOOD REPORT FOR STAGE 1 AREA (%d items) =====", #foodItems))

    for i, foodData in ipairs(foodItems) do
        local location = string.format("(%d, %d, %d)", foodData.x, foodData.y, foodData.z)
        local container = foodData.container and (" in " .. foodData.container) or " on ground"
        local nutrition = string.format("H:%.1f C:%.1f P:%.1f F:%.1f",
            foodData.hunger, foodData.carbs, foodData.protein, foodData.fat)

        print(string.format("[ZM_StageOne] %d. %s (%s) at %s%s - %s",
            i, foodData.displayName, foodData.type, location, container, nutrition))
    end

    print("[ZM_StageOne] ===== END FOOD REPORT =====")
end


-- Debug function to check player position
function ZM_StageOne.checkPlayerPosition()
    local player = getPlayer()
    if not player then
        print("[ZM_StageOne] No player found")
        return
    end

    local square = player:getSquare()
    if not square then
        print("[ZM_StageOne] No player square found")
        return
    end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local inArea = ZM_StageOne.isInStageOneArea(x, y, z)

    print(string.format("[ZM_StageOne] Player position: (%d, %d, %d)", x, y, z))
    print(string.format("[ZM_StageOne] Stage 1 area: X=%d-%d, Y=%d-%d, Z=%d",
        STAGE_ONE_AREA.minX, STAGE_ONE_AREA.maxX,
        STAGE_ONE_AREA.minY, STAGE_ONE_AREA.maxY,
        STAGE_ONE_AREA.z))
    print(string.format("[ZM_StageOne] Player in Stage 1 area: %s", inArea and "YES" or "NO"))

    if not inArea then
        local distX = math.min(math.abs(x - STAGE_ONE_AREA.minX), math.abs(x - STAGE_ONE_AREA.maxX))
        local distY = math.min(math.abs(y - STAGE_ONE_AREA.minY), math.abs(y - STAGE_ONE_AREA.maxY))
        print(string.format("[ZM_StageOne] Distance to area: X=%d, Y=%d", distX, distY))
    end
end

-- Test function to scan just around player
function ZM_StageOne.scanAroundPlayer(radius)
    radius = radius or 5
    local player = getPlayer()
    if not player then
        print("[ZM_StageOne] No player found")
        return
    end

    local square = player:getSquare()
    if not square then
        print("[ZM_StageOne] No player square found")
        return
    end

    local px, py, pz = square:getX(), square:getY(), square:getZ()
    local cell = getCell()
    local itemsFound = 0
    local foodFound = 0

    print(string.format("[ZM_StageOne] Scanning %dx%d area around player at (%d, %d, %d)",
        radius*2+1, radius*2+1, px, py, pz))

    for x = px - radius, px + radius do
        for y = py - radius, py + radius do
            local sq = cell:getGridSquare(x, y, pz)
            if sq then
                -- Check ground items
                local worldItems = sq:getWorldObjects()
                if worldItems and worldItems:size() > 0 then
                    for i = 0, worldItems:size() - 1 do
                        local worldItem = worldItems:get(i)
                        if worldItem and worldItem:getItem() then
                            local item = worldItem:getItem()
                            itemsFound = itemsFound + 1
                            print(string.format("[ZM_StageOne] Item at (%d, %d): %s (category: %s)",
                                x, y, item:getDisplayName(), item:getDisplayCategory() or "nil"))
                            if isFood(item) then
                                foodFound = foodFound + 1
                                print(string.format("[ZM_StageOne] ✓ FOOD: %s", item:getDisplayName()))
                            end
                        end
                    end
                end

                -- Check containers
                local objects = sq:getObjects()
                if objects then
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj and obj:getContainer() then
                            local container = obj:getContainer()
                            local items = container:getItems()
                            if items and items:size() > 0 then
                                print(string.format("[ZM_StageOne] Container at (%d, %d): %s with %d items",
                                    x, y, obj:getObjectName() or "Unknown", items:size()))
                                for j = 0, items:size() - 1 do
                                    local item = items:get(j)
                                    if item then
                                        itemsFound = itemsFound + 1
                                        print(string.format("[ZM_StageOne] Container item: %s (category: %s)",
                                            item:getDisplayName(), item:getDisplayCategory() or "nil"))
                                        if isFood(item) then
                                            foodFound = foodFound + 1
                                            print(string.format("[ZM_StageOne] ✓ FOOD in container: %s", item:getDisplayName()))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    print(string.format("[ZM_StageOne] Scan complete: %d items found, %d food items", itemsFound, foodFound))
end
