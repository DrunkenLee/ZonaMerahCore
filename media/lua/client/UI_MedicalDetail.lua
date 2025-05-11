require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
local HZ = HazardousZones.Client
-- Simple UI for Medical Information Display
MedicalDetailUI = ISPanel:derive("MedicalDetailUI")

function MedicalDetailUI:initialise()
    ISPanel.initialise(self)
    self:createChildren()
end

function MedicalDetailUI:createChildren()
    -- Title
    self.titleLabel = ISLabel:new(self.width/2 - 100, 10, 25, "Medical Status Report", 1, 1, 1, 1, UIFont.Medium, true)
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    -- Close button
    self.closeButton = ISButton:new(self.width - 60, 10, 50, 20, "Close", self, MedicalDetailUI.onClickClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- Create scrolling list for medical information
    self.infoList = ISScrollingListBox:new(10, 40, self.width - 20, self.height - 50)
    self.infoList:initialise()
    self.infoList:setFont(UIFont.Small, 3)
    self.infoList.drawBorder = true
    self.infoList.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
    self:addChild(self.infoList)

    -- Fill data
    self:populateMedicalData()
end

function MedicalDetailUI:populateMedicalData()
    local player = self.player
    if not player then return end

    local bodyDamage = player:getBodyDamage()
    self.infoList:clear()

    -- Section: Overall Health
    self.infoList:addItem("--- OVERALL HEALTH ---", nil)

    -- Confirm these fields exist in the data dump
    local overallHealth = bodyDamage:getOverallBodyHealth()
    if overallHealth then
        self.infoList:addItem("  Health: " .. string.format("%.1f%%", overallHealth), nil)
    end

    -- Infection status - confirmed to exist in data dump
    local infectionStatus = "None"
    if bodyDamage:IsInfected() then
        infectionStatus = "INFECTED (Red Strain)"
    elseif bodyDamage:IsFakeInfected() then
        infectionStatus = "Possible Infection"
    end
    self.infoList:addItem("  Infection: " .. infectionStatus, nil)

    -- Add detailed infection data if available
    local success = false

    -- Try to get infection data using pcall to avoid errors
    local infectionLevel, infectionGrowthRate, infectionTime, infectionMortalityDuration = 0, 0, -1, -1

    success = pcall(function() infectionLevel = bodyDamage:getInfectionLevel() end)
    if not success then pcall(function() infectionLevel = bodyDamage.InfectionLevel end) end

    success = pcall(function() infectionGrowthRate = bodyDamage:getInfectionGrowthRate() end)
    if not success then pcall(function() infectionGrowthRate = bodyDamage.InfectionGrowthRate end) end

    success = pcall(function() infectionTime = bodyDamage:getInfectionTime() end)
    if not success then pcall(function() infectionTime = bodyDamage.InfectionTime end) end

    success = pcall(function() infectionMortalityDuration = bodyDamage:getInfectionMortalityDuration() end)
    if not success then pcall(function() infectionMortalityDuration = bodyDamage.InfectionMortalityDuration end) end

    if bodyDamage:IsInfected() or infectionLevel > 0 or infectionTime > 0 then
        self.infoList:addItem("  --- Infection Details ---", nil)

        -- Format the infection level as percentage
        self.infoList:addItem("    Infection Level: " .. string.format("%.2f%%", infectionLevel * 100), nil)

        -- Format the growth rate
        self.infoList:addItem("    Progression Rate: " .. string.format("%.4f%%/hr", infectionGrowthRate * 100 * 60), nil)

        -- Calculate approximate time left if infected
        if infectionTime > 0 and infectionMortalityDuration > 0 then
            local gameTimeHours = getGameTime():getWorldAgeHours()
            local infectedAt = gameTimeHours - infectionTime
            local totalDuration = infectionMortalityDuration
            local hoursLeft = math.max(0, totalDuration - infectedAt)

            self.infoList:addItem("    Infected for: " .. string.format("%.1f hours", infectedAt), nil)
            self.infoList:addItem("    Estimated time left: " .. string.format("%.1f hours", hoursLeft), nil)
        end
    end

    -- Temperature - confirmed to exist
    self.infoList:addItem("  Body Temperature: " .. string.format("%.1f°C", bodyDamage:getTemperature()), nil)

    -- Add Hazardous Zones data (rad and bhx)
    local rad, bhx = 0, 0
    if HZ and HZ.getPlayerExposures then
        local exposures = HZ:getPlayerExposures()
        if exposures then
            rad = exposures.radiation or 0
            bhx = exposures.biological or 0
        end
    end
    self.infoList:addItem("  Radiation (rad): " .. tostring(rad), nil)
    self.infoList:addItem("  Biological Hazard (bhx): " .. tostring(bhx), nil)

    -- Cold information - use CatchACold and ColdStrength only
    local catchAColdVal = 0
    success = pcall(function() catchAColdVal = bodyDamage:getCatchACold() end)
    if not success then
        pcall(function() catchAColdVal = bodyDamage.CatchACold end)
    end

    -- Get cold strength directly (don't use HasACold flag)
    local coldStrength = 0
    pcall(function() coldStrength = bodyDamage:getColdStrength() end)
    if not success then
        pcall(function() coldStrength = bodyDamage.ColdStrength end)
    end

    -- Only show section if CatchACold > 0 or coldStrength > 0
    if catchAColdVal > 0 or coldStrength > 0 then
        -- Get all cold-related data
        local coldProgressionRate = 0
        local timeToSneezeOrCough, sneezeCoughActive = 0, 0
        local sneezeCoughTime, sneezeCoughDelay = 0, 0

        -- Safely get values with pcall
        pcall(function() coldProgressionRate = bodyDamage.ColdProgressionRate or 0 end)
        pcall(function() timeToSneezeOrCough = bodyDamage.TimeToSneezeOrCough or 0 end)
        pcall(function() sneezeCoughActive = bodyDamage.SneezeCouchActive or 0 end)
        pcall(function() sneezeCoughTime = bodyDamage.SneezeCoughTime or 0 end)
        pcall(function() sneezeCoughDelay = bodyDamage.SneezeCoughDelay or 0 end)

        -- Display cold info based on coldStrength and catchAColdVal
        if coldStrength > 0 then
            -- Determine severity based on coldStrength
            local severity = "Mild"
            if coldStrength > 50 then
                severity = "Severe"
            elseif coldStrength > 20 then
                severity = "Moderate"
            end
            self.infoList:addItem("  Cold: " .. severity, nil)
        else
            -- Player at risk of catching cold
            local riskLevel = "Low"
            if catchAColdVal > 75 then
                riskLevel = "Very High"
            elseif catchAColdVal > 50 then
                riskLevel = "High"
            elseif catchAColdVal > 25 then
                riskLevel = "Moderate"
            elseif catchAColdVal > 10 then
                riskLevel = "Slight"
            end
            self.infoList:addItem("  Cold Risk: " .. riskLevel, nil)
        end

        -- Add detailed cold section
        self.infoList:addItem("  --- Cold Details ---", nil)
        self.infoList:addItem("    CatchACold Value: " .. string.format("%.2f%%", catchAColdVal * 100), nil)

        if coldStrength > 0 then
            self.infoList:addItem("    Strength: " .. string.format("%.1f%%", coldStrength), nil)
            self.infoList:addItem("    Progression Rate: " .. string.format("%.4f%%/hr", coldProgressionRate * 100 * 60), nil)

            -- Display sneeze/cough information
            if timeToSneezeOrCough > 0 then
                self.infoList:addItem("    Time to Next Sneeze/Cough: " .. math.floor(timeToSneezeOrCough / 60) .. ":" ..
                                     string.format("%02d", timeToSneezeOrCough % 60), nil)
            end

            if sneezeCoughActive > 0 then
                self.infoList:addItem("    Currently Sneezing/Coughing: Yes", nil)
                self.infoList:addItem("    Sneeze/Cough Time Left: " .. sneezeCoughTime, nil)
                self.infoList:addItem("    Sneeze/Cough Delay: " .. sneezeCouchDelay, nil)
            end

            -- HAZARDOUS ZONES
            local rad = 0
            local bhx = 0
            local expData = HZ:getExpData()

            rad = expData.radiation or 0
            bhx = expData.biological or 0

            -- Only try to access timer values if coldStrength > 0
            local min, max = 0, 0
            if coldStrength > 50 then
                pcall(function() min = bodyDamage.NastyColdSneezeTimerMin or 0 end)
                pcall(function() max = bodyDamage.NastyColdSneezeTimerMax or 0 end)
                print(string.rep("-", 40))
                print("Nasty Cold Sneeze Timer Range:")
                print("  Min:", min)
                print("  Max:", max)
                print(string.rep("-", 40))
                if min > 0 or max > 0 then
                    self.infoList:addItem("    Sneeze Timer Range: " .. min .. "-" .. max .. " ticks", nil)
                end
            elseif coldStrength > 20 then
                pcall(function() min = bodyDamage.ColdSneezeTimerMin or 0 end)
                pcall(function() max = bodyDamage.ColdSneezeTimerMax or 0 end)
                if min > 0 or max > 0 then
                    self.infoList:addItem("    Sneeze Timer Range: " .. min .. "-" .. max .. " ticks", nil)
                end
            else
                pcall(function() min = bodyDamage.MildColdSneezeTimerMin or 0 end)
                pcall(function() max = bodyDamage.MildColdSneezeTimerMax or 0 end)
                if min > 0 or max > 0 then
                    self.infoList:addItem("    Sneeze Timer Range: " .. min .. "-" .. max .. " ticks", nil)
                end
            end
        else
            -- Show preventative info if not yet sick
            self.infoList:addItem("    Protection Needed: " .. (catchAColdVal > 25 and "Yes" or "Low Priority"), nil)
        end
    end

    -- Food sickness - confirmed to exist
    local foodSickness = bodyDamage:getFoodSicknessLevel()
    if foodSickness and foodSickness > 0 then
        self.infoList:addItem("  Food Sickness: " .. string.format("%.0f%%", foodSickness * 100), nil)
    end

    -- Section: Injuries by body part
    self.infoList:addItem(" ", nil) -- Spacer
    self.infoList:addItem("--- INJURIES ---", nil)

    -- Get body parts - confirmed to exist
    local bodyParts = bodyDamage:getBodyParts()
    if not bodyParts then return end

    local hasInjury = false

    -- Iterate through body parts - confirmed to work
    for i = 0, bodyParts:size() - 1 do
        local part = bodyParts:get(i)
        -- Skip invalid parts (rather than using goto)
        if part then
            local partType = part:getType():toString()

            -- Check if this part has any injuries - only use methods confirmed in dump
            local injuries = {}

            -- These methods are confirmed to exist in the dump
            if part:bleeding() then table.insert(injuries, "Bleeding") end
            if part:getBiteTime() > 0 then table.insert(injuries, "Bitten") end
            if part:getScratchTime() > 0 then table.insert(injuries, "Scratched") end
            if part:getCutTime() > 0 then table.insert(injuries, "Laceration") end
            if part:getFractureTime() > 0 then table.insert(injuries, "Fracture") end
            if part:getDeepWoundTime() > 0 then table.insert(injuries, "Deep Wound") end
            if part:haveBullet() then table.insert(injuries, "Bullet Wound") end
            if part:haveGlass() then table.insert(injuries, "Embedded Glass") end
            if part:getBurnTime() > 0 then table.insert(injuries, "Burn") end

            -- Check for infection - use pcall since we're not sure about method name
            local infectedWound = false
            local success = pcall(function()
                infectedWound = part:getWoundInfectionLevel() > 0
            end)
            if not success then
                -- Try alternative method
                success = pcall(function()
                    infectedWound = part.infectedWound or false
                end)
            end
            if infectedWound then table.insert(injuries, "Infected Wound") end

            -- Additional infection checks from data fields
            local isZombieInfected, isFakeInfected = false, false
            local success = true

            if part.IsInfected then
                isZombieInfected = part:IsInfected()
            end

            if part.IsFakeInfected then
                isFakeInfected = part:IsFakeInfected()
            end

            print(tostring(isZombieInfected) .. " ----- " .. tostring(isFakeInfected), part)

            if isZombieInfected then table.insert(injuries, "ZOMBIE INFECTION") end
            if isFakeInfected then table.insert(injuries, "Anxiety (False Infection)") end

            -- Check if burn needs washing
            local needBurnWash = false
            pcall(function() needBurnWash = part.needBurnWash end)
            if needBurnWash and part:getBurnTime() > 0 then
                table.insert(injuries, "Unwashed Burn")
            end

            -- If there are injuries for this part, list them
            if #injuries > 0 then
                hasInjury = true
                self.infoList:addItem("  " .. partType .. ":", nil)

                for _, injury in ipairs(injuries) do
                    self.infoList:addItem("    - " .. injury, nil)
                end

                -- Add treatment info - confirmed to exist
                if part:bandaged() then
                    local bandageLife = part:getBandageLife() or 0
                    local bandageQuality = "Poor"
                    if bandageLife > 0.75 then bandageQuality = "Excellent"
                    elseif bandageLife > 0.5 then bandageQuality = "Good"
                    elseif bandageLife > 0.25 then bandageQuality = "Fair" end

                    self.infoList:addItem("    * Bandaged (" .. bandageQuality .. ")", nil)
                end

                -- Check for splint - confirmed to exist
                local splintFactor = 0
                success = pcall(function()
                    splintFactor = part:getSplintFactor()
                end)
                if success and splintFactor > 0 then
                    self.infoList:addChild("    * Splinted", nil)
                end

                -- Add herb treatment information
                local hasHerbTreatment = false
                local plantainFactor, comfreyFactor, garlicFactor = 0, 0, 0

                pcall(function() plantainFactor = part.plantainFactor or 0 end)
                pcall(function() comfreyFactor = part.comfreyFactor or 0 end)
                pcall(function() garlicFactor = part.garlicFactor or 0 end)

                -- Show herbal treatments if any are applied
                if plantainFactor > 0 or comfreyFactor > 0 or garlicFactor > 0 then
                    self.infoList:addItem("    --- Herbal Treatments ---", nil)
                    hasHerbTreatment = true
                end

                if plantainFactor > 0 then
                    local effectiveness = "Minimal"
                    if plantainFactor > 0.7 then effectiveness = "Strong"
                    elseif plantainFactor > 0.4 then effectiveness = "Moderate" end
                    self.infoList:addItem("    * Plantain Poultice (" .. effectiveness .. ")", nil)
                end

                if comfreyFactor > 0 then
                    local effectiveness = "Minimal"
                    if comfreyFactor > 0.7 then effectiveness = "Strong"
                    elseif comfreyFactor > 0.4 then effectiveness = "Moderate" end
                    self.infoList:addItem("    * Comfrey Poultice (" .. effectiveness .. ")", nil)
                end

                if garlicFactor > 0 then
                    local effectiveness = "Minimal"
                    if garlicFactor > 0.7 then effectiveness = "Strong"
                    elseif garlicFactor > 0.4 then effectiveness = "Moderate" end
                    self.infoList:addItem("    * Wild Garlic (" .. effectiveness .. ")", nil)
                end

                -- Add detailed infection information if present
                local woundInfectionLevel = 0
                pcall(function() woundInfectionLevel = part.woundInfectionLevel or 0 end)

                if woundInfectionLevel > 0 then
                    local severity = "Early Stage"
                    if woundInfectionLevel > 0.7 then severity = "Severe"
                    elseif woundInfectionLevel > 0.4 then severity = "Moderate" end

                    self.infoList:addItem("    --- Wound Infection ---", nil)
                    self.infoList:addItem("    * Infection Level: " ..
                                         string.format("%.1f%%", woundInfectionLevel * 100), nil)
                    self.infoList:addItem("    * Severity: " .. severity, nil)
                end

                -- If no treatments shown, indicate this
                if not part:bandaged() and splintFactor <= 0 and not hasHerbTreatment then
                    self.infoList:addItem("    * No treatment applied", nil)
                end
            end
        end
    end

    if not hasInjury then
        self.infoList:addItem("  No injuries", nil)
    end

    -- Section: Pain Information
    self.infoList:addItem(" ", nil) -- Spacer
    self.infoList:addItem("--- PAIN & DISCOMFORT ---", nil)


    -- Thirst and hunger - these might exist on the stats object
    local stats = player:getStats()
    if stats then
        local thirst = stats:getThirst()
        if thirst and thirst > 0.1 then
            local thirstStatus = "Slight"
            if thirst > 0.8 then thirstStatus = "Severe"
            elseif thirst > 0.5 then thirstStatus = "Moderate" end
            self.infoList:addItem("  Thirst: " .. thirstStatus, nil)
        end

        local hunger = stats:getHunger()
        if hunger and hunger > 0.1 then
            local hungerStatus = "Peckish"
            if hunger > 0.8 then hungerStatus = "Starving"
            elseif hunger > 0.5 then hungerStatus = "Hungry" end
            self.infoList:addItem("  Hunger: " .. hungerStatus, nil)
        end
    end
end

function MedicalDetailUI:onClickClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

function MedicalDetailUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.variableColor = true
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1.0}
    o.width = width
    o.height = height
    o.player = player
    o.moveWithMouse = true
    return o
end

-- Global function to show medical information
function showMedicalDetailUI(player)
    player = player or getPlayer()
    if not player then return end

    local ui = MedicalDetailUI:new(100, 100, 400, 600, player)
    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)
    return ui
end

-- Add to global scope for console access
if not _G.checkMedical then
    _G.checkMedical = showMedicalDetailUI
end

-- Add key binding for medical check
-- local function onCustomUIKeyPressed(key)
--     if key == Keyboard.KEY_J then  -- You can change this to any key you prefer
--         showMedicalDetailUI()
--     end
-- end

Events.OnKeyPressed.Add(onCustomUIKeyPressed)