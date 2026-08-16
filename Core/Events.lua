local addonName, CSPAM = ...

CSPAM.Events = {}
local EV = CSPAM.Events

-- Single source of truth for monitored chat channels. Filters are registered
-- from it, Init derives defaults and migrations from it, and the Radar &
-- Config tab builds its checkboxes from it — adding a group here is enough
-- to make a new channel monitored, toggleable, and persisted.
EV.ChannelGroups = {
    {
        key = "public",
        events = { "CHAT_MSG_CHANNEL" },
        default = true,
        label = "Public Channels (Trade, Services, General, LFG)",
        sub = "Monitors public realm channels where boosting and political spam are most rampant.",
        tooltip = "Applies intercept rules to Trade, Services, General, LocalDefense, and LookingForGroup channels.",
    },
    {
        key = "communities",
        events = { "CHAT_MSG_COMMUNITIES_CHANNEL" },
        default = true,
        label = "Communities & Club Channels",
        sub = "Monitors WoW Community and custom player channels.",
        tooltip = "Applies intercept rules to Blizzard Community channels.",
    },
    {
        key = "say",
        events = { "CHAT_MSG_SAY", "CHAT_MSG_YELL" },
        default = true,
        label = "Local Say & Yell",
        sub = "Monitors local open-world chat (/say and /yell).",
        tooltip = "Monitors open-world spatial chat in cities and zones.",
    },
    {
        key = "emote",
        events = { "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE" },
        default = true,
        label = "Emotes",
        sub = "Monitors /emote text and predefined text emotes.",
        tooltip = "Applies intercept rules to player emotes.",
    },
    {
        key = "whisper",
        events = { "CHAT_MSG_WHISPER" },
        default = false,
        label = "Direct Whispers",
        sub = "Monitors direct private whispers from strangers (Allies still bypass if IFF is enabled).",
        tooltip = "Monitors 1-on-1 private whispers sent to you by other players.",
    },
}

local eventToGroup = {}
for _, group in ipairs(EV.ChannelGroups) do
    for _, eventName in ipairs(group.events) do
        eventToGroup[eventName] = group.key
    end
end

local function FilterChatMessage(chatFrame, event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter, guid, ...)
    local db = CSPAM.db
    if not db or not db.enabled then
        return false, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter, guid, ...
    end

    local groupKey = eventToGroup[event]
    if groupKey and db.channelGroups and db.channelGroups[groupKey] == false then
        return false, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown2, counter, guid, ...
    end

    local displaySector = channelName
    if not displaySector or displaySector == "" then
        displaySector = channelString or event:gsub("^CHAT_MSG_", "")
    end

    local eval = CSPAM.Engine:EvaluateMessage(message, sender, guid, displaySector, counter)

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
    for _, group in ipairs(EV.ChannelGroups) do
        for _, eventName in ipairs(group.events) do
            ChatFrame_AddMessageEventFilter(eventName, FilterChatMessage)
        end
    end
end
