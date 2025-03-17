PlayerTitleHandlerServer = {}

-- Function to clear the mod data
function PlayerTitleHandlerServer.clearModData()
    PlayerTitleHandlerServer = {}
    print("[ZonaMerahCore] PlayerTitleHandlerServer mod data has been cleared.")
end

Events.OnInitGlobalModData.Add(function (isNewGame)
    if isNewGame then
        PlayerTitleHandlerServer.clearModData()
    else
        PlayerTitleHandlerServer.clearModData()
    end
end)