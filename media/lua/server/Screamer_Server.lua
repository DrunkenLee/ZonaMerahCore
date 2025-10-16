if isClient() then return; end

local Commands = {};
Commands.ScreamerII = {};

-- helper round (karena ga ada bawaan di Lua PZ)
local function round(num)
    return math.floor(num + 0.5)
end

Commands.ScreamerII.isScreamerII = function(player, args)
    local playerId = player:getOnlineID();
    sendServerCommand('ScreamerII', 'isScreamerII', {id = playerId, isScreamerII = args.isScreamerII, zedID = args.zedID})
end

Commands.ScreamerII.Stats = function(player, args)
    local playerId = player:getOnlineID()
    local commandArgs = {id = playerId, zedID = args.zedID}
    if args.HP then commandArgs.HP = args.HP end
    if args.WALK then commandArgs.WALK = args.WALK end
    sendServerCommand('ScreamerII', 'Stats', commandArgs)
end

Commands.ScreamerII.knockDownZed = function(player, args)
    local playerId = player:getOnlineID();
    sendServerCommand('ScreamerII', 'knockDownZed', {id = playerId, zedID = args.zedID})
end

Commands.ScreamerII.isWearingScreamerII = function(player, args)
    local playerId = player:getOnlineID();
    sendServerCommand('ScreamerII', 'isWearingScreamerII', {id = playerId, isWearingScreamerII = args.isWearingScreamerII})
end

Commands.ScreamerII.Bashed = function(player, args)
    local playerId = player:getOnlineID();
    sendServerCommand('ScreamerII', 'Bashed', {id = playerId, targID = args.targID})
end

Commands.ScreamerII.isSprinter = function(player, args)
    local playerId = player:getOnlineID();
    sendServerCommand('ScreamerII', 'isSprinter', {id = playerId, isSprinter = args.isSprinter, zedID = args.zedID})
end

Commands.ScreamerII.Crash = function(player, args)
    local playerId = player:getOnlineID();
    sendServerCommand('ScreamerII', 'Crash', {id = playerId, zedID = args.zedID})
end

Commands.ScreamerII.msg = function(player, args)
    local playerId = player:getOnlineID()
    sendServerCommand('ScreamerII', 'msg', {id = playerId, msg = args.msg})
end

Commands.ScreamerII.img = function(player, args)
    local playerId = player:getOnlineID()
    sendServerCommand('ScreamerII', 'img', {id = playerId, int = args.int})
end

Commands.ScreamerII.sfx = function(player, args)
    local playerId = player:getOnlineID()
    sendServerCommand('ScreamerII', 'sfx', {id = playerId})
end

Commands.ScreamerII.doSpawn = function(player, args)
    local x, y, z, fit, fChance, isDown = args.x, args.y, args.z, args.fit, args.fChance, args.isDown
    local zeds = addZombiesInOutfit(round(x), round(y), round(z), 1, tostring(fit), tonumber(fChance), false, isDown, false, false, 1.0)

    if zeds and not zeds:isEmpty() then
        local zed = zeds:get(0)
        if isDown and not zed:isOnFloor() then
            zed:knockDown(true)
        end
    end
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if Commands[module] and Commands[module][command] then
        Commands[module][command](player, args)
    end
end)
