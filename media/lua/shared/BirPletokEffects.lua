-- Special effects for Bir Pletok
function OnEat_BirPletok(food, character, percentage)
    if not character then return end

    -- Special effects for traditional Indonesian beer
    local bodyDamage = character:getBodyDamage()
    local stats = character:getStats()

    -- Warming effect (ginger in the recipe)
    local currentTemp = bodyDamage:getTemperature()
    if currentTemp < 37.0 then
        bodyDamage:setTemperature(math.min(37.0, currentTemp + 0.5))
    end

    -- Slight health boost (traditional herbs)
    if bodyDamage:getOverallBodyHealth() < 85 then
        bodyDamage:AddDamage(BodyPartType.Torso, -2.0) -- Heal 2 points
    end

    -- Energy boost from spices
    stats:setEndurance(math.min(1.0, stats:getEndurance() + 0.1))

    -- Special message
    local messages = {
        "The warm spices of Bir Pletok make you feel energized.",
        "The traditional Indonesian beer warms your body.",
        "You feel the ginger and lemongrass working their magic.",
        "The palm sugar gives you a gentle energy boost."
    }

    local randomMessage = messages[ZombRand(#messages) + 1]
    character:Say(randomMessage)

    -- Small chance for mood boost
    if ZombRand(100) < 30 then -- 30% chance
        bodyDamage:setBoredomLevel(math.max(0, bodyDamage:getBoredomLevel() - 5))
        character:Say("This reminds you of home...")
    end
end
