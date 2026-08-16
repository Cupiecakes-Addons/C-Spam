-- Offline smoke test for C-Spam Core.
-- Run from the repo root with LuaJIT (same Lua 5.1 dialect WoW uses):
--   luajit tests/smoke.lua
-- Stubs the handful of WoW APIs the Core modules touch, loads the real
-- Normalizer/Engine/DefaultPacks, and asserts end-to-end filter behavior.
string.trim = function(s) return (s:match("^%s*(.-)%s*$")) end
table.wipe = table.wipe or function(t) for k in pairs(t) do t[k] = nil end return t end
time = os.time
CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end }
end
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
loadaddon("Data/DefaultPacks.lua")
loadaddon("Core/Normalizer.lua")
loadaddon("Core/Engine.lua")

CSPAM.db = {
    enabled = true,
    action = "HIDE",
    packs = { politics = true, boosting = true, toxicity = true },
    customWords = {
        { text = "link", mode = "CONTAINS", enabled = true },
        { text = "gold", mode = "EXACT", enabled = true },
    },
    whitelist = { friends = true, guild = true, party = true, characters = { baddie = true } },
    channelGroups = {},
    options = { checkLeet = true, collapseRepeats = true, logFiltered = true, maxLogEntries = 100 },
    filteredLog = {},
    stats = { totalScanned = 0, totalFiltered = 0 },
}

local E = CSPAM.Engine
E:RebuildIndex()

local nextLine = 0
local function eval(msg, sender, lineID)
    if not lineID then
        nextLine = nextLine + 1
        lineID = nextLine
    end
    return E:EvaluateMessage(msg, sender or "Spammer", nil, "Trade", lineID)
end

local failures = 0
local function check(name, cond)
    print((cond and "PASS  " or "FAIL  ") .. name)
    if not cond then failures = failures + 1 end
end

check("phrase 'm+ carry' fires", eval("WTS M+ CARRY cheap runs!").shouldFilter == true)
check("leet 'trvmp' fires via trump", eval("vote trvmp 2028").shouldFilter == true)
check("spaced 't r u m p' fires", eval("t r u m p rally now").shouldFilter == true)
check("collapsed 'trumpppp' fires", eval("trumpppp lol").shouldFilter == true)
check("innocent message passes", eval("anyone up for a dungeon?").shouldFilter == false)

local linked = "|cff0070dd|Hitem:19019::::::::80:::::|h[Thunderfury]|h|r for sale 500"
check("item link does not trip CONTAINS 'link'", eval(linked).shouldFilter == false)

CSPAM.db.action = "MASK"
E:InvalidateCache()
local r = eval("WTS GOLD CHEAP")
check("MASK censors 'WTS GOLD CHEAP'", r.shouldFilter == true and r.maskedText == "WTS **** CHEAP")
local r2 = eval((linked:gsub("for sale", "gold sale")))
check("MASK keeps hyperlink intact",
    r2.shouldFilter == true
    and r2.maskedText:find("|Hitem:", 1, true) ~= nil
    and r2.maskedText:find("****", 1, true) ~= nil)
CSPAM.db.action = "HIDE"
E:InvalidateCache()

local before = CSPAM.db.stats.totalScanned
eval("unique message alpha bravo", "Spammer", 999)
eval("unique message alpha bravo", "Spammer", 999) -- same line id: second chat frame
check("same lineID counted once", CSPAM.db.stats.totalScanned == before + 1)

CSPAM.db.filteredLog = {}
local filteredBefore = CSPAM.db.stats.totalFiltered
eval("WTS M+ CARRY spamrun", "GoldBot", 1001)
eval("WTS M+ CARRY spamrun", "GoldBot", 1002)
eval("WTS M+ CARRY spamrun", "GoldBot", 1003)
check("repeat spam aggregates in log",
    #CSPAM.db.filteredLog == 1 and CSPAM.db.filteredLog[1].count == 3)
check("repeats still counted in stats", CSPAM.db.stats.totalFiltered == filteredBefore + 3)

check("safe character bypasses", eval("m+ carry cheap", "Baddie-Realm").shouldFilter == false)
check("IsValidMode rejects HTTPS / accepts phrase",
    E:IsValidMode("HTTPS") == false and E:IsValidMode("phrase") == true)
check("'newts moved' passes ('wts m+' anchored)",
    eval("newts moved into my garden").shouldFilter == false)

print(failures == 0 and "ALL PASS" or (failures .. " FAILURES"))
os.exit(failures == 0 and 0 or 1)
