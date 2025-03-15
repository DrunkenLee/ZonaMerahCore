require "PlayerKillCountServer"

AlertHandler = {}

function AlertHandler.addLineToChat(message, color, username, options)
    if not isClient() then return end

    if type(options) ~= "table" then
        options = {
            showTime = false,
            serverAlert = false,
            showAuthor = false,
        }
    end

    if type(color) ~= "string" then
        color = "<RGB:1,1,1>"
    end

    if options.showTime then
        local dateStamp = Calendar.getInstance():getTime()
        local dateFormat = SimpleDateFormat.new("H:mm")
        if dateStamp and dateFormat then
            message = color .. "[" .. tostring(dateFormat:format(dateStamp) or "N/A") .. "]  " .. message
        end
    else
        message = color .. message
    end

    local msg = {
        getText = function(_)
            return message
        end,
        getTextWithPrefix = function(_)
            return message
        end,
        isServerAlert = function(_)
            return options.serverAlert
        end,
        isShowAuthor = function(_)
            return options.showAuthor
        end,
        getAuthor = function(_)
            return tostring(username)
        end,
        setShouldAttractZombies = function(_)
            return false
        end,
        setOverHeadSpeech = function(_)
            return false
        end,
    }

    if not ISChat.instance then return end
    if not ISChat.instance.chatText then return end
    ISChat.addLineInChat(msg, 0)
end

function SendAlertChat(module, command, args)
    if module == "ServerAlert" and command == "sendAlert" then
        AlertHandler.addLineToChat(args.message, args.color, args.username, args.options)
    end
end

Events.OnServerCommand.Add(OnServerCommand)