ZMPlayerInventoryHandler = ZMPlayerInventoryHandler or {};


local randomWeaponToGive = {
  "Base.CanoePadelX2",
  "Base.CanoePadel",
  "Base.Broad_Axe",
  "Base.CH_WarSword",
  "Base.Conan_Sword",
  "Base.FirePlace_Poker_B",
  "Base.GardenFork",
  "Base.GardenHoe",
  "Base.Golfclub",
  "Base.HockeyStick",
  "Base.IceHockeyStick",
  "Base.KillBill",
  "Base.LaCrosseStick",
  "Base.PickAxe",
  "Base.Shovel",
  "Base.Spartan_Spear_Thrust",
  "Base.PickAxeHandleSpiked",
}

local itemToEquip = {
  "Base.ScrapVestStudded",
  "Base.Hat_ScrapHelmet",
  "Base.ScrapPauldrons2",
  "Base.ScrapKilt",
  "Base.ScrapShinPlate2R",
  "Base.ScrapShinPlate2L",
  "Base.ScrapLegPadR",
  "Base.ScrapLegPadBoltsL",
  "Base.ScrapShoulderPadR",
  "Base.ScrapShoulderPadL",
  "Base.Shoes_ArmyBoots",
  "Base.Jacket_Fireman",
  "Base.Trousers_Fireman"
}

function ZMPlayerInventoryHandler.StripPlayerInventory(playerObj)
    local playerInventory = playerObj:getInventory()
    local items = playerInventory:getItems()
    if playerObj.getWornItems then
        local wornItems = playerObj:getWornItems()
        for i = wornItems:size() - 1, 0, -1 do
            local worn = wornItems:get(i)
            playerObj:removeWornItem(worn:getItem())
        end
    end
    if playerObj:getPrimaryHandItem() then
        playerObj:setPrimaryHandItem(nil)
    end
    if playerObj:getSecondaryHandItem() then
        playerObj:setSecondaryHandItem(nil)
    end

    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        playerInventory:DoRemoveItem(item)
    end
    playerObj:resetModel()
end

function ZMPlayerInventoryHandler.GivePlayerEquipment(playerObj)
  local playerInventory = playerObj:getInventory()
  for _, itemFullName in ipairs(itemToEquip) do
      local item = playerInventory:AddItem(itemFullName)
      if item and item:getBodyLocation() then
          playerObj:setWornItem(item:getBodyLocation(), item)
      end
  end
  playerObj:resetModel()
end

function ZMPlayerInventoryHandler.GiveRandomWeapon(playerObj)
  if #randomWeaponToGive == 0 then return end
  local randomIndex = ZombRand(#randomWeaponToGive) + 1
  local itemFullName = randomWeaponToGive[randomIndex]
  local playerInventory = playerObj:getInventory()
  playerInventory:AddItem(itemFullName)
end


return ZMPlayerInventoryHandler