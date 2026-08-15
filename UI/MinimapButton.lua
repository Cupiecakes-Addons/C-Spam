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
    if button then return end

    -- Plain circular button frame with zero backdrops or square boxes
    button = CreateFrame("Button", "CSPAMMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:EnableMouse(true)
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- Clean Full Circular Turret Icon (Zero square border/backdrop)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    icon:SetTexture(ICON_PATH)
    button.icon = icon

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
            local statusMsg = CSPAM.db.enabled and L["SLASH_TOGGLE_ON"] or L["SLASH_TOGGLE_OFF"]
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
    if not button then return end
    local show = (CSPAM.db and CSPAM.db.options and CSPAM.db.options.showMinimap ~= false)
    if show then
        button:Show()
        UpdateButtonPosition()
    else
        button:Hide()
    end
end
