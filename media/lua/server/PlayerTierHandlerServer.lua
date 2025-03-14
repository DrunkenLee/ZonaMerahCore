require "PlayerConfig"
require "PlayerTierHandler"
require "PlayerTitleHandler"

ServerPlayerTierHandler = {}

-- Function to set unlimited endurance for GODLIKE tier and add a trait
function ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
    local tier = PlayerTierHandler.getPlayerTier(player) or "NO_TIER"

    if tier == "Godlike" then
        player:setUnlimitedEndurance(true)
        if not player:HasTrait("Desensitized") then
            player:getTraits():add("Desensitized")
        end
        if player:HasTrait("FearOfBlood") then
            player:getTraits():remove("FearOfBlood")
        end
        if player:HasTrait("Cowardly") then
            player:getTraits():remove("Cowardly")
        end
    elseif tier == "Mythic" then
        player:setUnlimitedEndurance(false)
        if not player:HasTrait("Brave") then
            player:getTraits():add("Brave")
        end

        if not player:HasTrait("Brawler") then
            player:getTraits():add("Brawler")
        end

        if player:HasTrait("Cowardly") then
          player:getTraits():remove("Cowardly")
        end
    elseif tier == "Immortal" then
        player:setUnlimitedEndurance(false)
        if not player:HasTrait("Hunter") then
            player:getTraits():add("Hunter")
        end
        if not player:HasTrait("ThickSkinned") then
            player:getTraits():add("ThickSkinned")
        end
        if not player:HasTrait("LowThirst") then
            player:getTraits():add("LowThirst")
        end
        if not player:HasTrait("LightEater") then
            player:getTraits():add("LightEater")
        end
        if player:HasTrait("ThinSkinned") then
            player:getTraits():remove("ThinSkinned")
        end
        if player:HasTrait("HeartyAppetite") then
            player:getTraits():remove("HeartyAppetite")
        end
        if player:HasTrait("HighThirst") then
            player:getTraits():remove("HighThirst")
        end
    elseif tier == "Legend" then
        player:setUnlimitedEndurance(false)
        if not player:HasTrait("Resilient") then
            player:getTraits():add("Resilient")
        end
    elseif tier == "Newbies" then
        player:setUnlimitedEndurance(false)
    end
end

Events.EveryDays.Add(function()
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        -- local username = player:getUsername()
        if player then
            ServerPlayerTierHandler.setUnlimitedEnduranceAndTrait(player)
        end
    end
end)

return ServerPlayerTierHandler