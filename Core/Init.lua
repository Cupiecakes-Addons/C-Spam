local addonName, CSPAM = ...
_G.CSPAM = CSPAM

CSPAM.Version = "1.6.2"
local L = CSPAM.L

-- Default Database Schema
local defaultDB = {
    version = 1,
    enabled = true,
    action = "HIDE", -- "HIDE" (Kinetic Intercept), "MASK" (Jamming), "LOG" (Surveillance)
    packs = {},
    customWords = {},
    whitelist = {
        friends = true,
        guild = true,
        party = true, -- covers both party and raid allies
        characters = {},
    },
    channelGroups = {},
    options = {
        checkLeet = true,
        collapseRepeats = true,
        logFiltered = true,
        maxLogEntries = 100,
        showMinimap = true,
        minimapAngle = 225,
    },
    filteredLog = {},
    stats = {
        totalScanned = 0,
        totalFiltered = 0,
    }
}

-- Safe recursive default merger (Never overwrites user arrays or boolean/string settings)
local function CopyDefaults(src, dst)
    if type(dst) ~= "table" then dst = {} end
    if type(src) ~= "table" then return dst end

    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            -- Only recurse dictionary key-value tables (not array lists)
            if #v == 0 and next(v) ~= nil then
                dst[k] = CopyDefaults(v, dst[k])
            elseif dst[k] == nil then
                dst[k] = CopyDefaults(v, {})
            end
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

local function ClearActiveChatEditBox(editBox)
    local eb = editBox or (ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()) or (SELECTED_CHAT_FRAME and SELECTED_CHAT_FRAME.editBox) or (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox)
    if eb then
        if ChatEdit_ClearChat then
            ChatEdit_ClearChat(eb)
        else
            eb:SetText("")
        end
        if ChatEdit_DeactivateChat then
            ChatEdit_DeactivateChat(eb)
        else
            eb:Hide()
        end
    end
end
CSPAM.ClearActiveChatEditBox = ClearActiveChatEditBox

-- Master ARM/DISARM used by the slash command, console button, and minimap
function CSPAM:ToggleEnabled(silent)
    CSPAM.db.enabled = not CSPAM.db.enabled
    if not silent then
        local statusMsg = CSPAM.db.enabled and L["SLASH_TOGGLE_ON"] or L["SLASH_TOGGLE_OFF"]
        DEFAULT_CHAT_FRAME:AddMessage(statusMsg)
    end
    if CSPAM.UI and CSPAM.UI.Refresh then
        CSPAM.UI:Refresh()
    end
    if CSPAM.Minimap and CSPAM.Minimap.Refresh then
        CSPAM.Minimap:Refresh()
    end
end

-- Register a custom threat signature. Mode defaults to PHRASE for multi-word
-- input (a single EXACT token can never contain whitespace) and EXACT
-- otherwise. Returns true on success, or false plus "empty"/"exists".
function CSPAM:AddCustomRule(text, mode)
    text = text and text:trim() or ""
    if text == "" then return false, "empty" end

    if not mode then
        mode = text:find("%s") and "PHRASE" or "EXACT"
    end
    mode = mode:upper()

    for _, item in ipairs(CSPAM.db.customWords) do
        if item.text:lower() == text:lower() and (item.mode or "EXACT"):upper() == mode then
            return false, "exists"
        end
    end

    table.insert(CSPAM.db.customWords, {
        text = text,
        mode = mode,
        enabled = true,
        category = "Custom",
    })
    CSPAM.Engine:RebuildIndex()
    if CSPAM.UI and CSPAM.UI.Refresh then
        CSPAM.UI:Refresh()
    end
    return true
end

local function InitializeAddon()
    if CSPAM.isInitialized then return end

    if type(_G.CSPAM_DB) ~= "table" then
        _G.CSPAM_DB = {}
    end
    _G.CSPAM_DB = CopyDefaults(defaultDB, _G.CSPAM_DB)
    CSPAM.db = _G.CSPAM_DB

    -- Drop legacy keys that no code reads from existing SavedVariables
    CSPAM.db.options.checkPunctuation = nil
    CSPAM.db.whitelist.raid = nil
    CSPAM.db.stats.startTime = nil

    -- Channel toggles are stored per group (see Events.ChannelGroups).
    -- Migrate legacy per-event keys, then seed defaults for missing groups.
    if CSPAM.Events and CSPAM.Events.ChannelGroups then
        local legacy = CSPAM.db.channels
        for _, group in ipairs(CSPAM.Events.ChannelGroups) do
            if CSPAM.db.channelGroups[group.key] == nil then
                if legacy and legacy[group.events[1]] ~= nil then
                    CSPAM.db.channelGroups[group.key] = (legacy[group.events[1]] ~= false)
                else
                    CSPAM.db.channelGroups[group.key] = (group.default ~= false)
                end
            end
        end
        CSPAM.db.channels = nil
    end

    -- Seed pack toggles from the pack definitions so new packs added to
    -- Data/DefaultPacks.lua get their default state automatically
    if CSPAM.Packs then
        for packKey, pack in pairs(CSPAM.Packs) do
            if CSPAM.db.packs[packKey] == nil then
                CSPAM.db.packs[packKey] = (pack.enabled ~= false)
            end
        end
    end

    -- Normalize per-character whitelist keys to lowercase short names
    do
        local characters = CSPAM.db.whitelist and CSPAM.db.whitelist.characters
        if characters then
            local normalized = {}
            for name in pairs(characters) do
                if type(name) == "string" then
                    normalized[(name:match("^([^-]+)") or name):lower()] = true
                end
            end
            CSPAM.db.whitelist.characters = normalized
        end
    end

    if CSPAM.Engine and CSPAM.Engine.RebuildIndex then
        CSPAM.Engine:RebuildIndex()
    end

    if CSPAM.UI and CSPAM.UI.Init then
        CSPAM.UI:Init()
    end

    if CSPAM.Config and CSPAM.Config.Register then
        CSPAM.Config:Register()
    end

    CSPAM.isInitialized = true
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")

initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "CSPAM" or arg1 == "C-SPAM") then
        InitializeAddon()
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["ADDON_LOADED"], CSPAM.Version))
    elseif event == "PLAYER_LOGIN" then
        InitializeAddon()
        if CSPAM.Events and CSPAM.Events.RegisterFilters then
            CSPAM.Events:RegisterFilters()
        end
        -- The minimap button initializes at PLAYER_LOGIN (not ADDON_LOADED)
        -- so LibStub/LibDBIcon provided by addons that load after C-Spam
        -- are visible when we probe for them
        if CSPAM.Minimap and CSPAM.Minimap.Init then
            CSPAM.Minimap:Init()
        end
        if CSPAM.Minimap and CSPAM.Minimap.Refresh then
            CSPAM.Minimap:Refresh()
        end
    end
end)

-- Slash Commands (/cspam and /cs)
SLASH_CSPAM1 = "/cspam"
SLASH_CSPAM2 = "/cs"

SlashCmdList["CSPAM"] = function(msg, editBox)
    ClearActiveChatEditBox(editBox)

    msg = msg and msg:trim() or ""
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""

    if cmd == "" then
        if CSPAM.UI and CSPAM.UI.Toggle then
            CSPAM.UI:Toggle()
        end
    elseif cmd == "toggle" then
        CSPAM:ToggleEnabled()
    elseif cmd == "add" then
        if arg and arg ~= "" then
            local word = arg:trim()
            local ok, reason = CSPAM:AddCustomRule(word)
            if ok then
                DEFAULT_CHAT_FRAME:AddMessage(string.format(L["SLASH_ADDED_WORD"], word))
            elseif reason == "exists" then
                DEFAULT_CHAT_FRAME:AddMessage(string.format(L["SLASH_WORD_EXISTS"], word))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(L["SLASH_HELP_ADD"])
        end
    elseif cmd == "safe" then
        local characters = CSPAM.db.whitelist.characters
        if arg and arg ~= "" then
            local trimmed = arg:trim()
            local key = (trimmed:match("^([^-]+)") or trimmed):lower()
            if characters[key] then
                characters[key] = nil
                DEFAULT_CHAT_FRAME:AddMessage(string.format(L["SLASH_SAFE_REMOVED"], key))
            else
                characters[key] = true
                DEFAULT_CHAT_FRAME:AddMessage(string.format(L["SLASH_SAFE_ADDED"], key))
            end
        else
            local names = {}
            for name in pairs(characters) do
                names[#names + 1] = name
            end
            if #names == 0 then
                DEFAULT_CHAT_FRAME:AddMessage(L["SLASH_SAFE_EMPTY"])
            else
                table.sort(names)
                DEFAULT_CHAT_FRAME:AddMessage(string.format(L["SLASH_SAFE_LIST"], table.concat(names, ", ")))
            end
        end
    elseif cmd == "stats" then
        local scanned = CSPAM.db.stats.totalScanned or 0
        local filtered = CSPAM.db.stats.totalFiltered or 0
        local pct = scanned > 0 and ((filtered / scanned) * 100) or 0
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff3b30C-SPAM Telemetry:|r Airspace Scanned: |cffffffff%d|r | Threats Intercepted: |cffff2020%d|r (|cff00e5ff%.1f%%|r Intercept Rate)", scanned, filtered, pct))
    else
        DEFAULT_CHAT_FRAME:AddMessage(L["SLASH_HELP_HEADER"])
        DEFAULT_CHAT_FRAME:AddMessage(L["SLASH_HELP_OPEN"])
        DEFAULT_CHAT_FRAME:AddMessage(L["SLASH_HELP_TOGGLE"])
        DEFAULT_CHAT_FRAME:AddMessage(L["SLASH_HELP_ADD"])
        DEFAULT_CHAT_FRAME:AddMessage(L["SLASH_HELP_SAFE"])
        DEFAULT_CHAT_FRAME:AddMessage(L["SLASH_HELP_STATS"])
    end
end
