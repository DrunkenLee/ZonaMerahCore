require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
if not ZM_MedicalCheck then
    require "ZM_MedicalCheck"
end

-- Import CharacterStat for accessing stats via documented API
local CharacterStat = require "zombie/characters/CharacterStat"

local HZ = nil
if HazardousZones and HazardousZones.Client then
  HZ = HazardousZones.Client
end
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

    -- Server-side full heal button
    -- self.fullHealButton = ISButton:new(10, 10, 80, 20, "Full Heal", self, MedicalDetailUI.onClickFullHeal)
    -- self.fullHealButton:initialise()
    -- self:addChild(self.fullHealButton)

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

    local fullHealResponse = ZM_MedicalCheck and ZM_MedicalCheck.getLastFullHealResponse and ZM_MedicalCheck.getLastFullHealResponse() or nil
    if fullHealResponse then
        local prefix = fullHealResponse.success and "Last Full Heal: SUCCESS" or "Last Full Heal: FAILED"
        self.infoList:addItem(prefix, nil)
        self.infoList:addItem("  " .. tostring(fullHealResponse.message), nil)
        self.infoList:addItem("  " .. tostring(fullHealResponse.timestamp or ""), nil)
        self.infoList:addItem(" ", nil)
    end

    local fullCureResponse = ZM_MedicalCheck and ZM_MedicalCheck.getLastFullCureResponse and ZM_MedicalCheck.getLastFullCureResponse() or nil
    if fullCureResponse then
        local prefix = fullCureResponse.success and "Last Full Cure: SUCCESS" or "Last Full Cure: FAILED"
        self.infoList:addItem(prefix, nil)
        self.infoList:addItem("  " .. tostring(fullCureResponse.message), nil)
        self.infoList:addItem("  " .. tostring(fullCureResponse.timestamp or ""), nil)
        self.infoList:addItem(" ", nil)
    end

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
    local infectionLevel = bodyDamage:getGeneralWoundInfectionLevel() or 0
    local infectionGrowthRate = bodyDamage:getInfectionGrowthRate() or 0
    local infectionTime = bodyDamage:getInfectionTime() or -1
    local infectionMortalityDuration = bodyDamage:getInfectionMortalityDuration() or -1

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

            self.infoList:addItem("    Infected: " .. string.format("%.1f hours", infectedAt), nil)
            self.infoList:addItem("    Estimated time left: " .. string.format("%.1f hours", hoursLeft), nil)
        end
    end

    -- Temperature - use Thermoregulator API
    local tempValue = 37.0
    local thermoregulator = bodyDamage:getThermoregulator()
    if thermoregulator then
        tempValue = 37.0
    end
    -- self.infoList:addItem("  Body Temperature: " .. string.format("%.1f°C", tempValue), nil)

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
    local catchAColdVal = bodyDamage:getCatchACold() or 0

    -- Get cold strength directly (don't use HasACold flag)
    local coldStrength = bodyDamage:getColdStrength() or 0

    -- Only show section if CatchACold > 0 or coldStrength > 0
    if catchAColdVal > 0 or coldStrength > 0 then
        -- Get all cold-related data
        local coldProgressionRate = 0
        local timeToSneezeOrCough, sneezeCoughActive = 0, 0
        local sneezeCoughTime, sneezeCoughDelay = 0, 0

        -- Get cold values
        coldProgressionRate = bodyDamage:getColdProgressionRate() or 0
        timeToSneezeOrCough = bodyDamage:getTimeToSneezeOrCough() or 0
        sneezeCoughActive = bodyDamage:getSneezeCoughActive() or 0
        sneezeCoughTime = bodyDamage:getSneezeCoughTime() or 0
        sneezeCoughDelay = bodyDamage:getSneezeCoughDelay() or 0

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
                self.infoList:addItem("    Sneeze/Cough Delay: " .. sneezeCoughDelay, nil)
            end

            -- Sneeze timer information based on cold severity
            local min, max = 0, 0
            if coldStrength > 50 then
                min = bodyDamage:getNastyColdSneezeTimerMin() or 0
                max = bodyDamage:getNastyColdSneezeTimerMax() or 0
                print(string.rep("-", 40))
                print("Nasty Cold Sneeze Timer Range:")
                print("  Min:", min)
                print("  Max:", max)
                print(string.rep("-", 40))
                if min > 0 or max > 0 then
                    self.infoList:addItem("    Sneeze Timer Range: " .. min .. "-" .. max .. " ticks", nil)
                end
            elseif coldStrength > 20 then
                min = bodyDamage:getColdSneezeTimerMin() or 0
                max = bodyDamage:getColdSneezeTimerMax() or 0
                if min > 0 or max > 0 then
                    self.infoList:addItem("    Sneeze Timer Range: " .. min .. "-" .. max .. " ticks", nil)
                end
            else
                min = bodyDamage:getMildColdSneezeTimerMin() or 0
                max = bodyDamage:getMildColdSneezeTimerMax() or 0
                if min > 0 or max > 0 then
                    self.infoList:addItem("    Sneeze Timer Range: " .. min .. "-" .. max .. " ticks", nil)
                end
            end
        else
            -- Show preventative info if not yet sick
            self.infoList:addItem("    Protection Needed: " .. (catchAColdVal > 25 and "Yes" or "Low Priority"), nil)
        end
    end

    -- Food sickness - use documented CharacterStat API
    local stats = player:getStats()
    local foodSickness =  0
    if foodSickness > 0 then
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

            -- Check for infection using documented API
            local woundInfLevel = part:getWoundInfectionLevel() or 0
            local infectedWound = woundInfLevel > 0
            if infectedWound then table.insert(injuries, "Infected Wound") end

            -- Infection checks - use documented BodyPart methods
            local isZombieInfected = part:IsInfected()
            local isFakeInfected = part:IsFakeInfected()

            if isZombieInfected then table.insert(injuries, "ZOMBIE INFECTION") end
            if isFakeInfected then table.insert(injuries, "Anxiety (False Infection)") end

            -- Check if burn needs washing (if method exists)
            if part.isNeedBurnWash then
                local needBurnWash = part:isNeedBurnWash() or false
                if needBurnWash and part:getBurnTime() > 0 then
                    table.insert(injuries, "Unwashed Burn")
                end
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

                -- Check for splint - use documented API
                local splintFactor = part:getSplintFactor() or 0
                if splintFactor > 0 then
                    self.infoList:addItem("    * Splinted", nil)
                end

                -- Add herb treatment information
                local hasHerbTreatment = false
                local plantainFactor = part:getPlantainFactor() or 0
                local comfreyFactor = part:getComfreyFactor() or 0
                local garlicFactor = part:getGarlicFactor() or 0

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
                local woundInfectionLevel = part:getWoundInfectionLevel() or 0

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
    end
end

function MedicalDetailUI:onClickClose()
    if MedicalDetailUI.instance == self then
        MedicalDetailUI.instance = nil
    end

    self:setVisible(false)
    self:removeFromUIManager()
end

function MedicalDetailUI:onClickFullHeal()
    if ZM_MedicalCheck and ZM_MedicalCheck.requestFullHeal then
        ZM_MedicalCheck.requestFullHeal()
    else
        print("[ZonaMerahCore] Full-heal request function is unavailable on client.")
    end
end

function MedicalDetailUI:onClickFullCure()
    if ZM_MedicalCheck and ZM_MedicalCheck.requestFullCure then
        ZM_MedicalCheck.requestFullCure()
    else
        print("[ZonaMerahCore] Full-cure request function is unavailable on client.")
    end
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

function checkIfCanEnterZone(player)
    if not player then
        CharacterManager.instance:removeFlag("extraction_allow_flag")
        return false
    end

    local playerObj = player
    if not playerObj then
        CharacterManager.instance:removeFlag("extraction_allow_flag")
        return false
    end

    local bodyDamage = playerObj:getBodyDamage()
    local stats = playerObj:getStats()

    print("[Zone Entry Check] Player infection status: " .. tostring(bodyDamage:IsInfected()))
    print("[Zone Entry Check] Player fake infection status: " .. tostring(bodyDamage:IsFakeInfected()))
    print("[Zone Entry Check] Player has a cold: " .. tostring(bodyDamage:isHasACold()))

    -- Use Stats API for food sickness
    local foodSickness = stats and stats:get(CharacterStat.FOOD_SICKNESS) or 0
    print("[Zone Entry Check] Player Food Sickness Level: " .. tostring(foodSickness))

    if foodSickness > 0 then
        CharacterManager.instance:removeFlag("extraction_allow_flag")
        return false
    end

    if bodyDamage:isHasACold() then
        CharacterManager.instance:removeFlag("extraction_allow_flag")
        return false
    end

    if bodyDamage:IsFakeInfected() then
        CharacterManager.instance:removeFlag("extraction_allow_flag")
        return false
    end

    if bodyDamage:IsInfected() then
        CharacterManager.instance:removeFlag("extraction_allow_flag")
        return false
    end

    -- Check bitten
    local bodyParts = bodyDamage:getBodyParts()
    for i = 0, bodyParts:size() - 1 do
        local part = bodyParts:get(i)
        if part and part:getBiteTime() > 0 then
            CharacterManager.instance:removeFlag("extraction_allow_flag")
            return false
        end
    end

    -- Check rad and bhx
    local rad, bhx = 0, 0
    if HZ and HZ.getPlayerExposures then
        local exposures = HZ:getPlayerExposures()
        if exposures then
            rad = exposures.radiation or 0
            bhx = exposures.biological or 0
        end
    end

    if rad > 1 or bhx > 1 then
        CharacterManager.instance:removeFlag("extraction_allow_flag")
        return false
    end

    CharacterManager.instance:addFlag("extraction_allow_flag")
    return true
end

if HZ then
    function HZ:setPlayerRadiation(value)
        if not self or not self.getPlayerExposures then return end
        local exposures = self:getPlayerExposures()
        if exposures then
            exposures.radiation = value
        end
    end

    function HZ:setPlayerBiological(value)
        if not self or not self.getPlayerExposures then return end
        local exposures = self:getPlayerExposures()
        if exposures then
            exposures.biological = value
        end
    end
end

function showMedicalDetailUI(player)
    player = player or getPlayer()
    if not player then return end

    local ui = MedicalDetailUI:new(100, 100, 400, 600, player)
    MedicalDetailUI.instance = ui
    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)
    return ui
end

if not _G.checkMedical then
    _G.checkMedical = showMedicalDetailUI
end

local function onMedicalDetailServerCommand(module, command, args)
    if module ~= "ZonaMerahCore" then return end
    args = args or {}

    if command == "FullHealResponse" then
        -- Keep UI state in sync even if this handler runs before ZM_MedicalCheck's listener.
        if ZM_MedicalCheck then
            ZM_MedicalCheck.lastFullHealResponse = {
                success = args.success == true,
                message = args.message or "",
                timestamp = os.date("%Y-%m-%d %H:%M:%S")
            }
        end
    elseif command == "FullCureResponse" then
        if ZM_MedicalCheck then
            ZM_MedicalCheck.lastFullCureResponse = {
                success = args.success == true,
                message = args.message or "",
                timestamp = os.date("%Y-%m-%d %H:%M:%S")
            }
        end
    else
        return
    end

    if MedicalDetailUI.instance and MedicalDetailUI.instance.populateMedicalData then
        MedicalDetailUI.instance:populateMedicalData()
    end
end

Events.OnServerCommand.Add(onMedicalDetailServerCommand)

-- Events.OnKeyPressed.Add(onCustomUIKeyPressed)
