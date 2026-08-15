local addonName, CSPAM = ...

CSPAM.Events = {}
local EV = CSPAM.Events

local monitoredEvents = {
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_WHISPER",
}

local function FilterChatMessage(chatFrame, event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter, guid, ...)
    local db = CSPAM.db
    if not db or not db.enabled then
        return false, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter, guid, ...
    end

    if db.channels and db.channels[event] == false then
        return false, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter, guid, ...
    end

    local displaySector = channelName
    if not displaySector or displaySector == "" then
        displaySector = channelString or event:gsub("^CHAT_MSG_", "")
    end

    local eval = CSPAM.Engine:EvaluateMessage(message, sender, guid, displaySector)

    if eval.shouldFilter then
        if eval.action == "HIDE" then
            -- Kinetic Intercept: Drop message completely
            return true
        elseif eval.action == "MASK" and eval.maskedText then
            -- Electronic Jamming: Return masked text
            return false, eval.maskedText, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter, guid, ...
        end
    end

    return false, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter, guid, ...
end

function EV:RegisterFilters()
    for _, eventName in ipairs(monitoredEvents) do
        ChatFrame_AddMessageEventFilter(eventName, FilterChatMessage)
    end
end
