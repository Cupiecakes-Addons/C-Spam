local addonName, CSPAM = ...

CSPAM.UI = {}
local UI = CSPAM.UI
local L = CSPAM.L

local mainFrame = nil
local activeTab = 1
local searchFilter = ""
local contentPanels = {}
local tabButtons = {}

-- =============================================================================
-- ELVUI AESTHETIC DESIGN SYSTEM & WIDGET FACTORY
-- =============================================================================

local SOLID_TEX = "Interface\\Buttons\\WHITE8X8"

-- Dark & Semi-Transparent Palette (Directly matching ElvUI's Transparent Backdrop)
local C_BG_DARK    = { 0.05, 0.05, 0.06, 0.78 }
local C_BG_PANEL   = { 0.07, 0.07, 0.08, 0.70 }
local C_BG_ROW_ALT = { 0.06, 0.06, 0.08, 0.50 }
local C_BORDER     = { 0.00, 0.00, 0.00, 1.00 }
local C_INNER_BORD = { 0.18, 0.18, 0.22, 0.85 }
local C_ACCENT     = { 0.00, 0.70, 1.00, 1.00 } -- ElvUI Cyan
local C_ACCENT_RED = { 1.00, 0.23, 0.19, 1.00 } -- C-SPAM Red
local C_BTN_NORMAL = { 0.12, 0.12, 0.15, 0.85 }
local C_BTN_HOVER  = { 0.18, 0.18, 0.22, 0.95 }

-- Apply ElvUI 1-pixel flat backdrop with outer border & transparency support
local function CreateElvBackdrop(frame, bgCol, borderCol, isTransparent)
    if frame.SetTemplate then
        frame:SetTemplate(isTransparent and "Transparent" or "Default")
    else
        frame:SetBackdrop({
            bgFile = SOLID_TEX,
            edgeFile = SOLID_TEX,
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        local bg = bgCol or (isTransparent and C_BG_DARK or C_BG_PANEL)
        local bc = borderCol or C_INNER_BORD
        frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 0.8)
        frame:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4] or 1)
    end
end

-- Attach Rich ElvUI Hover Tooltip
local function SetElvTooltip(frame, title, desc, example)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cff00e5ff" .. title .. "|r", 1, 1, 1)
        if desc then
            GameTooltip:AddLine(desc, 0.9, 0.9, 0.9, true)
        end
        if example then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffffd100Example Behavior:|r", 1, 0.82, 0)
            GameTooltip:AddLine(example, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

-- ElvUI Flat Button
local function CreateElvButton(parent, text, width, height, isRed)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 100, height or 22)
    CreateElvBackdrop(btn, C_BTN_NORMAL, C_INNER_BORD, false)

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText(text or "")

    btn:SetScript("OnEnter", function(self)
        if not self:IsEnabled() then return end
        local hoverCol = isRed and { 0.4, 0.1, 0.1, 0.9 } or C_BTN_HOVER
        local borderCol = isRed and C_ACCENT_RED or C_ACCENT
        self:SetBackdropColor(hoverCol[1], hoverCol[2], hoverCol[3], hoverCol[4])
        self:SetBackdropBorderColor(borderCol[1], borderCol[2], borderCol[3], borderCol[4])
    end)

    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C_BTN_NORMAL[1], C_BTN_NORMAL[2], C_BTN_NORMAL[3], C_BTN_NORMAL[4])
        self:SetBackdropBorderColor(C_INNER_BORD[1], C_INNER_BORD[2], C_INNER_BORD[3], C_INNER_BORD[4])
    end)

    function btn:SetText(newText)
        self.text:SetText(newText)
    end

    return btn
end

-- ElvUI Flat Checkbox with label and properly bounded subtext
local function CreateElvCheckBox(parent, labelText, subText, onClick, textWidth)
    local check = CreateFrame("Button", nil, parent, "BackdropTemplate")
    check:SetSize(16, 16)
    CreateElvBackdrop(check, C_BTN_NORMAL, C_INNER_BORD, false)

    local inner = check:CreateTexture(nil, "OVERLAY")
    inner:SetTexture(SOLID_TEX)
    inner:SetPoint("TOPLEFT", 3, -3)
    inner:SetPoint("BOTTOMRIGHT", -3, 3)
    inner:SetColorTexture(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 1)
    inner:Hide()
    check.inner = inner

    check.text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    check.text:SetPoint("LEFT", check, "RIGHT", 7, 0)
    check.text:SetText(labelText or "")

    if subText then
        local sub = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        sub:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 23, -2)
        local maxW = textWidth or (parent:GetWidth() > 50 and (parent:GetWidth() - 44) or 285)
        sub:SetWidth(maxW)
        sub:SetWordWrap(true)
        sub:SetJustifyH("LEFT")
        sub:SetText(subText)
        check.sub = sub
    end

    local checked = false
    function check:SetChecked(val)
        checked = (val == true)
        if checked then
            inner:Show()
            self:SetBackdropBorderColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 1)
        else
            inner:Hide()
            self:SetBackdropBorderColor(C_INNER_BORD[1], C_INNER_BORD[2], C_INNER_BORD[3], 1)
        end
    end

    function check:GetChecked()
        return checked
    end

    check:SetScript("OnClick", function(self)
        self:SetChecked(not checked)
        if onClick then onClick(checked) end
    end)

    check:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 1)
    end)

    check:SetScript("OnLeave", function(self)
        if not checked then
            self:SetBackdropBorderColor(C_INNER_BORD[1], C_INNER_BORD[2], C_INNER_BORD[3], 1)
        end
    end)

    return check
end

-- ElvUI Flat Radio Button with properly bounded subtext
local function CreateElvRadio(parent, labelText, subText, onClick, textWidth)
    local radio = CreateFrame("Button", nil, parent, "BackdropTemplate")
    radio:SetSize(14, 14)
    CreateElvBackdrop(radio, C_BTN_NORMAL, C_INNER_BORD, false)

    local inner = radio:CreateTexture(nil, "OVERLAY")
    inner:SetTexture(SOLID_TEX)
    inner:SetPoint("TOPLEFT", 2, -2)
    inner:SetPoint("BOTTOMRIGHT", -2, 2)
    inner:SetColorTexture(C_ACCENT_RED[1], C_ACCENT_RED[2], C_ACCENT_RED[3], 1)
    inner:Hide()
    radio.inner = inner

    radio.text = radio:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    radio.text:SetPoint("LEFT", radio, "RIGHT", 7, 0)
    radio.text:SetText(labelText or "")

    if subText then
        local sub = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        sub:SetPoint("TOPLEFT", radio, "BOTTOMLEFT", 21, -2)
        local maxW = textWidth or (parent:GetWidth() > 50 and (parent:GetWidth() - 44) or 285)
        sub:SetWidth(maxW)
        sub:SetWordWrap(true)
        sub:SetJustifyH("LEFT")
        sub:SetText(subText)
        radio.sub = sub
    end

    local checked = false
    function radio:SetChecked(val)
        checked = (val == true)
        if checked then
            inner:Show()
            self:SetBackdropBorderColor(C_ACCENT_RED[1], C_ACCENT_RED[2], C_ACCENT_RED[3], 1)
        else
            inner:Hide()
            self:SetBackdropBorderColor(C_INNER_BORD[1], C_INNER_BORD[2], C_INNER_BORD[3], 1)
        end
    end

    function radio:GetChecked()
        return checked
    end

    radio:SetScript("OnClick", function(self)
        if onClick then onClick() end
    end)

    return radio
end

-- ElvUI Flat EditBox
local function CreateElvEditBox(parent, width, height)
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    eb:SetSize(width or 180, height or 22)
    CreateElvBackdrop(eb, { 0.05, 0.05, 0.07, 0.75 }, C_INNER_BORD, false)
    eb:SetFontObject("GameFontHighlightSmall")
    eb:SetTextInsets(6, 6, 2, 2)
    eb:SetAutoFocus(false)

    eb:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 1)
    end)

    eb:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(C_INNER_BORD[1], C_INNER_BORD[2], C_INNER_BORD[3], 1)
    end)

    eb:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    return eb
end

-- ElvUI Section Card Frame
local function CreateElvCard(parent, titleText, descText, width, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(width, height)
    CreateElvBackdrop(card, { 0.06, 0.06, 0.08, 0.65 }, C_INNER_BORD, true)

    if titleText then
        local header = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("TOPLEFT", 10, -8)
        header:SetText("|cff00e5ff" .. titleText .. "|r")
        card.header = header
    end

    if descText then
        local desc = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        desc:SetPoint("TOPLEFT", 10, -24)
        desc:SetWidth(width - 20)
        desc:SetWordWrap(true)
        desc:SetJustifyH("LEFT")
        desc:SetText(descText)
        card.desc = desc
    end

    return card
end

-- =============================================================================
-- MAIN CONSOLE INITIALIZATION
-- =============================================================================

function UI:Init()
    if mainFrame then return end

    mainFrame = CreateFrame("Frame", "CSPAMMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(720, 580)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetClampedToScreen(true)
    CreateElvBackdrop(mainFrame, C_BG_DARK, { 0, 0, 0, 1 }, true)
    tinsert(UISpecialFrames, "CSPAMMainFrame")

    -- Top Header Bar
    local headerBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    headerBar:SetPoint("TOPLEFT", 1, -1)
    headerBar:SetPoint("TOPRIGHT", -1, -1)
    headerBar:SetHeight(28)
    CreateElvBackdrop(headerBar, { 0.08, 0.08, 0.10, 0.80 }, C_INNER_BORD, true)

    local iconLogo = headerBar:CreateTexture(nil, "OVERLAY")
    iconLogo:SetSize(20, 20)
    iconLogo:SetPoint("LEFT", 6, 0)
    iconLogo:SetTexture("Interface\\AddOns\\CSPAM\\Media\\icon.tga")

    local title = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", iconLogo, "RIGHT", 7, 0)
    title:SetText("|cffff3b30C-SPAM|r |cffffffffPhalanx Defense Console|r")

    local ver = headerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ver:SetPoint("LEFT", title, "RIGHT", 8, 0)
    ver:SetText("|cff888888v" .. CSPAM.Version .. "|r")

    local closeBtn = CreateFrame("Button", nil, headerBar, "BackdropTemplate")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", -4, 0)
    CreateElvBackdrop(closeBtn, C_BTN_NORMAL, C_INNER_BORD, false)

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER", 0, 0)
    closeText:SetText("|cffff2020×|r")

    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)
    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.4, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(1, 0.2, 0.2, 1)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C_BTN_NORMAL[1], C_BTN_NORMAL[2], C_BTN_NORMAL[3], C_BTN_NORMAL[4])
        self:SetBackdropBorderColor(C_INNER_BORD[1], C_INNER_BORD[2], C_INNER_BORD[3], 1)
    end)

    -- Master ARM / DISARM Button
    local masterBtn = CreateElvButton(headerBar, "ARMED", 90, 20)
    masterBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    masterBtn:SetScript("OnClick", function()
        CSPAM:ToggleEnabled()
    end)
    SetElvTooltip(masterBtn, "Master Interceptor Switch", 
        "Globally arms or disarms all chat threat filtering across all channels.\n\n" ..
        "• |cff00ff00ARMED|r: Actively scans, intercepts, and removes matching chat threats.\n" ..
        "• |cffff2020DISARMED|r: Interceptor is in standby; chat passes through unaltered.")
    mainFrame.masterBtn = masterBtn

    -- Tabs Container
    local tabNames = {
        L["TAB_CUSTOM"] or "Threat Matrix",
        L["TAB_PACKS"] or "Defense Packs",
        L["TAB_LOG"] or "Intercept Log",
        L["TAB_SETTINGS"] or "Radar & Config",
        L["TAB_IMPORT_EXPORT"] or "Import / Export"
    }

    local function ShowTab(tabIndex)
        activeTab = tabIndex
        for i, panel in ipairs(contentPanels) do
            if i == tabIndex then
                panel:Show()
                if tabButtons[i] then
                    tabButtons[i]:SetBackdropColor(C_BG_PANEL[1], C_BG_PANEL[2], C_BG_PANEL[3], 0.90)
                    tabButtons[i]:SetBackdropBorderColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 1)
                    tabButtons[i].text:SetTextColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 1)
                end
            else
                panel:Hide()
                if tabButtons[i] then
                    tabButtons[i]:SetBackdropColor(C_BTN_NORMAL[1], C_BTN_NORMAL[2], C_BTN_NORMAL[3], 0.65)
                    tabButtons[i]:SetBackdropBorderColor(C_INNER_BORD[1], C_INNER_BORD[2], C_INNER_BORD[3], 1)
                    tabButtons[i].text:SetTextColor(0.7, 0.7, 0.7, 1)
                end
            end
        end
        UI:Refresh()
    end

    local tabX = 8
    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
        tab:SetSize(136, 24)
        tab:SetPoint("TOPLEFT", tabX, -33)
        CreateElvBackdrop(tab, C_BTN_NORMAL, C_INNER_BORD, false)

        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tab.text:SetPoint("CENTER", 0, 0)
        tab.text:SetText(name)

        tab:SetScript("OnClick", function() ShowTab(i) end)
        tab:SetScript("OnEnter", function(self)
            if activeTab ~= i then
                self:SetBackdropBorderColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 0.7)
                self.text:SetTextColor(1, 1, 1, 1)
            end
        end)
        tab:SetScript("OnLeave", function(self)
            if activeTab ~= i then
                self:SetBackdropBorderColor(C_INNER_BORD[1], C_INNER_BORD[2], C_INNER_BORD[3], 1)
                self.text:SetTextColor(0.7, 0.7, 0.7, 1)
            end
        end)

        tabButtons[i] = tab
        tabX = tabX + 140

        local panel = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
        panel:SetPoint("TOPLEFT", 8, -60)
        panel:SetPoint("BOTTOMRIGHT", -8, 8)
        CreateElvBackdrop(panel, C_BG_PANEL, C_INNER_BORD, true)
        panel:Hide()
        contentPanels[i] = panel
    end

    -- =========================================================================
    -- TAB 1: THREAT MATRIX
    -- =========================================================================
    local p1 = contentPanels[1]

    local addInput = CreateElvEditBox(p1, 210, 24)
    addInput:SetPoint("TOPLEFT", 10, -10)
    local addPlaceholder = addInput:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    addPlaceholder:SetPoint("LEFT", 8, 0)
    addPlaceholder:SetText("Enter target signature / keyword...")
    addInput.placeholder = addPlaceholder
    addInput:SetScript("OnTextChanged", function(self)
        if self:GetText() == "" then addPlaceholder:Show() else addPlaceholder:Hide() end
    end)
    SetElvTooltip(addInput, "Target Signature Input", "Type the word, phrase, or pattern you wish to intercept.")

    local selectedMode = "EXACT"
    local modes = { "EXACT", "CONTAINS", "PHRASE", "REGEX" }
    local modeIndex = 1
    local modeBtn = CreateElvButton(p1, "Mode: Exact", 116, 24)
    modeBtn:SetPoint("LEFT", addInput, "RIGHT", 6, 0)
    
    local function UpdateModeTooltip()
        if selectedMode == "EXACT" then
            SetElvTooltip(modeBtn, "Mode: Exact Word (Recommended for single words)",
                "Matches isolated, standalone words only. Punctuation (like '!?,.') is automatically stripped.\n\n" ..
                "• Prevents false positives inside longer words.",
                "Blocking 'trump' intercepts 'Vote for trump!' but will NOT block 'strumpet' or 'trumpet'.")
        elseif selectedMode == "CONTAINS" then
            SetElvTooltip(modeBtn, "Mode: Contains (Substring Match)",
                "Matches the signature anywhere within the text, even when embedded inside other words.",
                "Blocking 'sell' intercepts 'reseller', 'selling', 'wholesale', etc.")
        elseif selectedMode == "PHRASE" then
            SetElvTooltip(modeBtn, "Mode: Phrase (Multi-Word Sequence)",
                "Matches multi-word phrases with normalized spacing and punctuation between words.",
                "Blocking 'project 2025' intercepts 'project   2025', 'project-2025', and 'Project 2025!'.")
        elseif selectedMode == "REGEX" then
            SetElvTooltip(modeBtn, "Mode: Regex / Lua Pattern (Advanced)",
                "Evaluates the target as an advanced Lua regular expression pattern.",
                "Example: '^wts%s+.*boost' matches any line starting with 'wts' followed by 'boost'.")
        end
    end
    UpdateModeTooltip()

    modeBtn:SetScript("OnClick", function(self)
        modeIndex = (modeIndex % #modes) + 1
        selectedMode = modes[modeIndex]
        self:SetText("Mode: " .. selectedMode:sub(1,1) .. selectedMode:sub(2):lower())
        UpdateModeTooltip()
    end)

    local addBtn = CreateElvButton(p1, "+ Register Threat", 126, 24)
    addBtn:SetPoint("LEFT", modeBtn, "RIGHT", 6, 0)
    addBtn:SetScript("OnClick", function()
        if CSPAM:AddCustomRule(addInput:GetText(), selectedMode) then
            addInput:SetText("")
        end
    end)

    local searchBox = CreateElvEditBox(p1, 160, 24)
    searchBox:SetPoint("TOPRIGHT", -10, -10)
    local sPlaceholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sPlaceholder:SetPoint("LEFT", 8, 0)
    sPlaceholder:SetText("Search signatures...")
    searchBox:SetScript("OnTextChanged", function(self)
        if self:GetText() == "" then sPlaceholder:Show() else sPlaceholder:Hide() end
        searchFilter = self:GetText():lower():trim()
        UI:Refresh()
    end)
    SetElvTooltip(searchBox, "Filter Matrix", "Type here to quickly filter through your registered threat signatures.")

    -- Table Header
    local thFrame = CreateFrame("Frame", nil, p1, "BackdropTemplate")
    thFrame:SetPoint("TOPLEFT", 10, -42)
    thFrame:SetPoint("TOPRIGHT", -10, -42)
    thFrame:SetHeight(20)
    CreateElvBackdrop(thFrame, { 0.10, 0.10, 0.13, 0.80 }, C_INNER_BORD, true)

    local th1 = thFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    th1:SetPoint("LEFT", 10, 0)
    th1:SetText("|cff00e5ffTARGET SIGNATURE|r")

    local th2 = thFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    th2:SetPoint("LEFT", 350, 0)
    th2:SetText("|cff00e5ffTRACKING MODE|r")

    local th3 = thFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    th3:SetPoint("RIGHT", -16, 0)
    th3:SetText("|cff00e5ffDELETE|r")

    local scrollFrame = CreateFrame("ScrollFrame", "CSPAMCustomScrollFrame", p1, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -64)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(660, 400)
    scrollFrame:SetScrollChild(scrollContent)
    p1.scrollContent = scrollContent

    -- =========================================================================
    -- TAB 2: DEFENSE PACKS
    -- =========================================================================
    local p2 = contentPanels[2]
    p2.packCheckboxes = {}

    -- Cards are built straight from Data/DefaultPacks.lua (name, description,
    -- example, order): a new pack added there appears here automatically
    local packKeys = {}
    for key in pairs(CSPAM.Packs or {}) do
        packKeys[#packKeys + 1] = key
    end
    table.sort(packKeys, function(a, b)
        local oa = CSPAM.Packs[a].order or math.huge
        local ob = CSPAM.Packs[b].order or math.huge
        if oa ~= ob then return oa < ob end
        return a < b
    end)

    local cardY = -12
    for _, key in ipairs(packKeys) do
        local pack = CSPAM.Packs[key]
        local packKey = key
        local title = (pack.name or key):upper()
        local card = CreateElvCard(p2, title, pack.description, 684, 105)
        card:SetPoint("TOPLEFT", 10, cardY)

        local cb = CreateElvCheckBox(card, "Active In Defense Matrix", nil, function(checked)
            CSPAM.db.packs[packKey] = checked
            CSPAM.Engine:RebuildIndex()
            UI:Refresh()
        end)
        cb:SetPoint("TOPLEFT", 12, -48)

        local badge = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        badge:SetPoint("LEFT", cb.text, "RIGHT", 14, 0)
        badge:SetText(string.format("(|cffffd100%d calibrated signatures|r)", pack.words and #pack.words or 0))

        if pack.example then
            local ex = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            ex:SetPoint("TOPLEFT", 12, -74)
            ex:SetWidth(660)
            ex:SetJustifyH("LEFT")
            ex:SetText("|cff888888" .. pack.example .. "|r")
        end

        SetElvTooltip(cb, title, pack.description, pack.example)
        p2.packCheckboxes[packKey] = cb
        cardY = cardY - 118
    end

    -- =========================================================================
    -- TAB 3: INTERCEPT LOG
    -- =========================================================================
    local p3 = contentPanels[3]

    local logHeader = CreateFrame("Frame", nil, p3, "BackdropTemplate")
    logHeader:SetPoint("TOPLEFT", 10, -10)
    logHeader:SetPoint("TOPRIGHT", -10, -10)
    logHeader:SetHeight(28)
    CreateElvBackdrop(logHeader, { 0.10, 0.10, 0.13, 0.80 }, C_INNER_BORD, true)

    local logTitle = logHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    logTitle:SetPoint("LEFT", 10, 0)
    logTitle:SetText("REAL-TIME THREAT INTERCEPT TELEMETRY (ROLLING 100-ENTRY LOG)")

    local purgeBtn = CreateElvButton(logHeader, "Purge Telemetry", 120, 20, true)
    purgeBtn:SetPoint("RIGHT", -4, 0)
    purgeBtn:SetScript("OnClick", function()
        table.wipe(CSPAM.db.filteredLog)
        UI:Refresh()
    end)
    SetElvTooltip(purgeBtn, "Purge Telemetry", "Clears all recorded intercept logs from addon memory.")

    local logScrollFrame = CreateFrame("ScrollFrame", "CSPAMLogScrollFrame", p3, "UIPanelScrollFrameTemplate")
    logScrollFrame:SetPoint("TOPLEFT", 10, -42)
    logScrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)

    local logContent = CreateFrame("Frame", nil, logScrollFrame)
    logContent:SetSize(660, 420)
    logScrollFrame:SetScrollChild(logContent)
    p3.logContent = logContent

    local emptyMsg = p3:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyMsg:SetPoint("CENTER", p3, "CENTER", 0, -10)
    emptyMsg:SetText("|cff666666[ RADAR ACTIVE ] Standing by for telemetry...\nIntercepted chat threats will appear here in real-time.|r")
    p3.emptyMsg = emptyMsg

    -- =========================================================================
    -- TAB 4: RADAR & CONFIG
    -- =========================================================================
    local p4 = contentPanels[4]

    -- Card 1: Engagement Doctrine (Width 338, Usable text width 280)
    local cardDoctrine = CreateElvCard(p4, "ENGAGEMENT PROTOCOL", 
        "Determines how intercepted chat messages are handled when a threat signature is triggered.", 338, 135)
    cardDoctrine:SetPoint("TOPLEFT", 10, -10)

    local rHide = CreateElvRadio(cardDoctrine, "Kinetic Intercept (Silent Drop)", 
        "Message is completely dropped. Nothing appears in your chat window.", function()
        CSPAM.db.action = "HIDE"
        CSPAM.Engine:InvalidateCache()
        p4.rHide:SetChecked(true)
        p4.rMask:SetChecked(false)
    end, 280)
    rHide:SetPoint("TOPLEFT", 12, -44)
    SetElvTooltip(rHide, "Kinetic Intercept", 
        "Silently suppresses the entire incoming chat message before it reaches your chat frame. No audio or visual notification is produced.")

    local rMask = CreateElvRadio(cardDoctrine, "Electronic Jamming (Censor ***)", 
        "Message passes through, but matching keywords are censored with asterisks.", function()
        CSPAM.db.action = "MASK"
        CSPAM.Engine:InvalidateCache()
        p4.rMask:SetChecked(true)
        p4.rHide:SetChecked(false)
    end, 280)
    rMask:SetPoint("TOPLEFT", 12, -88)
    SetElvTooltip(rMask, "Electronic Jamming", 
        "Allows the message through to your chat frame, but replaces the detected keywords with '***' while keeping item and spell links completely safe.")

    p4.rHide = rHide
    p4.rMask = rMask

    -- Card 2: IFF Whitelist (Width 338, Usable text width 280)
    local cardIFF = CreateElvCard(p4, "IFF SAFE ALLIES (WHITELIST BYPASS)", 
        "Safe allies will bypass the interceptor even if they send blocked keywords.", 338, 135)
    cardIFF:SetPoint("TOPRIGHT", -10, -10)

    local cbFriends = CreateElvCheckBox(cardIFF, "Safe: Friends List", nil, function(c) CSPAM.db.whitelist.friends = c end, 280)
    cbFriends:SetPoint("TOPLEFT", 12, -44)
    SetElvTooltip(cbFriends, "Bypass: Friends List", "Messages from Battle.net and character friends are never intercepted.")

    local cbGuild = CreateElvCheckBox(cardIFF, "Safe: Guild Roster", nil, function(c) CSPAM.db.whitelist.guild = c end, 280)
    cbGuild:SetPoint("TOPLEFT", 12, -72)
    SetElvTooltip(cbGuild, "Bypass: Guild Roster", "Messages from guild members are never intercepted.")

    local cbParty = CreateElvCheckBox(cardIFF, "Safe: Party & Raid Allies", nil, function(c) CSPAM.db.whitelist.party = c end, 280)
    cbParty:SetPoint("TOPLEFT", 12, -100)
    SetElvTooltip(cbParty, "Bypass: Party & Raid Allies", "Messages from members of your current dungeon/raid group bypass the filter.")

    p4.cbFriends = cbFriends
    p4.cbGuild = cbGuild
    p4.cbParty = cbParty

    -- Card 3: Monitored Airspace (Channels) — built from Events.ChannelGroups
    -- so every monitored event has a toggle and the two can never drift
    local channelGroups = (CSPAM.Events and CSPAM.Events.ChannelGroups) or {}
    local airspaceRows = math.ceil(#channelGroups / 2)
    local cardAirspace = CreateElvCard(p4, "MONITORED AIRSPACE (CHAT CHANNELS)",
        "Select which chat channels the C-SPAM radar actively monitors and filters.", 684, 52 + airspaceRows * 46)
    cardAirspace:SetPoint("TOPLEFT", 10, -155)

    p4.channelChecks = {}
    for i, group in ipairs(channelGroups) do
        local col = (i - 1) % 2
        local rowIdx = math.floor((i - 1) / 2)
        local key = group.key
        local cb = CreateElvCheckBox(cardAirspace, group.label, group.sub, function(c)
            CSPAM.db.channelGroups[key] = c
        end, 280)
        cb:SetPoint("TOPLEFT", 12 + col * 343, -44 - rowIdx * 46)
        SetElvTooltip(cb, group.label, group.tooltip)
        p4.channelChecks[key] = cb
    end

    -- Card 4: Evasion Decoders & Interface (Width 684, textWidth 610)
    local cardEvasion = CreateElvCard(p4, "EVASION DECODING & INTERFACE RADAR", 
        "Advanced heuristics that decode bypass tricks, plus Minimap HUD controls.", 684, 150)
    cardEvasion:SetPoint("TOPLEFT", cardAirspace, "BOTTOMLEFT", 0, -8)

    local cbLeet = CreateElvCheckBox(cardEvasion, "Decode Camouflage, Leetspeak & Homoglyphs", 
        "Translates '@' -> 'a', '0' -> 'o', '$' -> 's', '1' -> 'i', 'v' -> 'u', and Russian Cyrillic lookalikes back to standard Latin characters.", function(c)
        CSPAM.db.options.checkLeet = c
        CSPAM.Engine:InvalidateCache()
    end, 610)
    cbLeet:SetPoint("TOPLEFT", 12, -44)
    SetElvTooltip(cbLeet, "Decode Camouflage & Leetspeak", 
        "Translates visual lookalikes before filtering so spammers cannot bypass your blocklist.\n\n" ..
        "• Translates '@' to 'a', '0' to 'o', '$' to 's', '!'/'1' to 'i'.\n" ..
        "• Normalizes Cyrillic lookalikes (e.g. Russian 'а', 'е', 'о', 'р', 'с').",
        "A spammer typing 'tr0mp' or 'b!den' or 'wts b00st' is automatically decoded and intercepted.")

    local cbRepeat = CreateElvCheckBox(cardEvasion, "Collapse Stutter Evasion (e.g. 'traaaash' -> 'trash')", 
        "Collapses runs of 3+ identical letters and spaces between characters ('t.r.u.m.p' -> 'trump').", function(c)
        CSPAM.db.options.collapseRepeats = c
        CSPAM.Engine:InvalidateCache()
    end, 610)
    cbRepeat:SetPoint("TOPLEFT", 12, -78)
    SetElvTooltip(cbRepeat, "Collapse Stutter Evasion", 
        "Prevents players from bypassing filters by dragging out letters or inserting spacing/dots.\n\n" ..
        "• Collapses 3+ repeated characters down to 1.\n" ..
        "• Automatically strips punctuation and space padding.",
        "'trumpppp' and 't r u m p' and 't.r.u.m.p' are automatically recognized as 'trump'.")

    local cbMinimap = CreateElvCheckBox(cardEvasion, "Show C-SPAM Minimap Turret Icon", 
        "Displays the C-SPAM turret icon on your minimap for 1-click console access and quick ARM/DISARM toggles.", function(c) 
        CSPAM.db.options.showMinimap = c 
        if CSPAM.Minimap and CSPAM.Minimap.Refresh then
            CSPAM.Minimap:Refresh()
        end
    end, 610)
    cbMinimap:SetPoint("TOPLEFT", 12, -114)
    SetElvTooltip(cbMinimap, "Minimap Turret Button", 
        "Toggles the C-SPAM minimap button.\n\n" ..
        "• |cff00e5ffLeft-Click:|r Open/Close Tactical Defense Console.\n" ..
        "• |cff00e5ffRight-Click:|r Quick toggle ARM / DISARM.\n" ..
        "• |cff00e5ffDrag:|r Move button around your minimap perimeter.")

    p4.cbLeet = cbLeet
    p4.cbRepeat = cbRepeat
    p4.cbMinimap = cbMinimap

    -- =========================================================================
    -- TAB 5: IMPORT / EXPORT
    -- =========================================================================
    local p5 = contentPanels[5]

    local ieHeader = p5:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ieHeader:SetPoint("TOPLEFT", 10, -10)
    ieHeader:SetText("THREAT SIGNATURE MATRIX (RAW TELEMETRY / IMPORT & EXPORT)")

    local ieSub = p5:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ieSub:SetPoint("TOPLEFT", 10, -26)
    ieSub:SetText("Copy your registered threat signatures to share with guildmates, or paste a new list below and click 'Import Matrix Data'.")

    local ieScroll = CreateFrame("ScrollFrame", "CSPAMIEScrollFrame", p5, "UIPanelScrollFrameTemplate")
    ieScroll:SetPoint("TOPLEFT", 10, -46)
    ieScroll:SetPoint("BOTTOMRIGHT", -26, 44)

    local ieEditBox = CreateFrame("EditBox", nil, ieScroll, "BackdropTemplate")
    ieEditBox:SetMultiLine(true)
    ieEditBox:SetMaxLetters(999999)
    ieEditBox:EnableMouse(true)
    ieEditBox:SetAutoFocus(false)
    ieEditBox:SetFontObject("GameFontHighlightSmall")
    ieEditBox:SetWidth(650)
    ieEditBox:SetTextInsets(6, 6, 6, 6)
    CreateElvBackdrop(ieEditBox, { 0.05, 0.05, 0.07, 0.75 }, C_INNER_BORD, false)
    ieScroll:SetScrollChild(ieEditBox)
    p5.ieEditBox = ieEditBox

    local exportBtn = CreateElvButton(p5, "Export Signatures", 140, 24)
    exportBtn:SetPoint("BOTTOMLEFT", 10, 8)
    exportBtn:SetScript("OnClick", function()
        local lines = {}
        for _, item in ipairs(CSPAM.db.customWords) do
            table.insert(lines, string.format("%s:%s", item.mode or "EXACT", item.text))
        end
        ieEditBox:SetText(table.concat(lines, "\n"))
        ieEditBox:HighlightText()
    end)
    SetElvTooltip(exportBtn, "Export Signatures", "Dumps all your custom threat signatures into the text box formatted as MODE:KEYWORD for easy sharing.")

    local importBtn = CreateElvButton(p5, "Import Matrix Data", 140, 24)
    importBtn:SetPoint("BOTTOMLEFT", exportBtn, "BOTTOMRIGHT", 8, 0)
    importBtn:SetScript("OnClick", function()
        local text = ieEditBox:GetText()
        local count = 0
        for line in text:gmatch("[^\r\n]+") do
            line = line:trim()
            if line ~= "" then
                local mode, word = line:match("^(%w+):(.*)$")
                if not mode then
                    word = line
                    mode = "EXACT"
                end
                word = word:trim()
                if word ~= "" then
                    table.insert(CSPAM.db.customWords, {
                        text = word,
                        mode = mode:upper(),
                        enabled = true,
                        category = "Custom"
                    })
                    count = count + 1
                end
            end
        end
        CSPAM.Engine:RebuildIndex()
        UI:Refresh()
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["IE_SUCCESS"] or "Loaded %d threat signatures.", count))
    end)
    SetElvTooltip(importBtn, "Import Matrix Data", "Parses the text box (one signature per line) and adds all entries into your active Threat Matrix.")

    mainFrame:Hide()
    ShowTab(1)
end

function UI:Toggle()
    if not mainFrame then
        self:Init()
    end
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        if CSPAM.ClearActiveChatEditBox then
            CSPAM.ClearActiveChatEditBox()
        end
        mainFrame:Show()
        self:Refresh()
    end
end

-- Hook called by Engine.lua when a threat is intercepted
function UI:OnLogUpdated()
    if mainFrame and mainFrame:IsShown() and activeTab == 3 then
        self:Refresh()
    end
end

function UI:Refresh()
    if not mainFrame or not mainFrame:IsShown() then return end

    local armed = (CSPAM.db and CSPAM.db.enabled == true)
    if armed then
        mainFrame.masterBtn:SetText("|cff00ff00ARMED|r")
        mainFrame.masterBtn:SetBackdropBorderColor(0, 0.8, 0.2, 1)
    else
        mainFrame.masterBtn:SetText("|cffff2020DISARMED|r")
        mainFrame.masterBtn:SetBackdropBorderColor(0.8, 0.1, 0.1, 1)
    end

    if activeTab == 1 then
        local p1 = contentPanels[1]
        local parent = p1 and p1.scrollContent
        if not parent then return end

        if not parent.rows then parent.rows = {} end
        for _, r in ipairs(parent.rows) do r:Hide() end

        local y = 0
        local rowIndex = 0

        if CSPAM.db and CSPAM.db.customWords then
            for i, item in ipairs(CSPAM.db.customWords) do
                local textMatch = true
                if searchFilter ~= "" then
                    textMatch = item.text:lower():find(searchFilter, 1, true) ~= nil
                end

                if textMatch then
                    rowIndex = rowIndex + 1
                    local row = parent.rows[rowIndex]
                    if not row then
                        row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
                        row:SetSize(656, 24)

                        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        row.text:SetPoint("LEFT", 10, 0)

                        row.mode = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        row.mode:SetPoint("LEFT", 340, 0)

                        local delBtn = CreateElvButton(row, "×", 22, 18, true)
                        delBtn:SetPoint("RIGHT", -6, 0)
                        row.delBtn = delBtn

                        parent.rows[rowIndex] = row
                    end

                    local bg = (rowIndex % 2 == 0) and C_BG_ROW_ALT or { 0.05, 0.05, 0.07, 0.35 }
                    CreateElvBackdrop(row, bg, { 0.12, 0.12, 0.15, 0.50 }, false)

                    row:SetPoint("TOPLEFT", 0, -y)
                    row.text:SetText(item.text)
                    row.mode:SetText("|cffffd100[" .. (item.mode or "EXACT") .. "]|r")

                    local itemIndex = i
                    row.delBtn:SetScript("OnClick", function()
                        table.remove(CSPAM.db.customWords, itemIndex)
                        CSPAM.Engine:RebuildIndex()
                        UI:Refresh()
                    end)

                    row:Show()
                    y = y + 26
                end
            end
        end

        parent:SetHeight(math.max(y, 380))

    elseif activeTab == 2 then
        local p2 = contentPanels[2]
        if p2 and p2.packCheckboxes and CSPAM.db and CSPAM.db.packs then
            for key, cb in pairs(p2.packCheckboxes) do
                cb:SetChecked(CSPAM.db.packs[key] == true)
            end
        end

    elseif activeTab == 3 then
        local p3 = contentPanels[3]
        local parent = p3 and p3.logContent
        if not parent then return end

        if not parent.rows then parent.rows = {} end
        for _, r in ipairs(parent.rows) do r:Hide() end

        local y = 0
        local rowIndex = 0

        local logEntries = CSPAM.db and CSPAM.db.filteredLog
        if logEntries and #logEntries > 0 then
            if p3.emptyMsg then p3.emptyMsg:Hide() end
            for i, entry in ipairs(logEntries) do
                rowIndex = rowIndex + 1
                local row = parent.rows[rowIndex]
                if not row then
                    row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
                    row:SetSize(656, 40)

                    row.header = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    row.header:SetPoint("TOPLEFT", 8, -4)

                    row.msg = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    row.msg:SetPoint("TOPLEFT", 8, -20)
                    row.msg:SetWidth(640)
                    row.msg:SetJustifyH("LEFT")

                    parent.rows[rowIndex] = row
                end

                local bg = (rowIndex % 2 == 0) and C_BG_ROW_ALT or { 0.05, 0.05, 0.07, 0.35 }
                CreateElvBackdrop(row, bg, { 0.12, 0.12, 0.15, 0.50 }, false)

                row:SetPoint("TOPLEFT", 0, -y)
                local timeStr = date("%H:%M:%S", entry.timestamp or time())
                local repeats = (entry.count and entry.count > 1) and string.format(" |cffffd100(x%d)|r", entry.count) or ""
                row.header:SetText(string.format("|cff888888[%s]|r |cff00e5ff[%s]|r |cffffffff%s|r (|cffff3b30Target: %s|r)%s", timeStr, entry.channel or "Sector", entry.sender or "Unknown", entry.matched or "Threat", repeats))
                row.msg:SetText(entry.message or "")
                row:Show()
                y = y + 42
            end
        else
            if p3.emptyMsg then p3.emptyMsg:Show() end
        end

        parent:SetHeight(math.max(y, 380))

    elseif activeTab == 4 then
        local p4 = contentPanels[4]
        if p4 and CSPAM.db then
            if p4.rHide then p4.rHide:SetChecked(CSPAM.db.action == "HIDE") end
            if p4.rMask then p4.rMask:SetChecked(CSPAM.db.action == "MASK") end
            if p4.cbFriends then p4.cbFriends:SetChecked(CSPAM.db.whitelist and CSPAM.db.whitelist.friends == true) end
            if p4.cbGuild then p4.cbGuild:SetChecked(CSPAM.db.whitelist and CSPAM.db.whitelist.guild == true) end
            if p4.cbParty then p4.cbParty:SetChecked(CSPAM.db.whitelist and CSPAM.db.whitelist.party == true) end
            if p4.channelChecks and CSPAM.db.channelGroups then
                for key, cb in pairs(p4.channelChecks) do
                    cb:SetChecked(CSPAM.db.channelGroups[key] == true)
                end
            end
            if p4.cbLeet then p4.cbLeet:SetChecked(CSPAM.db.options and CSPAM.db.options.checkLeet ~= false) end
            if p4.cbRepeat then p4.cbRepeat:SetChecked(CSPAM.db.options and CSPAM.db.options.collapseRepeats ~= false) end
            if p4.cbMinimap then p4.cbMinimap:SetChecked(CSPAM.db.options and CSPAM.db.options.showMinimap ~= false) end
        end
    end
end
