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
    packs = { politics = true, boosting = true, toxicity = true, nsfw = true },
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

-- Live-spam replay: modern raid-sale ads avoid classic boost/carry/gold words
local RAID_LINK = "|cff66bbff|Hjournal:0:1300:16|h[The Voidspire]|h|r"
check("raid-sale boilerplate fires (saved heroic / gold only)",
    eval("WTS BEST SERVICE. " .. RAID_LINK .. " SPOREFALL SAVED HEROIC [GOLD ONLY - PAY IN RAID] PM for booking.").shouldFilter == true)
check("'WTS M+0 Dungeons' fires via 'wts m+'",
    eval("[WTS M+0 Dungeons. Buy 6, Get 2 FREE! Starts within a few minutes!]").shouldFilter == true)
check("legit 'saved to heroic' passes",
    eval("i got saved to heroic tonight so cant come").shouldFilter == false)

-- Renamed-battle-pet trick: the whole ad lives in link DISPLAY text
local PET_AD = "|cff0070dd|Hbattlepet:162:25:3:1546:325:278:BattlePet-0-000B1DE348|h[WTS M+0 Dungeons. Buy 6, Get 2 FREE!]|h|r Book early. "
    .. "|cff0070dd|Hbattlepet:162:25:3:1546:325:278:BattlePet-0-000B1DE349|h[Visit gamer-choice.com]|h|r"
check("ad hidden in link display text fires", eval(PET_AD).shouldFilter == true)
local STORE_AD = "|cffffd000|Hquest:12345:70|h[GREAT VAULT]|h|r Your S2 Vault fills NOW, unlocks Aug 19 "
    .. "|cff66bbff|Hquest:12346:70|h[MythicStore.com]|h|r"
check("mythicstore link ad fires", eval(STORE_AD).shouldFilter == true)

check("safe character bypasses", eval("m+ carry cheap", "Baddie-Realm").shouldFilter == false)
check("IsValidMode rejects HTTPS / accepts phrase",
    E:IsValidMode("HTTPS") == false and E:IsValidMode("phrase") == true)
check("'newts moved' passes ('wts m+' anchored)",
    eval("newts moved into my garden").shouldFilter == false)

-- NSFW pack: the goon family is EXACT, so it matches whole tokens only
check("'gooning' fires", eval("anyone else gooning tonight").shouldFilter == true)
check("'gooner' fires", eval("what a gooner").shouldFilter == true)
check("'goon' alone fires", eval("straight up goon behavior").shouldFilter == true)
check("stretched 'goooooning' fires (repeat collapse)",
    eval("bro is goooooning").shouldFilter == true)
check("leet 'g00ning' fires", eval("he is g00ning again").shouldFilter == true)
-- Substring safety: EXACT is a token-set lookup, not a find()
check("'dragoon' passes (not a goon token)",
    eval("my dragoon transmog looks great").shouldFilter == false)
check("'lagoon' passes (not a goon token)",
    eval("meet me at the lagoon in vashjir").shouldFilter == false)

-- Masturbation stems are CONTAINS, so the whole family is two rules
check("'masturbating' fires via stem", eval("stop masturbating in trade").shouldFilter == true)
check("'masturbation' fires via stem", eval("no masturbation talk please").shouldFilter == true)
check("misspelled 'masterbate' fires", eval("he said masterbate lol").shouldFilter == true)

-- NSFW pack, wider signature set. CONTAINS stems catch whole families...
check("'motherfucker' fires via 'fuck' stem", eval("motherfucker that was close").shouldFilter == true)
check("'bullshit' fires via 'shit' stem", eval("this is bullshit honestly").shouldFilter == true)
check("'dickhead' fires", eval("he is a total dickhead").shouldFilter == true)
check("'onlyfans' fires", eval("check my onlyfans link").shouldFilter == true)
check("phrase 'deez nuts' fires", eval("hit em with the deez nuts joke").shouldFilter == true)
-- ...while short anatomical terms stay EXACT so they cannot match inside words
check("'class/assist/pass' pass ('ass' is EXACT)",
    eval("great class, nice assist, pass me the flag").shouldFilter == false)
check("'titan/title' pass ('tits' is EXACT)",
    eval("titan forged title on that item").shouldFilter == false)
check("'document/cucumber' pass ('cum' is EXACT)",
    eval("documented accumulation, cucumber salad").shouldFilter == false)
check("'coarse/sparse/parse' pass ('arse' is EXACT)",
    eval("coarse hoarse sparse parse").shouldFilter == false)
check("'analysis/analyze' pass ('anus' is EXACT)",
    eval("running analysis to analyze the logs").shouldFilter == false)
check("'scatter shot' passes ('scat' is EXACT)",
    eval("scatter shot then disengage").shouldFilter == false)
check("'cockatrice/peacock' pass ('cock' is EXACT)",
    eval("cockatrice eye and a peacock feather").shouldFilter == false)
check("'buttress' passes ('butt' is EXACT)",
    eval("buttress the wall on the left").shouldFilter == false)

print(failures == 0 and "ALL PASS" or (failures .. " FAILURES"))
os.exit(failures == 0 and 0 or 1)
