function ISMiniMap.InitPlayer(playerNum)
	local width = 200
	local height = 200
	local sx = getPlayerScreenLeft(playerNum)
	local sy = getPlayerScreenTop(playerNum)
	local sw = getPlayerScreenWidth(playerNum)
	local sh = getPlayerScreenHeight(playerNum)
	local MINIMAP = ISMiniMapOuter:new(sx + sw - 10 - width, sy + sh - 10 - height, width, height, playerNum)
	MINIMAP:initialise()
	MINIMAP:instantiate()

	local INNER = MINIMAP.inner

	local dirs = getLotDirectories()
	for i=1,dirs:size() do
--[[
		local file = 'media/maps/'..dirs:get(i-1)..'/worldmap-forest.xml'
		if fileExists(file) then
			INNER.mapAPI:addData(file)
		end
--]]
		local file = 'media/maps/'..dirs:get(i-1)..'/worldmap.xml'
		if fileExists(file) then
			INNER.mapAPI:addData(file)
		end

		-- This call indicates the end of XML data files for the directory.
		-- If map features exist for a particular cell in this directory,
		-- then no data added afterwards will be used for that same cell.
		INNER.mapAPI:endDirectoryData()

		INNER.mapAPI:addImages('media/maps/'..dirs:get(i-1))
	end
	INNER.mapAPI:setBoundsFromWorld()
	INNER.mapAPI:setZoom(19)

	INNER.mapAPI:setBoolean("HideUnvisited", true)
	INNER.mapAPI:setBoolean("Players", true)
	INNER.mapAPI:setBoolean("Symbols", false)
	INNER.mapAPI:setBoolean("MiniMapSymbols", true)
	INNER.mapAPI:setBoolean("RemotePlayers", true)
	INNER.mapAPI:setBoolean("PlayerNames", true)

	MapUtils.initDefaultStyleV1(INNER)

	MINIMAP:restoreSettings()

	local settings = WorldMapSettings.getInstance()
	if settings:getBoolean("MiniMap.StartVisible") then
		MINIMAP:addToUIManager()
	end

	return MINIMAP
end