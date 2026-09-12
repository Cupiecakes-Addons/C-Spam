-- Offline test for C-Spam FilterListUI detail view.
-- Runs with LuaJIT to test frame creation and row population.
string.trim = function(s) return (s:match("^%s*(.-)%s*$")) end
table.wipe = table.wipe or function(t) for k in pairs(t) do t[k] = nil end return t end
time = os.time
date = os.date

local function mockFrame(frameType, name, parent, template)
    local f = {
        _name = name,
        _parent = parent,
        _type = frameType,
        _shown = true,
        _points = {},
        _scripts = {},
    }
    function f:SetSize(w, h) self._w, self._h = w, h end
    function f:SetWidth(w) self._w = w end
    function f:SetHeight(h) self._h = h end
    function f:RegisterEvent() end
    function f:UnregisterEvent() end
    function f:SetPoint(pt, rel, rpt, x, y) table.insert(self._points, { pt, rel, rpt, x, y }) end
    function f:SetAllPoints(...) end
    function f:ClearAllPoints() self._points = {} end
    function f:Show() self._shown = true end
    function f:Hide() self._shown = false end
    function f:IsShown() return self._shown end
    function f:SetScript(evt, fn) self._scripts[evt] = fn end
    function f:GetScript(evt) return self._scripts[evt] end
    function f:HookScript(evt, fn) self._scripts[evt] = fn end
    function f:SetBackdrop(t) self._backdrop = t end
    function f:SetBackdropColor(r, g, b, a)
        assert(r ~= nil and g ~= nil and b ~= nil, "SetBackdropColor called with nil color component!")
        self._bgColor = { r, g, b, a }
    end
    function f:SetBackdropBorderColor(r, g, b, a) self._borderColor = { r, g, b, a } end
    function f:CreateFontString(name, layer, inherit)
        local fs = mockFrame("FontString", name, self)
        fs._text = ""
        function fs:SetText(t) self._text = t end
        function fs:GetText() return self._text end
        function fs:SetTextColor(r, g, b, a) end
        function fs:SetJustifyH(j) end
        function fs:SetWordWrap(w) end
        function fs:GetStringWidth() return #self._text * 7 end
        return fs
    end
    function f:CreateTexture(name, layer)
        local tex = mockFrame("Texture", name, self)
        function tex:SetTexture(t) self._tex = t end
        return tex
    end
    function f:SetScrollChild(c) self._scrollChild = c end
    function f:SetVerticalScroll(v) self._vScroll = v end
    function f:GetVerticalScroll() return self._vScroll or 0 end
    function f:GetVerticalScrollRange() return 100 end
    function f:EnableMouse(b) end
    function f:EnableMouseWheel(b) end
    function f:RegisterForDrag(...) end
    function f:SetFrameStrata(s) end
    function f:SetClampedToScreen(b) end
    function f:SetMovable(b) end
    function f:SetChecked(b) self._checked = b end
    function f:GetChecked() return self._checked end
    function f:IsEnabled() return true end
    function f:SetText(t) self._text = t if self.text and self.text.SetText then self.text:SetText(t) end end
    function f:GetText() return self._text or "" end
    function f:SetMultiLine(b) end
    function f:SetAutoFocus(b) end
    function f:SetFontObject(fo) end
    function f:SetFont(...) end
    function f:SetTextInsets(l, r, t, b) end
    function f:ClearFocus() end
    function f:SetColorTexture(r, g, b, a) self._colorTex = { r, g, b, a } end
    function f:GetWidth() return self._w or 600 end
    function f:GetHeight() return self._h or 400 end
    function f:SetNormalFontObject(fo) end
    function f:SetHighlightFontObject(fo) end
    function f:SetDisabledFontObject(fo) end
    function f:SetMaxLetters(n) end
    function f:SetHyperlinksEnabled(b) self._hyperlinks = b end
    function f:GetHyperlinksEnabled() return self._hyperlinks end
    return f
end

CreateFrame = mockFrame
UIParent = mockFrame("Frame", "UIParent")
GameTooltip = mockFrame("GameTooltip", "GameTooltip")
function GameTooltip:SetOwner(o, a) self._owner = o end
function GameTooltip:GetOwner() return self._owner end
function GameTooltip:ClearLines() self._lines = {} end
function GameTooltip:AddLine(t) table.insert(self._lines, t) end
function GameTooltip:SetHyperlink(link) self._hyperlink = link end

local itemRefCalls = {}
SetItemRef = function(link, text, button, frame)
    table.insert(itemRefCalls, { link = link, text = text, button = button, frame = frame })
end

C_Timer = {
    After = function(delay, fn) fn() end,
    NewTicker = function(interval, fn)
        return { Cancel = function() end }
    end,
}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) end }
UISpecialFrames = {}
SlashCmdList = {}
tinsert = table.insert
UnitName = function() return "Tester" end
IsInGuild = function() return false end
IsInGroup = function() return false end
IsInRaid = function() return false end
GetNumGuildMembers = function() return 0 end
GetNumGroupMembers = function() return 0 end
GetGuildRosterInfo = function() return nil end

local CSPAM = {}
local function loadaddon(path)
    local chunk = assert(loadfile(path))
    chunk("C-Spam", CSPAM)
end

loadaddon("Locales/enUS.lua")
loadaddon("Data/DefaultPacks.lua")
loadaddon("Core/Init.lua")
loadaddon("Core/Normalizer.lua")
loadaddon("Core/Engine.lua")
loadaddon("UI/FilterListUI.lua")

CSPAM.db = {
    enabled = true,
    action = "HIDE",
    packs = { politics = true, boosting = false, toxicity = true, nsfw = true },
    customWords = {},
    whitelist = { friends = true, guild = true, party = true, characters = {} },
    channelGroups = {},
    options = { checkLeet = true, collapseRepeats = true, logFiltered = true, maxLogEntries = 100 },
    filteredLog = {},
    stats = { totalScanned = 0, totalFiltered = 0 },
}

print("Running FilterListUI Test...")
CSPAM.UI:Init()

local p2 = CSPAM.UI.contentPanels and CSPAM.UI.contentPanels[2]
assert(p2, "contentPanels[2] not found!")

for _, packKey in ipairs({ "politics", "boosting", "toxicity", "nsfw" }) do
    local pack = CSPAM.Packs[packKey]
    print(string.format("Testing ShowDetail for pack '%s' (%d words)...", packKey, #pack.words))
    local ok, err = pcall(function()
        p2.ShowDetail(packKey)
    end)
    if not ok then
        print(string.format("FAIL: ShowDetail('%s') crashed: %s", packKey, tostring(err)))
        os.exit(1)
    end
    
    local rows = p2.detailScrollContent.rows
    local shownCount = 0
    for _, r in ipairs(rows) do
        if r:IsShown() then
            shownCount = shownCount + 1
        end
    end
    print(string.format("  -> Shown rows: %d / Expected: %d", shownCount, #pack.words))
    assert(shownCount == #pack.words, string.format("Expected %d shown rows but got %d!", #pack.words, shownCount))
end

print("Testing search filter in detail view...")
p2.ShowDetail("politics")
p2.searchBox:SetText("trump")
p2.searchBox:GetScript("OnTextChanged")(p2.searchBox)
local trumpRows = 0
for _, r in ipairs(p2.detailScrollContent.rows) do
    if r:IsShown() then
        trumpRows = trumpRows + 1
    end
end
print(string.format("  -> Filtered 'trump' rows: %d", trumpRows))
assert(trumpRows > 0, "Search for 'trump' should have returned matches!")

print("Testing HideDetail()...")
p2.HideDetail()
assert(p2.cardsView:IsShown(), "cardsView should be shown after HideDetail")
assert(not p2.detailView:IsShown(), "detailView should be hidden after HideDetail")

print("Testing Tab 3 Intercept Log hyperlinks...")
table.insert(CSPAM.db.filteredLog, {
    timestamp = os.time(),
    sender = "Cilette-MoonGuard",
    channel = "Trade",
    matched = "ksh",
    category = "Boosting",
    message = "WTS |cffa335ee|Hitem:228514:0:0:0:0:0:0:0|h[Ashes of Belo'ren]|h|r and |cffffff00|Hachievement:1234:0:0:0:0:0:0:0|h[Ahead of the Curve]|h|r",
})

CSPAM.UI:Toggle()

-- Switch to Tab 3
local tabBtns = CSPAM.UI.tabButtons
if tabBtns and tabBtns[3] then
    tabBtns[3]:GetScript("OnClick")(tabBtns[3])
end

local p3 = CSPAM.UI.contentPanels and CSPAM.UI.contentPanels[3]
assert(p3, "contentPanels[3] not found!")
assert(p3.logContent and p3.logContent.rows and #p3.logContent.rows > 0, "No log rows created in Tab 3!")

local logRow = p3.logContent.rows[1]
assert(logRow:IsShown(), "Log row 1 should be shown!")
assert(logRow:GetHyperlinksEnabled() == true, "Log row 1 must have hyperlinks enabled!")

-- 1. Test hover over item link
logRow:GetScript("OnHyperlinkEnter")(logRow, "item:228514:0:0:0:0:0:0:0", "[Ashes of Belo'ren]")
assert(GameTooltip:IsShown(), "GameTooltip should be shown on item hyperlink enter!")
assert(GameTooltip._hyperlink == "item:228514:0:0:0:0:0:0:0", "GameTooltip should have received the item hyperlink!")

-- 2. Test hover leave
logRow:GetScript("OnHyperlinkLeave")(logRow)
assert(not GameTooltip:IsShown(), "GameTooltip should be hidden on hyperlink leave!")

-- 3. Test click on achievement link
logRow:GetScript("OnHyperlinkClick")(logRow, "achievement:1234:0:0:0:0:0:0:0", "[Ahead of the Curve]", "LeftButton")
assert(#itemRefCalls == 1, "SetItemRef should have been called once!")
assert(itemRefCalls[1].link == "achievement:1234:0:0:0:0:0:0:0", "SetItemRef should have received the achievement link!")

-- 4. Test click on player link
logRow:GetScript("OnHyperlinkClick")(logRow, "player:Cilette-MoonGuard", "Cilette-MoonGuard", "LeftButton")
assert(#itemRefCalls == 2, "SetItemRef should have been called twice!")
assert(itemRefCalls[2].link == "player:Cilette-MoonGuard", "SetItemRef should have received the player link!")

-- 5. Test mouse wheel forwarding
local scrolledDelta = 0
p3.scrollFrame:SetScript("OnMouseWheel", function(self, delta) scrolledDelta = delta end)
logRow:GetScript("OnMouseWheel")(logRow, -1)
assert(scrolledDelta == -1, "Mouse wheel on log row must forward to p3.scrollFrame!")
print("  -> All Tab 3 hyperlink & mousewheel tests passed!")

print("ALL UI TESTS PASSED!")
