require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISScrollingListBox"

PlayerTierInfoUI = ISPanel:derive("PlayerTierInfoUI")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function formatNumber(value)
    local numberValue = math.floor(tonumber(value) or 0)
    local sign = ""
    if numberValue < 0 then
        sign = "-"
        numberValue = math.abs(numberValue)
    end

    local result = tostring(numberValue)
    while true do
        local replaced, count = result:gsub("^(%d+)(%d%d%d)", "%1,%2")
        result = replaced
        if count == 0 then
            break
        end
    end
    return sign .. result
end

local function toPercent(value)
    local numberValue = tonumber(value) or 0
    if numberValue < 0 then
        numberValue = 0
    elseif numberValue > 1 then
        numberValue = 1
    end
    return math.floor(numberValue * 100 + 0.5)
end

function PlayerTierInfoUI:new(x, y, width, height, player, progressData)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0.08, g = 0.08, b = 0.1, a = 0.95 }
    o.borderColor = { r = 0.4, g = 0.45, b = 0.5, a = 1.0 }
    o.moveWithMouse = true

    o.player = player
    o.progressData = progressData or {}
    o.daysProgress = 0
    o.killsProgress = 0
    o.lastAutoRefreshAt = 0

    o.padding = 12
    o.daysBarY = 148
    o.killsBarY = 184
    o.listY = 266

    return o
end

function PlayerTierInfoUI:initialise()
    ISPanel.initialise(self)

    local btnWidth = 90
    local btnHeight = 24
    local infoWidth = self.width - (self.padding * 2)
    local textColor = {1, 1, 1, 1}

    self.headerLabel = ISLabel:new(self.padding, 10, FONT_HGT_MEDIUM, "Zona Merah Tier Progress & Benefits", 1, 0, 0, 1, UIFont.Medium, true)
    self:addChild(self.headerLabel)

    self.refreshBtn = ISButton:new(self.width - (btnWidth * 2) - self.padding - 8, 8, btnWidth, btnHeight, "Refresh", self, self.onRefresh)
    self.refreshBtn:initialise()
    self:addChild(self.refreshBtn)

    self.closeBtn = ISButton:new(self.width - btnWidth - self.padding, 8, btnWidth, btnHeight, "Close", self, self.onClose)
    self.closeBtn:initialise()
    self:addChild(self.closeBtn)

    self.playerLabel = ISLabel:new(self.padding, 40, FONT_HGT_SMALL, "", textColor[1], textColor[2], textColor[3], textColor[4], UIFont.Small, true)
    self:addChild(self.playerLabel)

    self.currentTierLabel = ISLabel:new(self.padding, 58, FONT_HGT_SMALL, "", 0.8, 1, 0.8, 1, UIFont.Small, true)
    self:addChild(self.currentTierLabel)

    self.statsLabel = ISLabel:new(self.padding, 76, FONT_HGT_SMALL, "", textColor[1], textColor[2], textColor[3], textColor[4], UIFont.Small, true)
    self:addChild(self.statsLabel)

    self.nextTierLabel = ISLabel:new(self.padding, 96, FONT_HGT_SMALL, "", 0.9, 0.9, 0.6, 1, UIFont.Small, true)
    self:addChild(self.nextTierLabel)

    self.requirementLabel = ISLabel:new(self.padding, 114, FONT_HGT_SMALL, "", textColor[1], textColor[2], textColor[3], textColor[4], UIFont.Small, true)
    self:addChild(self.requirementLabel)

    self.currentBenefitsLabel = ISLabel:new(self.padding, 222, FONT_HGT_SMALL, "", 0.7, 0.95, 1, 1, UIFont.Small, true)
    self:addChild(self.currentBenefitsLabel)

    self.nextBenefitsLabel = ISLabel:new(self.padding, 240, FONT_HGT_SMALL, "", 0.7, 0.95, 1, 1, UIFont.Small, true)
    self:addChild(self.nextBenefitsLabel)

    self.tierTableHeader = ISLabel:new(self.padding, self.listY - 34, FONT_HGT_SMALL, "Tier List (Requirement + Benefits)", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.tierTableHeader)

    self.tierColTitle = ISLabel:new(self.padding + 8, self.listY - 18, FONT_HGT_SMALL, "Tier", 0.85, 0.9, 1.0, 1.0, UIFont.Small, true)
    self:addChild(self.tierColTitle)

    self.reqColTitle = ISLabel:new(self.padding + 145, self.listY - 18, FONT_HGT_SMALL, "Requirement", 0.85, 0.9, 1.0, 1.0, UIFont.Small, true)
    self:addChild(self.reqColTitle)

    self.extraColTitle = ISLabel:new(self.padding + 500, self.listY - 18, FONT_HGT_SMALL, "Benefits", 0.85, 0.9, 1.0, 1.0, UIFont.Small, true)
    self:addChild(self.extraColTitle)

    self.tierList = ISScrollingListBox:new(self.padding, self.listY, infoWidth, self.height - self.listY - 18)
    self.tierList:initialise()
    self.tierList.backgroundColor = { r = 0.04, g = 0.04, b = 0.06, a = 0.9 }
    self.tierList.borderColor = { r = 0.28, g = 0.32, b = 0.36, a = 1 }
    self.tierList.itemheight = FONT_HGT_SMALL + 8
    self.tierList.font = UIFont.Small
    self.tierList.drawBorder = true
    self.tierList.doDrawItem = self.drawTierRow
    self:addChild(self.tierList)

    self:refreshData()
end

function PlayerTierInfoUI:drawTierRow(y, item, alt)
    local row = item.item
    local a = 0.9

    if row and row.isCurrent then
        self:drawRect(0, y, self:getWidth(), self.itemheight, 0.45, 0.12, 0.35, 0.12)
    elseif alt then
        self:drawRect(0, y, self:getWidth(), self.itemheight, 0.28, 0.18, 0.18, 0.2)
    else
        self:drawRect(0, y, self:getWidth(), self.itemheight, 0.18, 0.12, 0.12, 0.16)
    end

    local textY = y + 2
    if row then
        local r, g, b = 1, 1, 1
        if row.isCurrent then
            r, g, b = 0.75, 1, 0.75
        end

        self:drawText(row.name or "Unknown", 8, textY, r, g, b, a, UIFont.Small)
        self:drawText(row.requirement or "-", 145, textY, 0.9, 0.9, 0.9, a, UIFont.Small)
        self:drawText(row.benefits or "-", 500, textY, 0.85, 0.9, 1.0, a, UIFont.Small)
    end

    return y + self.itemheight
end

function PlayerTierInfoUI:populateTierRows()
    self.tierList:clear()

    local selectedIndex = 1
    local rows = self.progressData and self.progressData.tierRows or {}
    for index, row in ipairs(rows) do
        self.tierList:addItem(row.name, row)
        if row.isCurrent then
            selectedIndex = index
        end
    end

    self.tierList.selected = selectedIndex
    if self.tierList.ensureVisible then
        self.tierList:ensureVisible(selectedIndex - 1)
    end
end

function PlayerTierInfoUI:refreshData()
    if not self.player then
        return
    end

    if PlayerTierHandler and PlayerTierHandler.getTierProgressData then
        local latest = PlayerTierHandler.getTierProgressData(self.player)
        if latest then
            self.progressData = latest
        end
    end

    local data = self.progressData or {}
    local daysSurvived = tonumber(data.daysSurvived) or 0
    local hoursSurvived = tonumber(data.hoursSurvived) or 0
    local zombieKills = tonumber(data.zombieKills) or 0

    self.daysProgress = tonumber(data.daysProgress) or 0
    self.killsProgress = tonumber(data.killsProgress) or 0

    self.playerLabel:setName("Player: " .. tostring(data.username or self.player:getUsername() or "Unknown") .. "   |   Supporter Title: " .. tostring(data.titleValue or 0))
    self.currentTierLabel:setName("Current Tier: " .. tostring(data.currentTier or "Newbies") .. " (#" .. tostring(data.currentTierValue or 1) .. ")")
    self.statsLabel:setName("Progress Stats: " .. formatNumber(math.floor(daysSurvived)) .. " days (" .. formatNumber(hoursSurvived) .. "h), " .. formatNumber(zombieKills) .. " zombie kills")
    self.nextTierLabel:setName("Next Tier: " .. tostring(data.nextTier or "Max tier reached"))
    self.requirementLabel:setName("Requirement: " .. tostring(data.nextTierRequirement or "Max tier reached"))


    self:populateTierRows()
end

function PlayerTierInfoUI:render()
    ISPanel.render(self)

    local barWidth = self.width - (self.padding * 2)

    self:drawText("Days Progress to Next Tier: " .. tostring(toPercent(self.daysProgress)) .. "%", self.padding, self.daysBarY - 16, 1, 1, 1, 1, UIFont.Small)
    self:drawRect(self.padding, self.daysBarY, barWidth, 12, 0.5, 0.2, 0.2, 0.24)
    self:drawRect(self.padding, self.daysBarY, barWidth * math.max(0, math.min(1, self.daysProgress)), 12, 0.85, 0.25, 0.8, 0.25)

    self:drawText("Kill Progress to Next Tier: " .. tostring(toPercent(self.killsProgress)) .. "%", self.padding, self.killsBarY - 16, 1, 1, 1, 1, UIFont.Small)
    self:drawRect(self.padding, self.killsBarY, barWidth, 12, 0.5, 0.2, 0.2, 0.24)
    self:drawRect(self.padding, self.killsBarY, barWidth * math.max(0, math.min(1, self.killsProgress)), 12, 0.85, 0.25, 0.45, 0.85)
end

function PlayerTierInfoUI:update()
    ISPanel.update(self)

    local now = 0
    if getTimestampMs then
        now = tonumber(getTimestampMs()) or 0
    end

    if now <= 0 or (now - self.lastAutoRefreshAt) >= 2000 then
        self.lastAutoRefreshAt = now
        self:refreshData()
    end
end

function PlayerTierInfoUI:onRefresh()
    if self.player and PlayerTierHandler and PlayerTierHandler.requestTierSnapshot then
        PlayerTierHandler.requestTierSnapshot(self.player, true)
    end
    self:refreshData()
end

function PlayerTierInfoUI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    if PlayerTierInfoUI.instance == self then
        PlayerTierInfoUI.instance = nil
    end
end

function PlayerTierInfoUI:close()
    self:onClose()
end

function PlayerTierInfoUI.show(player, progressData)
    if PlayerTierInfoUI.instance then
        PlayerTierInfoUI.instance:close()
    end

    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local width = 900
    local height = 560
    local x = (screenWidth - width) / 2
    local y = (screenHeight - height) / 2

    local ui = PlayerTierInfoUI:new(x, y, width, height, player, progressData)
    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)

    PlayerTierInfoUI.instance = ui
    return ui
end

PlayerTierInfoUI.instance = nil

return PlayerTierInfoUI
