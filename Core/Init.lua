local addonName, CSPAM = ...
_G.CSPAM = CSPAM
_G.C_SPAM = CSPAM

CSPAM.Version = "1.0.4"
local L = CSPAM.L

-- Default Database Schema
local defaultDB = {
    version = 1,
    enabled = true,
    action = "HIDE", -- "HIDE" (Kinetic Intercept), "MASK" (Jamming), "LOG" (Surveillance)
    packs = {
        politics = true,
        boosting = false,
        toxicity = true,
    },
    customWords = {},
    whitelist = {
        friends = true,
        guild = true,
        party = true,
        raid = true,
        characters = {},
    },
    channels = {
        CHAT_MSG_CHANNEL = true,
        CHAT_MSG_COMMUNITIES_CHANNEL = true,
        CHAT_MSG_SAY = true,
        CHAT_MSG_YELL = true,
        CHAT_MSG_WHISPER = false,
        CHAT_MSG_EMOTE = true,
        CHAT_MSG_TEXT_EMOTE = true,
    },
    options = {
        checkLeet = true,
        checkPunctuation = true,
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
        startTime = 0,
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

local function InitializeAddon()
    if CSPAM.isInitialized then return end

    if type(_G.CSPAM_DB) ~= "table" then
        _G.CSPAM_DB = {}
    end
    _G.CSPAM_DB = CopyDefaults(defaultDB, _G.CSPAM_DB)
    CSPAM.db = _G.CSPAM_DB

    if CSPAM.db.stats.startTime == 0 then
        CSPAM.db.stats.startTime = time()
    end

    if CSPAM.Engine and CSPAM.Engine.RebuildIndex then
        CSPAM.Engine:RebuildIndex()
    end

    if CSPAM.UI and CSPAM.UI.Init then
        CSPAM.UI:Init()
    end

    if CSPAM.Minimap and CSPAM.Minimap.Init then
        CSPAM.Minimap:Init()
    end

    if CSPAM.Config and CSPAM.Config.Register then
        CSPAM.Config:Register()
    end

    CSPAM.isInitialized = true
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_LOGOUT")

initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "CSPAM" or arg1 == "C-SPAM") then
        InitializeAddon()
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["ADDON_LOADED"], CSPAM.Version))
    elseif event == "PLAYER_LOGIN" then
        InitializeAddon()
        if CSPAM.Events and CSPAM.Events.RegisterFilters then
            CSPAM.Events:RegisterFilters()
        end
        if CSPAM.Minimap and CSPAM.Minimap.Refresh then
            CSPAM.Minimap:Refresh()
        end
    elseif event == "PLAYER_LOGOUT" then
        if CSPAM.db then
            _G.CSPAM_DB = CSPAM.db
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
        CSPAM.db.enabled = not CSPAM.db.enabled
        local statusMsg = CSPAM.db.enabled and L["SLASH_TOGGLE_ON"] or L["SLASH_TOGGLE_OFF"]
        DEFAULT_CHAT_FRAME:AddMessage(statusMsg)
        if CSPAM.UI and CSPAM.UI.Refresh then
            CSPAM.UI:Refresh()
        end
        if CSPAM.Minimap and CSPAM.Minimap.Refresh then
            CSPAM.Minimap:Refresh()
        end
    elseif cmd == "add" then
        if arg and arg ~= "" then
            local word = arg:lower():trim()
            local exists = false
            for _, item in ipairs(CSPAM.db.customWords) do
                if item.text:lower() == word then
                    exists = true
                    break
                end
            end
            if exists then
                DEFAULT_CHAT_FRAME:AddMessage(string.format(L["SLASH_WORD_EXISTS"], word))
            else
                table.insert(CSPAM.db.customWords, {
                    text = word,
                    mode = "EXACT",
                    enabled = true,
                    category = "Custom"
                })
                CSPAM.Engine:RebuildIndex()
                if CSPAM.UI and CSPAM.UI.Refresh then
                    CSPAM.UI:Refresh()
                end
                DEFAULT_CHAT_FRAME:AddMessage(string.format(L["SLASH_ADDED_WORD"], word))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(L["SLASH_HELP_ADD"])
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
        DEFAULT_CHAT_FRAME:AddMessage(L["SLASH_HELP_STATS"])
    end
end
