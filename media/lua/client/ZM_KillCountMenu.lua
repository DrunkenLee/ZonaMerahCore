-- ZM_KillCountMenu.lua - Context menu integration for Kill Count UI
require "ISContextMenu"

ZM_KillCountMenu = ZM_KillCountMenu or {}

-- Add kill count option to player context menu
function ZM_KillCountMenu.addKillCountMenu(playerIndex, context)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    -- Add kill count tracking option
    context:addOption("View Kill Count Leaderboard", player, ZM_KillCountMenu.openKillCountUI, player)
end

-- Function to open the kill count UI
function ZM_KillCountMenu.openKillCountUI(player)
    if not player then return end

    -- Check if UI is already open and close it
    if ZM_KillCountUI.instance then
        ZM_KillCountUI.instance:close()
        ZM_KillCountUI.instance = nil
    end

    -- Create and show new UI instance
    ZM_KillCountUI.instance = ZM_KillCountUI.show()

    print("ZM_KillCountMenu: Opened kill count UI for " .. (player:getUsername() or "Unknown"))
end

-- Keyboard shortcut handler
function ZM_KillCountMenu.onKeyPressed(key)
    -- Check for Ctrl+K combination to open kill count UI
    if key == Keyboard.KEY_K and isCtrlKeyDown() then
        local player = getPlayer()
        if player then
            ZM_KillCountMenu.openKillCountUI(player)
        end
    end
end

-- Hook into the context menu event
Events.OnFillWorldObjectContextMenu.Add(ZM_KillCountMenu.addKillCountMenu)
Events.OnKeyPressed.Add(ZM_KillCountMenu.onKeyPressed)

print("ZM_KillCountMenu: Kill count context menu integration loaded (Ctrl+K to open)")