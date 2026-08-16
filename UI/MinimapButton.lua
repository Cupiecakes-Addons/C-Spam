local addonName, CSPAM = ...

CSPAM.Minimap = {}
local MM = CSPAM.Minimap
local L = CSPAM.L

local button = nil
local ICON_PATH = "Interface\\AddOns\\CSPAM\\Media\\icon.tga"

local function UpdateButtonPosition(angle)
    if not button then return end
    angle = angle or (CSPAM.db and CSPAM.db.options and CSPAM.db.options.minimapAngle) or 225

    local rad = math.rad(angle)
    local cos = math.cos(rad)
    local sin = math.sin(rad)

    local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local radiusX = (Minimap:GetWidth() / 2) + 8
    local radiusY = (Minimap:GetHeight() / 2) + 8

    local x, y
    if minimapShape == "SQUARE" or (ElvUI and Minimap:IsShown()) then
        local diag = math.max(math.abs(cos), math.abs(sin))
        x = (cos / diag) * radiusX
        y = (sin / diag) * radiusY
    else
        x = cos * radiusX
        y = sin * radiusY
    end

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
MM.UpdatePosition = UpdateButtonPosition

function MM:Init()
    -- 1. Try LibDataBroker & LibDBIcon integration (for ElvUI / Minimap Bar integration)
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

    if LDB and not MM.dataObj then
        local dataObj = LDB:NewDataObject("CSPAM", {
            type = "launcher",
            text = "C-SPAM",
            icon = ICON_PATH,
            OnClick = function(self, btn)
                if btn == "LeftButton" then
                    if CSPAM.UI and CSPAM.UI.Toggle then
                        CSPAM.UI:Toggle()
                    end
                elseif btn == "RightButton" then
                    CSPAM.db.enabled = not CSPAM.db.enabled
                    local statusMsg = CSPAM.db.enabled and (L["SLASH_TOGGLE_ON"] or "|cffff3b30C-SPAM:|r Interceptor |cff00ff00ARMED|r.") or (L["SLASH_TOGGLE_OFF"] or "|cffff3b30C-SPAM:|r Interceptor |cffff2020DISARMED|r.")
                    DEFAULT_CHAT_FRAME:AddMessage(statusMsg)
                    if CSPAM.UI and CSPAM.UI.Refresh then
                        CSPAM.UI:Refresh()
                    end
                    MM:Refresh()
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("|cffff3b30C-SPAM|r |cff00e5ffPhalanx Defense|r", 1, 1, 1)
                tooltip:AddLine(" ")

                local armed = (CSPAM.db and CSPAM.db.enabled)
                local statusText = armed and "|cff00ff00[ARMED & ACTIVE]|r" or "|cffff2020[DISARMED]|r"
                tooltip:AddDoubleLine("Interceptor Status:", statusText, 0.9, 0.9, 0.9, 1, 1, 1)

                local scanned = (CSPAM.db and CSPAM.db.stats and CSPAM.db.stats.totalScanned) or 0
                local filtered = (CSPAM.db and CSPAM.db.stats and CSPAM.db.stats.totalFiltered) or 0
                local pct = scanned > 0 and ((filtered / scanned) * 100) or 0
                tooltip:AddDoubleLine("Airspace Scanned:", string.format("|cffffffff%d|r", scanned), 0.9, 0.9, 0.9, 1, 1, 1)
                tooltip:AddDoubleLine("Threats Intercepted:", string.format("|cffff2020%d|r (|cff00e5ff%.1f%%|r)", filtered, pct), 0.9, 0.9, 0.9, 1, 1, 1)

                tooltip:AddLine(" ")
                tooltip:AddLine("|cff00e5ffLeft-Click:|r Toggle Tactical Defense Console", 0.8, 0.8, 0.8)
                tooltip:AddLine("|cff00e5ffRight-Click:|r Quick ARM / DISARM toggle", 0.8, 0.8, 0.8)
                tooltip:AddLine("|cff00e5ffDrag:|r Reposition Minimap Button", 0.8, 0.8, 0.8)
            end,
        })
        MM.dataObj = dataObj

        if LDBIcon then
            if not CSPAM.db.options.minimap then
                CSPAM.db.options.minimap = { hide = false }
            end
            LDBIcon:Register("CSPAM", dataObj, CSPAM.db.options.minimap)
            MM.ldbRegistered = true
            return
        end
    end

    if button then return end

    -- 2. Standalone fallback circular button (Exact standard 31x31 sizing)
    button = CreateFrame("Button", "CSPAMMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:EnableMouse(true)
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- Inset Circular Turret Icon
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    icon:SetTexture(ICON_PATH)
    button.icon = icon

    -- Circular Alpha Masking
    if button.CreateMaskTexture then
        local mask = button:CreateMaskTexture()
        mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(icon)
        icon:AddMaskTexture(mask)
        button.mask = mask
    end

    -- Drag Handlers
    button:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.deg(math.atan2(cy - my, cx - mx))
            if angle < 0 then angle = angle + 360 end
            CSPAM.db.options.minimapAngle = angle
            UpdateButtonPosition(angle)
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    -- Click Handlers
    button:SetScript("OnClick", function(self, btn)
        if btn == "LeftButton" then
            if CSPAM.UI and CSPAM.UI.Toggle then
                CSPAM.UI:Toggle()
            end
        elseif btn == "RightButton" then
            CSPAM.db.enabled = not CSPAM.db.enabled
            local statusMsg = CSPAM.db.enabled and (L["SLASH_TOGGLE_ON"] or "|cffff3b30C-SPAM:|r Interceptor |cff00ff00ARMED|r.") or (L["SLASH_TOGGLE_OFF"] or "|cffff3b30C-SPAM:|r Interceptor |cffff2020DISARMED|r.")
            DEFAULT_CHAT_FRAME:AddMessage(statusMsg)
            if CSPAM.UI and CSPAM.UI.Refresh then
                CSPAM.UI:Refresh()
            end
            MM:Refresh()
        end
    end)

    -- Rich Hover Tooltip
    button:SetScript("OnEnter", function(self)
        local x = self:GetCenter()
        local screenWidth = GetScreenWidth()
        if x and screenWidth and x < screenWidth / 2 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 4, 0)
        else
            GameTooltip:SetOwner(self, "ANCHOR_LEFT", -4, 0)
        end

        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffff3b30C-SPAM|r |cff00e5ffPhalanx Defense|r", 1, 1, 1)
        GameTooltip:AddLine(" ")

        local armed = (CSPAM.db and CSPAM.db.enabled)
        local statusText = armed and "|cff00ff00[ARMED & ACTIVE]|r" or "|cffff2020[DISARMED]|r"
        GameTooltip:AddDoubleLine("Interceptor Status:", statusText, 0.9, 0.9, 0.9, 1, 1, 1)

        local scanned = (CSPAM.db and CSPAM.db.stats and CSPAM.db.stats.totalScanned) or 0
        local filtered = (CSPAM.db and CSPAM.db.stats and CSPAM.db.stats.totalFiltered) or 0
        local pct = scanned > 0 and ((filtered / scanned) * 100) or 0
        GameTooltip:AddDoubleLine("Airspace Scanned:", string.format("|cffffffff%d|r", scanned), 0.9, 0.9, 0.9, 1, 1, 1)
        GameTooltip:AddDoubleLine("Threats Intercepted:", string.format("|cffff2020%d|r (|cff00e5ff%.1f%%|r)", filtered, pct), 0.9, 0.9, 0.9, 1, 1, 1)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00e5ffLeft-Click:|r Toggle Tactical Defense Console", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00e5ffRight-Click:|r Quick ARM / DISARM toggle", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00e5ffDrag:|r Reposition Minimap Button", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    MM.button = button
    MM:Refresh()
end

function MM:Refresh()
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LDBIcon and MM.ldbRegistered then
        local show = (CSPAM.db and CSPAM.db.options and CSPAM.db.options.showMinimap ~= false)
        if show then
            LDBIcon:Show("CSPAM")
        else
            LDBIcon:Hide("CSPAM")
        end
        return
    end

    if not button then return end
    local show = (CSPAM.db and CSPAM.db.options and CSPAM.db.options.showMinimap ~= false)
    if show then
        button:Show()
        UpdateButtonPosition()
    else
        button:Hide()
    end
end
