-- Test script for the new loot system
ZM_LootTest = {}

-- Test function to simulate the new loot logic
function ZM_LootTest.testLootSelection()
    print("=== Testing New Loot Selection Logic ===")

    -- Mock ZombRand function for testing
    local function mockZombRand(min, max)
        return math.random(min, max - 1)
    end

    -- Test data similar to your screamer1 setup
    local testLootTable = {
        {item = "RMWeapons.DarkResin", quantity = 1, chance = 75},
        {item = "RMWeapons.DragonsteelIngot", quantity = 1, chance = 85},
        {item = "RMWeapons.EldritchWood", quantity = 1, chance = 95},
        {item = "RMWeapons.SoulThread", quantity = 1, chance = 100},
        {item = "RMWeapons.BloodGem", quantity = 1, chance = 100},
        {item = "RMWeapons.MythrilEssence", quantity = 1, chance = 100},
        {item = "RMWeapons.AetherCrystal", quantity = 1, chance = 100},
        {item = "RMWeapons.OblivionCore", quantity = 1, chance = 100},
        {item = "RMWeapons.PhoenixFeather", quantity = 1, chance = 100},
        {item = "RMWeapons.CelestialFragment", quantity = 1, chance = 100},
        {item = "RMWeapons.ApocalypseRelic", quantity = 1, chance = 100},
        {item = "RMWeapons.HeartOfRedZone", quantity = 1, chance = 100}
    }

    local maxItems = 2

    print("Input: " .. #testLootTable .. " total items, max items = " .. maxItems)
    print("Items with chances:")
    for i, item in ipairs(testLootTable) do
        print("  " .. i .. ". " .. item.item .. " - " .. item.chance .. "%")
    end

    -- Simulate the selectRandomLoot function
    local function selectRandomLoot(lootTable, maxItems)
        if not lootTable or #lootTable == 0 or maxItems <= 0 then
            return {}
        end

        local availableItems = {}

        -- First, roll chances for all items to see which are available
        for _, lootItem in ipairs(lootTable) do
            local chance = lootItem.chance or 100
            if chance <= 0 then
                -- Skip items with 0% chance
            elseif chance >= 100 then
                -- 100% chance - always available
                availableItems[#availableItems + 1] = lootItem
            else
                -- Roll for chance (1 to 100)
                local roll = mockZombRand(1, 101) -- 1-100 inclusive
                if roll <= chance then
                    availableItems[#availableItems + 1] = lootItem
                end
            end
        end

        print("Available items after chance rolls: " .. #availableItems)

        -- If we have more available items than maxItems, randomly select
        if #availableItems > maxItems then
            local selectedItems = {}
            local tempItems = {}

            -- Copy available items to temp array
            for i, item in ipairs(availableItems) do
                tempItems[i] = item
            end

            -- Randomly select maxItems from available items
            for i = 1, maxItems do
                if #tempItems > 0 then
                    local randomIndex = mockZombRand(1, #tempItems + 1) -- 1 to length inclusive
                    selectedItems[#selectedItems + 1] = tempItems[randomIndex]

                    -- Remove selected item from temp array
                    for j = randomIndex, #tempItems - 1 do
                        tempItems[j] = tempItems[j + 1]
                    end
                    tempItems[#tempItems] = nil
                end
            end

            return selectedItems
        end

        -- Return all available items if we have maxItems or fewer
        return availableItems
    end

    -- Run multiple tests
    for test = 1, 5 do
        print("\n--- Test Run #" .. test .. " ---")
        local result = selectRandomLoot(testLootTable, maxItems)
        print("Selected " .. #result .. " items:")
        for i, item in ipairs(result) do
            print("  " .. i .. ". " .. item.item .. " (qty: " .. item.quantity .. ")")
        end
    end

    print("\n=== Test Complete ===")
end

-- Auto-run test when file is loaded (for debugging)
-- ZM_LootTest.testLootSelection()

return ZM_LootTest