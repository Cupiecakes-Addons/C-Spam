local addonName, CSPAM = ...

CSPAM.Config = {}
local Config = CSPAM.Config
local L = CSPAM.L

function Config:Register()
    local configPanel = CreateFrame("Frame", "CSPAMSettingsPanel", UIParent)
    configPanel.name = "C-SPAM"

    local title = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cffff3b30C-SPAM|r |cff00e5ff[Counter-Spam Phalanx System]|r")

    local version = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("LEFT", title, "RIGHT", 10, 0)
    version:SetText("v" .. CSPAM.Version)

    local desc = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", 16, -46)
    desc:SetWidth(560)
    desc:SetJustifyH("LEFT")
    desc:SetText("C-SPAM is an automated chat threat interceptor inspired by military C-RAM air defense systems. It automatically tracks, decodes, and eliminates political noise, gold spam, and toxic keywords before they reach your chat box.")

    local openBtn = CreateFrame("Button", nil, configPanel, "UIPanelButtonTemplate")
    openBtn:SetSize(240, 30)
    openBtn:SetPoint("TOPLEFT", 16, -95)
    openBtn:SetText("Open Tactical Defense Console")
    openBtn:SetScript("OnClick", function()
        if Settings and SettingsPanel and SettingsPanel:IsShown() then
            SettingsPanel:Hide()
        elseif InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
            InterfaceOptionsFrame:Hide()
        end
        if CSPAM.UI and CSPAM.UI.Toggle then
            CSPAM.UI:Toggle()
        end
    end)

    local helpText = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", 16, -150)
    helpText:SetWidth(560)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("Console Slash Commands:\n" ..
        "  |cff00e5ff/cs|r or |cff00e5ff/cspam|r - Open Tactical Defense Console\n" ..
        "  |cff00e5ff/cs toggle|r - Quick Arm / Disarm intercept system\n" ..
        "  |cff00e5ff/cs add <word>|r - Quick register threat signature\n" ..
        "  |cff00e5ff/cs stats|r - Output intercept telemetry & stats")

    -- Modern Retail Settings API
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(configPanel, "C-SPAM")
        Settings.RegisterAddOnCategory(category)
        Config.category = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(configPanel)
    end
end
