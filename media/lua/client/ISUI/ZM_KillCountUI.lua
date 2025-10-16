-- ZM_KillCountUI.lua - UI for displaying player kill counts
require "ISUI/ISPanel"
require "PlayerTitleHandler" -- for adjusted kill calculation

ZM_KillCountUI = ISPanel:derive("ZM_KillCountUI")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function ZM_KillCountUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.width = width
    o.height = height
    o.moveWithMouse = true
    o.title = "Player Kill Count Tracker"
    o.killData = {}
    return o
end

function ZM_KillCountUI:initialise()
    ISPanel.initialise(self)

    local padding = 10
    local btnWidth = 120
    local btnHeight = 25
    local currentY = 40

    -- Title
    self.titleLabel = ISLabel:new(padding, 10, FONT_HGT_MEDIUM, "Player Kill Count Tracker", 1, 1, 1, 1, UIFont.Medium, true)
    self:addChild(self.titleLabel)

    -- Refresh button
    self.refreshBtn = ISButton:new(self.width - btnWidth - padding, 10, btnWidth, btnHeight, "Refresh Data", self, self.onRefresh)
    self.refreshBtn:initialise()
    self:addChild(self.refreshBtn)

    -- Create scrollable list for kill counts
    self.scrollArea = ISScrollingListBox:new(padding, currentY, self.width - (padding * 2), self.height - currentY - 50)
    self.scrollArea:initialise()
    self.scrollArea.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0.8}
    self.scrollArea.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
    self.scrollArea.itemheight = FONT_HGT_SMALL + 4
    self.scrollArea.selected = -1
    self.scrollArea.joypadParent = self
    self.scrollArea.font = UIFont.Small
    self.scrollArea.doDrawItem = self.drawKillCountItem
    self.scrollArea.drawBorder = true
    self:addChild(self.scrollArea)

    -- Close button
    self.closeBtn = ISButton:new(self.width - btnWidth - padding, self.height - 35, btnWidth, btnHeight, "Close", self, self.onClose)
    self.closeBtn:initialise()
    self:addChild(self.closeBtn)

    -- Current player info
    local player = getPlayer()
    if player then
        local currentKills = player:getZombieKills() or 0
        self.playerInfoLabel = ISLabel:new(padding, self.height - 35, FONT_HGT_SMALL,
            "Your Kills: " .. currentKills, 1, 1, 0, 1, UIFont.Small, true)
        self:addChild(self.playerInfoLabel)
    end

    -- Request data from server
    self:requestKillData()
end

function ZM_KillCountUI:drawKillCountItem(y, item, alt)
    local a = 0.9

    -- Alternate row colors
    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.3, 0.3, a)
    else
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.2, 0.2, 0.2, a)
    end

    local fontHgt = FONT_HGT_SMALL
    local textY = y + (self.itemheight - fontHgt) / 2

    if item.item then
        local playerData = item.item

        -- Draw rank number
        self:drawText("#" .. (item.index or 0), 10, textY, 0.8, 0.8, 0.8, a, UIFont.Small)

        -- Draw player name
        self:drawText(playerData.username or "Unknown", 40, textY, 1, 1, 1, a, UIFont.Small)

        -- Draw kill count
        local killText = tostring(playerData.killCount or 0) .. " kills"
        self:drawText(killText, self:getWidth() - 150, textY, 0.8, 1, 0.8, a, UIFont.Small)
        -- Do NOT draw last updated/timestamp
    end

    return y + self.itemheight
end

function ZM_KillCountUI:updateKillData(killData)
    if not killData then return end

    self.killData = killData
    self:refreshDisplay()
end

function ZM_KillCountUI:refreshDisplay()
    self.scrollArea:clear()

    -- Convert data to sorted list
    local sortedPlayers = {}
    for username, data in pairs(self.killData) do
        table.insert(sortedPlayers, {
            username = username,
            killCount = data.killCount or 0,
            -- timestamp etc intentionally ignored in display
        })
    end

    table.sort(sortedPlayers, function(a, b)
        return a.killCount > b.killCount
    end)

    for i = 1, math.min(10, #sortedPlayers) do
        local playerData = sortedPlayers[i]
        if playerData.killCount < 0 then playerData.killCount = 0 end
        playerData.index = i
        self.scrollArea:addItem(playerData.username, playerData)
    end

    if self.playerInfoLabel then
        local player = getPlayer()
        if player then
            local adjusted = player:getZombieKills() or 0
            if PlayerTitleHandler and PlayerTitleHandler.getPlayerTitle then
                local level = tonumber(PlayerTitleHandler.getPlayerTitle(player)) or 0
                local bonusMap = { [1]=1000,[2]=3000,[3]=5000 }
                local bonus = bonusMap[level] or 0
                adjusted = adjusted - bonus
                if adjusted < 0 then adjusted = 0 end
            end
            self.playerInfoLabel:setName("Your Kills: " .. adjusted)
        end
    end
end

function ZM_KillCountUI:requestKillData()
    -- Request fresh data from server
    if ZM_KillCountClient then
        ZM_KillCountClient.requestKillCountData()
    end

    -- Check if we have cached data
    if ZM_KillCountClient and ZM_KillCountClient.serverKillData then
        self:updateKillData(ZM_KillCountClient.serverKillData)
    end
end

function ZM_KillCountUI:onRefresh()
    self:requestKillData()
end

function ZM_KillCountUI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

function ZM_KillCountUI:close()
    self:onClose()
end

-- Static function to create and show the UI
function ZM_KillCountUI.show()
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()

    local width = 600
    local height = 400
    local x = (screenWidth - width) / 2
    local y = (screenHeight - height) / 2

    local ui = ZM_KillCountUI:new(x, y, width, height)
    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)

    return ui
end

-- Global reference for server command handling
ZM_KillCountUI.instance = nil

-- Handle server data updates
Events.OnServerCommand.Add(function(module, command, args)
    if module == "ZM_KillCount" and command == "killCountData" then
        if ZM_KillCountUI.instance and args and args.killData then
            ZM_KillCountUI.instance:updateKillData(args.killData)
        end
        -- Also store in client for future access
        if ZM_KillCountClient then
            ZM_KillCountClient.serverKillData = args.killData
        end
    end
end)

print("ZM_KillCountUI: Kill count UI system loaded")