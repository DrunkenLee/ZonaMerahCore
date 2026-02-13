PlayerFlagHandler = PlayerFlagHandler or {}

function PlayerFlagHandler.giveFlag(flagname, flagValue)
  local player = getPlayer()
  if player and player:getModData() then
      local modData = player:getModData()

      if flagValue == false then
          -- Remove the flag completely
          modData[flagname] = nil
          player:save()
          player:Say("Flag " .. flagname .. " has been removed")
      else
          -- Set the flag to the given value
          modData[flagname] = flagValue
          player:save()
          player:Say("Flag " .. flagname .. " set to " .. tostring(flagValue))
      end
  end
end

function PlayerFlagHandler.getFlag(flagname)
  local player = getPlayer()
  if player and player:getModData() then
      local value = player:getModData()[flagname]
      -- player:Say("Flag " .. flagname .. " is " .. tostring(value))
      return value
  end
end


function PlayerFlagHandler.setFlagOnPlayer(username, flagname, flagValue)
  if not username or username == "" then
    print("[PlayerFlagHandler] Error: Invalid username")
    return false
  end
  if not flagname or flagname == "" then
    print("[PlayerFlagHandler] Error: Invalid flagname")
    return false
  end

  local action = flagValue == false and "remove" or "set"

  print("[PlayerFlagHandler] Sending command to " .. action .. " flag", flagname, "for player", username)
  sendClientCommand("ServerFlagHandler", "giveFlag", {
    username = username,
    flagname = flagname,
    flagValue = flagValue,
    action = action
  })
  return true
end

local function addLineToChat(message, color, username, options)
	if not isClient() then return end

	if type(options) ~= "table" then
		options = {
			showTime = false,
			serverAlert = false,
			showAuthor = false,
		};
	end

	if type(color) ~= "string" then
		color = "<RGB:1,1,1>";
	end

	if options.showTime then
		local dateStamp = Calendar.getInstance():getTime();
		local dateFormat = SimpleDateFormat.new("H:mm");
		if dateStamp and dateFormat then
			message = color .. "[" .. tostring(dateFormat:format(dateStamp) or "N/A") .. "]  " .. message;
		end
	else
		message = color .. message;
	end

	local msg = {
		getText = function(_)
			return message;
		end,
		getTextWithPrefix = function(_)
			return message;
		end,
		isServerAlert = function(_)
			return options.serverAlert;
		end,
		isShowAuthor = function(_)
			return options.showAuthor;
		end,
		getAuthor = function(_)
			return tostring(username);
		end,
		setShouldAttractZombies = function(_)
			return false
		end,
		setOverHeadSpeech = function(_)
			return false
		end,
	};

	if not ISChat.instance then return; end;
	if not ISChat.instance.chatText then return; end;
	ISChat.addLineInChat(msg, 0);
end

PlayerFlagHandler.requestBroadcast = function(message)
  if not message or message == "" then
      print("[PlayerFlagHandler] Error: Invalid message for broadcast")
      return false
  end

  print("[PlayerFlagHandler] Requesting broadcast message:", message)
  sendClientCommand("ZonaMerahCore", "SendMessageZM", {
    message = message
  })
  return true
end

-- Function to check for required ritual items in a 5x5 area around the player
PlayerFlagHandler.checkRitualItems = function()
    local player = getPlayer()
    if not player then return false, "Player not found" end

    local playerSquare = player:getSquare()
    if not playerSquare then return false, "Player square not found" end

    local requiredItems = {
        "RMWeapons.DragonsteelIngot",
        "RMWeapons.EldritchWood",
        "RMWeapons.SoulThread"
    }

    local foundItems = {}
    local missingItems = {}

    -- Initialize missing items list
    for _, item in ipairs(requiredItems) do
        missingItems[item] = true
    end

    local playerX = playerSquare:getX()
    local playerY = playerSquare:getY()
    local playerZ = playerSquare:getZ()

    -- Check 5x5 area around player (-2 to +2 from player position)
    for x = playerX - 2, playerX + 2 do
        for y = playerY - 2, playerY + 2 do
            local square = getCell():getGridSquare(x, y, playerZ)
            if square then
                -- Check for world objects that might contain items
                local objects = square:getWorldObjects()
                if objects then
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj and obj.getContainer then
                            local container = obj:getContainer()
                            if container then
                                local items = container:getItems()
                                for j = 0, items:size() - 1 do
                                    local item = items:get(j)
                                    if item then
                                        local fullType = item:getFullType()
                                        for _, requiredItem in ipairs(requiredItems) do
                                            if fullType == requiredItem and missingItems[requiredItem] then
                                                foundItems[requiredItem] = true
                                                missingItems[requiredItem] = nil
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                -- Also check items directly on the ground (IsoWorldInventoryObject)
                local worldObjects = square:getWorldObjects()
                if worldObjects and worldObjects:size() > 0 then
                    for j = 0, worldObjects:size() - 1 do
                        local worldObj = worldObjects:get(j)
                        if worldObj and worldObj.getItem then
                            local item = worldObj:getItem()
                            if item then
                                local fullType = item:getFullType()
                                for _, requiredItem in ipairs(requiredItems) do
                                    if fullType == requiredItem and missingItems[requiredItem] then
                                        foundItems[requiredItem] = true
                                        missingItems[requiredItem] = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Check if at least one item was found
    local anyItemFound = false
    for item, _ in pairs(foundItems) do
        anyItemFound = true
        break
    end

    if anyItemFound then
        return true, "Required ritual item found"
    else
        local itemsText = table.concat(requiredItems, " OR ")
        return false, "No ritual items found. You need at least one of these items: " .. itemsText
    end
end

PlayerFlagHandler.RitualFunction = function(level)
    local flagName = "SummoningRitual"
    -- PlayerFlagHandler.giveFlag(flagName, level)
    local player = getPlayer()
    local username = player and player:getUsername() or "Unknown"

    -- Validate ritual items before proceeding
    local itemsFound, message = PlayerFlagHandler.checkRitualItems()
    if not itemsFound then
        player:Say("Ritual failed: " .. message .. ". Place these items within a 5x5 area around yourself before attempting the ritual.")
        print("[AngelicGravestone] Ritual validation failed: " .. message)
        return false
    end

    -- Send request to server to consume ritual items
    local playerSquare = player:getSquare()
    if playerSquare then
        sendClientCommand("ZM_ZombieHandler", "consumeRitualItems", {
            playerX = playerSquare:getX(),
            playerY = playerSquare:getY(),
            playerZ = playerSquare:getZ(),
            ritualLevel = level
        })

        -- Store ritual level for when server responds
        PlayerFlagHandler.pendingRitualLevel = level
        player:Say("Preparing ritual materials...")
        print("[AngelicGravestone] Requesting server to consume ritual items for level " .. level)
        return true -- Return true for now, actual ritual will be triggered by server response
    else
        player:Say("Ritual failed: Unable to determine your location.")
        print("[AngelicGravestone] Ritual failed: Player square not found")
        return false
    end
end

-- Function to execute the actual ritual after server confirms item consumption
PlayerFlagHandler.executeRitual = function(level)
    local player = getPlayer()
    local username = player and player:getUsername() or "Unknown"

    if level == 30 then

        -- change this to check surrounding area for this items

        sendClientCommand("ZonaMerahCore", "SendMessageZM", {
            message = username .. " has begun the level 30 summoning ritual! Brace yourselves!",
        })
        print("[AngelicGravestone] Starting ritual level 30")
        player:setHealth(player:getHealth() * 0.5)
        player:Say("Felt a sharp pain in my chest..." .. player:getHealth() .. " health remaining")
        print(player:getHealth() .. " health remaining")
        ZM_ZombieHandler.consoleSpawnHorde(100, 50, true, username, "elite", false, 30)

    elseif level == 50 then
        sendClientCommand("ZonaMerahCore", "SendMessageZM", {
            message = username .. " has begun the level 50 summoning ritual! Brace yourselves!",
        })
        print("[AngelicGravestone] Starting ritual level 50")
        player:setHealth(player:getHealth() * 0.7)
        player:Say("Felt a sharp pain in my chest..." .. player:getHealth() .. " health remaining")
        print(player:getHealth() .. " health remaining")
        ZM_ZombieHandler.consoleSpawnHorde(200, 50, true, username, "elite", false, 30)

    elseif level == 70 then
        sendClientCommand("ZonaMerahCore", "SendMessageZM", {
            message = username .. " has begun the level 70 summoning ritual! Brace yourselves!",
        })
        print("[AngelicGravestone] Starting ritual level 70")
        player:setHealth(player:getHealth() * 0.9)
        player:Say("Felt a sharp pain in my chest..." .. player:getHealth() .. " health remaining")
        print(player:getHealth() .. " health remaining")
        ZM_ZombieHandler.consoleSpawnHorde(300, 50, true, username, "elite", false, 30)

    else
        player:Say("Unknown ritual level: " .. tostring(level))
        print("[AngelicGravestone] Unknown ritual level: " .. tostring(level))
    end

    return true
end


local function classTag(obj)
    -- Quick best-effort type label
    if instanceof(obj, "IsoDoor") then return "IsoDoor" end
    if instanceof(obj, "IsoWindow") then return "IsoWindow" end
    if instanceof(obj, "IsoThumpable") then return "IsoThumpable" end
    if instanceof(obj, "IsoTree") then return "IsoTree" end
    if instanceof(obj, "IsoWorldInventoryObject") then return "IsoWorldInventoryObject" end
    if instanceof(obj, "IsoMovingObject") then return "IsoMovingObject" end
    return "IsoObject"
end

local function safeCall(obj, method)
    if obj and obj[method] then
        local ok, res = pcall(function() return obj[method](obj) end)
        if ok then return res end
    end
    return nil
end

local function spriteNameOf(obj)
    local spr = safeCall(obj, "getSprite")
    if spr then
        local nm = safeCall(spr, "getName")
        if nm and nm ~= "" then return nm end
    end
    return nil
end

local function nameOf(obj)
    return safeCall(obj, "getObjectName")
        or safeCall(obj, "getName")
        or spriteNameOf(obj)
        or tostring(obj)
end

local function posOf(obj)
    local sq = safeCall(obj, "getSquare")
    if sq then
        return string.format("(%d,%d,%d)", sq:getX(), sq:getY(), sq:getZ())
    end
    return "(?, ?, ?)"
end

local function containerInfo(obj)
    local cont = safeCall(obj, "getContainer")
    if cont then
        local t = safeCall(cont, "getType")
        if t and t ~= "" then return " container=" .. t end
    end
    return ""
end

local function getThumpableDisplayName(obj)
    if not (obj and instanceof(obj, "IsoThumpable")) then return nil end

    -- 1) Preferred: sprite properties (used by Moveables)
    local spr = obj:getSprite()
    if spr then
        local props = spr:getProperties()
        if props then
            local group = props:Is("GroupName") and props:Val("GroupName") or nil
            local cname = props:Is("CustomName") and props:Val("CustomName") or nil
            if group or cname then
                return (group and (group .. " ") or "") .. (cname or "")
            end
        end
    end

    -- 2) Container type (counter, crate, fridge, etc.)
    local cont = obj:getContainer()
    if cont and cont:getType() and cont:getType() ~= "" then
        return cont:getType()
    end

    -- 3) Sprite name is unique to the tile (e.g., "appliances_cooking_01_16")
    local spriteName = obj:getSpriteName()
    if spriteName and spriteName ~= "" then return spriteName end

    -- 4) Last resort: the object’s class tag
    local on = obj:getObjectName()
    if on and on ~= "" then return on end
    return "Thumpable"
end

local function describe(obj, idx)
    return string.format(
        "#%d %s name='%s' sprite='%s' pos=%s%s",
        idx,
        classTag(obj),
        tostring(nameOf(obj) or ""),
        tostring(spriteNameOf(obj) or ""),
        posOf(obj),
        containerInfo(obj)
    )
end

local function OnRightClickInfo(playerNum, context, worldObjects, test)
    -- 'test' is true when the game is probing; skip spam.
    if test then return end
    if not worldObjects then return end

    local player = getSpecificPlayer(playerNum)
    print("[RightClick] -----")

    -- Check if worldObjects is a Java ArrayList or a Lua table
    local size = 0
    local isJavaList = false

    -- Check if it's a Lua table first
    if type(worldObjects) == "table" then
        size = #worldObjects
        isJavaList = false
    -- Try to use size() method (Java ArrayList) only if it has the size method
    elseif worldObjects.size and type(worldObjects.size) == "function" then
        local ok, result = pcall(function() return worldObjects:size() end)
        if ok then
            size = result
            isJavaList = true
        else
            print("[RightClick] Error: Failed to call size() method")
            return
        end
    else
        print("[RightClick] Error: worldObjects is neither Java ArrayList nor Lua table")
        return
    end

    -- Iterate through objects - show details for thumpables only
    local angelicGravestoneFound = false
    local angelicGravestoneObj = nil

    for i = 0, size - 1 do
        local obj
        if isJavaList then
            obj = worldObjects:get(i)
        else
            obj = worldObjects[i + 1] -- Lua tables are 1-indexed
        end

        if obj and instanceof(obj, "IsoThumpable") then
            print("[RightClick] " .. getThumpableDisplayName(obj))

            if not angelicGravestoneFound and getThumpableDisplayName(obj) == "Angelic Gravestone" then
                angelicGravestoneFound = true
                angelicGravestoneObj = obj
            end
        end
    end

    -- Add context menu options only once if Angelic Gravestone was found
    if angelicGravestoneFound and angelicGravestoneObj then
        -- local option30 = context:addOption("Begin Summoning Ritual - 30", angelicGravestoneObj, function(thumpable)
        --     PlayerFlagHandler.RitualFunction(30)
        --     print("[AngelicGravestone] Starting ritual level 30")
        --     -- Add your ritual logic here
        -- end)

        local option50 = context:addOption("Begin Summoning Ritual - 50", angelicGravestoneObj, function(thumpable)

	    -- Add validation logic here
            local success = PlayerFlagHandler.RitualFunction(50)
            if success then
                print("[AngelicGravestone] Starting ritual level 50")
            else
                print("[AngelicGravestone] Ritual level 50 failed - missing required items")
            end
            -- Add your ritual logic here
        end)

        -- local option70 = context:addOption("Begin Summoning Ritual - 70", angelicGravestoneObj, function(thumpable)
        --     PlayerFlagHandler.RitualFunction(70)
        --     print("[AngelicGravestone] Starting ritual level 70")
        --     -- Add your ritual logic here
        -- end)
    end

    -- brief on-screen hint for the primary object (the direct hit) - thumpables only
    local primary
    if isJavaList then
        primary = worldObjects:get(0)
    else
        primary = worldObjects[1] -- Lua tables are 1-indexed
    end

    if player and primary and instanceof(primary, "IsoThumpable") then
        -- player:Say(string.format("[RC] %s: %s", classTag(primary), nameOf(primary) or "unknown"))
    end
end

-- Events.OnFillWorldObjectContextMenu.Add(OnRightClickInfo)


Events.OnServerCommand.Add(function(module, command, args)
  if module == "PlayerFlagHandler" and command == "updateFlag" then
      print("[PlayerFlagHandler] Received server update for flag:", args.flagname)

      -- Get the current player's username
      local player = getPlayer()
      local currentUsername = player and player:getUsername() or ""

      -- Only apply if the update is meant for this player
      if args.username and args.username == currentUsername and args.flagname then
          print("[PlayerFlagHandler] Applying flag update for", currentUsername)
          PlayerFlagHandler.giveFlag(args.flagname, args.flagValue)
      else
          print("[PlayerFlagHandler] Ignoring flag update - not for this player")
      end
  end

  if module == "ZM_ZombieHandler" and command == "ritualItemConsumed" then
      local player = getPlayer()
      if args.success then
          local consumedItem = args.consumedItem or "Unknown item"
          player:Say("Ritual materials consumed: " .. consumedItem .. ". The ritual begins!")
          print("[AngelicGravestone] Server consumed: " .. consumedItem)

          -- Execute the actual ritual if we have a pending level
          if PlayerFlagHandler.pendingRitualLevel then
              PlayerFlagHandler.executeRitual(PlayerFlagHandler.pendingRitualLevel)
              PlayerFlagHandler.pendingRitualLevel = nil
          end
      else
          player:Say("Ritual failed: No required items could be found or consumed on the server.")
          print("[AngelicGravestone] Server failed to consume ritual items")
          PlayerFlagHandler.pendingRitualLevel = nil
      end
  end

  if module == "ZonaMerahCore" and command == "Broadcast" then
      local message = args.message or ""
      if message ~= "" then
          print("[ZonaMerahCore] Broadcast message received: " .. message)
          addLineToChat(getText("[ZM Broadcast] - ") .. message, "<RGB:" .. "250,234,0" .. ">");
      end
  end

  if module == "ZonaMerahCore" and command == "BroadcastToPlayers" then
      local message = args.message or ""
      if message ~= "" then
          print("[ZonaMerahCore] Broadcast message received: " .. message)
          addLineToChat(getText("[ZM Broadcast] - ") .. message, "<RGB:" .. "250,234,0" .. ">");
      end
  end
end)

return PlayerFlagHandler