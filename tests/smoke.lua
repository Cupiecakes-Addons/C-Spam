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
    packs = { politics = true, sexuality = true, boosting = true, toxicity = true, nsfw = true },
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
check("epiccarry website fires", eval("visit epiccarry.net for info").shouldFilter == true)
check("8/8 heroic full clear fires", eval("WTS STARTING NOW Heroic Full clear 8/8 CHEAPEST Prices").shouldFilter == true)
check("casino roll spam fires", eval("casino is open! ROLL ANYTHING HIGHER THAN 49").shouldFilter == true)
check("israel discourse fires", eval("cucking for israel is cringe af").shouldFilter == true)
check("skill issue fires", eval("massive skill issue tbh").shouldFilter == true)
check("Cyrillic Te WTS bypass fires", eval("[W\208\162S] carry").shouldFilter == true)
check("'Selling HEROIC' ad fires", eval("Selling HEROIC VA 8/8 full clear").shouldFilter == true)
check("'Selling MYTHIC' fires", eval("Selling MYTHIC 8/8 fast").shouldFilter == true)
check("'Selling M+' fires", eval("Selling M+ keys vault cap").shouldFilter == true)
check("'coupon code' fires", eval("use coupon code 'guild' for 15% off").shouldFilter == true)
check("'off coupon' fires", eval("special 15% OFF coupon: 'guild'").shouldFilter == true)

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
check("'penis' fires (EXACT)", eval("penis jus gets in the way").shouldFilter == true)
check("'peninsula' passes ('penis' is EXACT)",
    eval("heading to the peninsula in swamp of sorrows").shouldFilter == false)

-- Political pack: reproductive rights, extremism, manosphere, drama
-- streamers and culture-war buzzwords
check("'abortion' fires", eval("abortion talk in trade again").shouldFilter == true)
check("'anti-abortion' fires via the 'abortion' token",
    eval("the anti-abortion guy is back").shouldFilter == true)
check("'prolife' fires", eval("he is prolife apparently").shouldFilter == true)
check("phrase 'planned parenthood' fires", eval("someone typed planned parenthood").shouldFilter == true)
check("'neo-nazi' fires via the 'nazi' token", eval("that is neo-nazi stuff").shouldFilter == true)
check("plural phrase 'white supremacists' fires", eval("white supremacists in general").shouldFilter == true)
check("phrase 'proud boys' fires", eval("proud boys flag guy").shouldFilter == true)
check("'zionist' fires", eval("calling everyone a zionist").shouldFilter == true)
check("'hamas' fires", eval("hamas this hamas that").shouldFilter == true)
check("leet '1nc3l' fires via incel", eval("what an 1nc3l").shouldFilter == true)
check("'looksmaxxing' fires via the 'looksmax' stem", eval("day 40 of looksmaxxing").shouldFilter == true)
check("phrase 'andrew tate' fires", eval("andrew tate clip in trade").shouldFilter == true)
check("phrase 'fresh and fit' fires", eval("fresh and fit podcast").shouldFilter == true)
check("'asmongold' fires", eval("asmongold reacted to it").shouldFilter == true)
check("phrase 'hasan piker' fires", eval("hasan piker stream tonight").shouldFilter == true)
check("'xqc' fires", eval("xqc yelling again").shouldFilter == true)
check("'kick.com' fires", eval("watch me on kick.com/somebody").shouldFilter == true)
check("phrase 'virtue signaling' fires", eval("pure virtue signaling").shouldFilter == true)
check("phrase 'cancel culture' fires", eval("cancel culture is wild").shouldFilter == true)
check("'snowflake' fires", eval("cry more snowflake").shouldFilter == true)
check("'psyop' fires", eval("it's a psyop").shouldFilter == true)
check("'cucked' fires", eval("got cucked by rng").shouldFilter == true)
check("'cuckoo' passes ('cuck' is EXACT)", eval("cuckoo clock on the wall").shouldFilter == false)
check("'grooming' passes ('groomer' is EXACT)",
    eval("grooming my pet at the stable").shouldFilter == false)
check("'kicked' passes ('kick.com' needs the domain)", eval("got kicked from the group").shouldFilter == false)
check("'abort' passes", eval("abort abort, wipe it").shouldFilter == false)
check("'mogging' passes (transmog slang, not a rule)",
    eval("mogging with my new transmog").shouldFilter == false)
check("'kkkkkk' laughter passes ('kkk' is EXACT)", eval("kkkkkk that was funny").shouldFilter == false)
check("'great replacement' gear talk passes",
    eval("a great replacement for my trinket").shouldFilter == false)
check("'simp' fires (EXACT)", eval("stop being a simp").shouldFilter == true)
check("'simping' fires (EXACT)", eval("the only thing worth simping for").shouldFilter == true)
check("'simple' passes ('simp' is EXACT)", eval("that is a simple quest").shouldFilter == false)
check("'politician' fires", eval("defend their favorite politicians online").shouldFilter == true)

-- Sexuality, Gender & Identity pack
check("'homosexual' fires", eval("talking about homosexual issues in trade").shouldFilter == true)
check("'homosexuals' fires", eval("some homosexuals were debating").shouldFilter == true)
check("'homosexuality' fires", eval("topic of homosexuality again").shouldFilter == true)
check("'heterosexual' fires", eval("he claims he is heterosexual").shouldFilter == true)
check("'bisexual' fires", eval("bisexual pride").shouldFilter == true)
check("'gay' fires", eval("that is so gay").shouldFilter == true)
check("'lesbian' fires", eval("lesbian dating guild").shouldFilter == true)
check("'lgbtq' fires", eval("lgbtq rights discussion").shouldFilter == true)
check("'trans' alone fires (EXACT)", eval("he said he is trans").shouldFilter == true)
check("leet 'tr@ns' fires via trans", eval("he is tr@ns").shouldFilter == true)
check("'transgender' fires", eval("transgender debate in trade").shouldFilter == true)
check("phrase 'trans rights' fires", eval("trans rights are human rights").shouldFilter == true)
check("phrase 'pride month' fires", eval("happy pride month everyone").shouldFilter == true)
check("phrase 'gender identity' fires", eval("discussing gender identity").shouldFilter == true)
check("'non-binary' fires via phrase", eval("identifies as non-binary").shouldFilter == true)
check("'femboy' fires", eval("what a cute femboy").shouldFilter == true)
check("'twink' fires", eval("blood elf twink guild").shouldFilter == true)
check("'ladyboy' fires", eval("ladyboy stream tonight").shouldFilter == true)
check("'shemale' fires", eval("watching shemale stuff").shouldFilter == true)
check("'crossdresser' fires", eval("he is a crossdresser").shouldFilter == true)
check("'sissy' fires", eval("sissy behavior").shouldFilter == true)
check("'deadname' fires", eval("stop deadnaming people").shouldFilter == true)
check("'misgender' fires", eval("trying to misgender everyone").shouldFilter == true)
check("'pronouns' fires", eval("what are your pronouns").shouldFilter == true)
check("phrase 'fudge packer' fires (moved from nsfw)", eval("calling him a fudge packer").shouldFilter == true)

-- WoW False-Positive Safety Checks
check("'transmog' passes ('trans' is EXACT, never CONTAINS)",
    eval("nice transmog where did you get it").shouldFilter == false)
check("'transmogrification' passes",
    eval("transmogrification vendor is near the bank").shouldFilter == false)
check("'character transfer' passes",
    eval("doing a character transfer to another realm").shouldFilter == false)
check("'transport' passes",
    eval("take the transport ship to dragon isles").shouldFilter == false)
check("'transmute' passes",
    eval("alchemy transmute cooldown available").shouldFilter == false)
check("'lion's pride inn' passes ('pride month' is a phrase)",
    eval("meet at lion's pride inn").shouldFilter == false)
check("'sha of pride' passes",
    eval("farming sha of pride for the mount").shouldFilter == false)

-- Signatures from the Sep 18-25 2026 chat log, with the near misses they
-- must leave alone
check("'Anal <spell>' spam fires", eval("Anal Obliterate").shouldFilter == true)
check("'horny' fires", eval("please stop being horny in trade chat").shouldFilter == true)
check("'big booty' fires", eval("any big booty latinas").shouldFilter == true)
check("'Booty Bay' passes ('booty' is only a phrase)",
    eval("meet me in booty bay for the pirate event").shouldFilter == false)
check("'work out the kinks' passes (no 'kinks' rule)",
    eval("still working out the kinks in my rotation").shouldFilter == false)
check("'butcher' passes ('butch' is EXACT)", eval("the butcher in stormwind has meat").shouldFilter == false)
check("'delve carries' fires", eval("WTS T11 DELVE CARRIES YOUR PREFERENCE /w").shouldFilter == true)
check("mount-run ad fires",
    eval("WTS - Need The Hivemind ? Don't lose your mind! Quick mount run, hop in and you'll find. /w").shouldFilter == true)
check("Northern Sky raid-run ad fires",
    eval("<Northern Sky> Offers Heroic & Normal raid runs every 2 hours!").shouldFilter == true)
check("'RFKJR' fires as one word", eval("if u trust RFKJR ur a drone").shouldFilter == true)
check("'jordan peterson' fires", eval("jordan peterson brainwashed him").shouldFilter == true)
check("'latinx' fires", eval("Latinx is just dumb in general").shouldFilter == true)
check("'LowTierGod' fires", eval("LowTierGod").shouldFilter == true)
check("'Nickocado' misspelling fires", eval("Nickocado Avocado got better").shouldFilter == true)
check("'fatty' fires", eval("get an education fatty").shouldFilter == true)

-- Sugar dating and daddy/mommy slang, without the ordinary words inside them
check("'daddy' fires", eval("seeing daddy denathrius again").shouldFilter == true)
check("'sugar daddy' fires via the daddy token", eval("LF sugar daddy pst").shouldFilter == true)
check("'sugar baby' fires", eval("looking for a sugar baby").shouldFilter == true)
check("'sugarbaby' fires as one word", eval("any sugarbaby on").shouldFilter == true)
check("stretched 'mommyyy' fires (repeat collapse)", eval("goth mommyyy").shouldFilter == true)
check("'sugar' alone passes (a character name)", eval("what about sugar").shouldFilter == false)
check("'baby murloc' passes", eval("wts baby murloc pet").shouldFilter == false)
check("'stepsister' passes (only the slang forms are rules)",
    eval("my stepsister plays a paladin").shouldFilter == false)

-- Owner's calls on rules that hit ordinary chat (2026-09-25). Removed: WoW
-- has a Hardcore game mode and Sylvanas is lore. Kept on purpose, even
-- though they catch these lines: "woke" is a political term in any sense,
-- and the boosting pack blocks all carry/achievement talk.
check("'Classic Hardcore' passes ('hardcore' removed)",
    eval("Classic Hardcore was pretty sick, there was a small RP scene too").shouldFilter == false)
check("Sylvanas lore passes ('sylvanas' removed)",
    eval("Why didn't Sylvanas burn Silvermoon too?").shouldFilter == false)
check("'woke' fires even as a verb (kept by choice)",
    eval("a chicken bone fell out and woke la magra up").shouldFilter == true)
check("'aotc' fires in guild recruitment (kept by choice)",
    eval("semi casual pve guild seeking dps for AOTC").shouldFilter == true)
check("'power level' fires (kept by choice)",
    eval("i am slamming tw dungeons to power level").shouldFilter == true)
check("'ahead of the curve' fires (kept by choice)",
    eval("is Ahead of the Curve still a thing?").shouldFilter == true)

-- Leet decoding also rewrites 'v' -> 'u', so rules containing a 'v' carry a
-- decoded twin; without it, leet anywhere in the message hid them
check("leet 'p0wer leveling' fires (rule contains a 'v')", eval("WTS p0wer leveling 1-80").shouldFilter == true)
check("leet 'v@nce' fires via the decoded twin of 'vance'", eval("v@nce 2028").shouldFilter == true)
check("leet 's@ved heroic' fires", eval("s@ved heroic runs tonight").shouldFilter == true)
check("'die' passes (the leet-spelled rule 'd1e' gets no twin)",
    eval("dont die to the first mechanic").shouldFilter == false)

-- Phrases are looked up by first word; every one must stay reachable, both
-- as written and leet-spelled
do
    local function leetSpell(s) return (s:gsub("o", "0"):gsub("e", "3")) end
    local missed, missedLeet = {}, {}
    for packKey, pack in pairs(CSPAM.Packs) do
        for _, w in ipairs(pack.words) do
            local mode = w.mode:upper()
            local cleaned = w.text:lower():gsub("[%p%c]", " "):gsub("%s+", " "):trim()
            if (mode == "PHRASE" or mode == "EXACT") and cleaned:find(" ") then
                if not eval("so " .. w.text .. " ok").shouldFilter then
                    missed[#missed + 1] = w.text
                end
                if not eval("so " .. leetSpell(w.text:lower()) .. " ok").shouldFilter then
                    missedLeet[#missedLeet + 1] = leetSpell(w.text:lower())
                end
            end
        end
    end
    if #missed > 0 then print("      missed: " .. table.concat(missed, "; ")) end
    if #missedLeet > 0 then print("      missed leet: " .. table.concat(missedLeet, "; ")) end
    check("every phrase rule fires inside a sentence", #missed == 0)
    check("every phrase rule fires leet-spelled (o->0, e->3)", #missedLeet == 0)
end

-- Escapes spliced in by the client or other addons never reach the matcher
do
    local N = CSPAM.Normalizer
    local EMOJI = "|TInterface\\AddOns\\ElvUI\\Game\\Shared\\Media\\ChatEmojis\\Heart:16:16|t"
    local n1 = N.NormalizeMessage(EMOJI .. " hello " .. EMOJI)
    check("texture icon paths are not tokenized",
        n1.tokens.elvui == nil and n1.tokens.interface == nil and n1.tokens.hello == true)
    local n2 = N.NormalizeMessage("WTB |cnIQ4:|Hitem:212456::::::::80:::::|h[Everburning Ignition]|h|r pst")
    check("named-color (|cnIQ4:) link is extracted whole",
        #n2.links == 1 and n2.tokens.cniq4 == nil and n2.tokens.r == nil and n2.tokens.everburning == true)
    check("keyword wrapped in another addon's color code still fires",
        eval("|cffff0000trump|r rally tonight").shouldFilter == true)
end

-- MASK censors whole words for EXACT/PHRASE and substrings for CONTAINS
CSPAM.db.action = "MASK"
E:InvalidateCache()
check("MASK leaves 'Goldshire' alone when censoring 'gold'",
    eval("got gold near Goldshire").maskedText == "got **** near Goldshire")
check("MASK keeps exact spacing around links",
    eval("gold |cff0070dd|Hitem:19019::::::::80:::::|h[Thunderfury]|h|r pst").maskedText
        == "**** |cff0070dd|Hitem:19019::::::::80:::::|h[Thunderfury]|h|r pst")
check("MASK still censors CONTAINS matches inside words",
    eval("clicky links here").maskedText == "clicky ****s here")
CSPAM.db.action = "HIDE"
E:InvalidateCache()

-- Single-token rules from every pack share one index, so a term listed in two
-- packs silently overwrites the first and pairs() order decides which pack
-- the log credits. EXACT/PHRASE are compared in their cleaned form, the same
-- space RebuildIndex compiles them into.
do
    local seen, dupes = {}, {}
    for packKey, pack in pairs(CSPAM.Packs) do
        for _, w in ipairs(pack.words) do
            local mode = w.mode:upper()
            local key
            if mode == "EXACT" or mode == "PHRASE" then
                key = "W:" .. w.text:lower():gsub("[%p%c]", " "):gsub("%s+", " "):trim()
            else
                key = mode .. ":" .. w.text:lower()
            end
            if seen[key] then
                dupes[#dupes + 1] = string.format("'%s' (%s, %s)", w.text, seen[key], packKey)
            else
                seen[key] = packKey
            end
        end
    end
    if #dupes > 0 then
        print("      duplicates: " .. table.concat(dupes, "; "))
    end
    check("no duplicate signatures across packs", #dupes == 0)
end

print(failures == 0 and "ALL PASS" or (failures .. " FAILURES"))
os.exit(failures == 0 and 0 or 1)
