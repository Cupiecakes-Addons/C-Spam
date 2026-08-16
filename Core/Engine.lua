local addonName, CSPAM = ...

CSPAM.Engine = {}
local E = CSPAM.Engine

-- Escape Lua pattern magic characters so text can be matched literally
local function EscapePattern(str)
    return (str:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

local VALID_MODES = { EXACT = true, CONTAINS = true, PHRASE = true, REGEX = true, PATTERN = true }
function E:IsValidMode(mode)
    return mode ~= nil and VALID_MODES[mode:upper()] == true
end

-- Compiled Index Tables
local exactWords = {}
local containsList = {}
local phraseList = {}
local regexList = {}

-- Decision cache for repeat spam payloads, keyed by the raw message string
-- itself (Lua interns strings, so lookups are O(1) with no collision risk).
-- Entries live in a fixed ring: each key owns exactly one slot, and inserting
-- into an occupied slot evicts that slot's previous key.
local decisionCache = {}
local cacheSlots = {}
local cacheSlotIdx = 0
local MAX_CACHE_SIZE = 128
local CACHE_TTL = 20

local function CacheDecision(key, matched, result)
    local entry = decisionCache[key]
    if entry then
        entry.time, entry.matched, entry.result = time(), matched, result
        return
    end
    cacheSlotIdx = (cacheSlotIdx % MAX_CACHE_SIZE) + 1
    local evicted = cacheSlots[cacheSlotIdx]
    if evicted ~= nil then
        decisionCache[evicted] = nil
    end
    cacheSlots[cacheSlotIdx] = key
    decisionCache[key] = { time = time(), matched = matched, result = result }
end

-- Wipe cached decisions; called whenever anything that influences a verdict
-- changes (rules, engagement action, normalizer options)
function E:InvalidateCache()
    table.wipe(decisionCache)
    table.wipe(cacheSlots)
    cacheSlotIdx = 0
end

function E:RebuildIndex()
    table.wipe(exactWords)
    table.wipe(containsList)
    table.wipe(phraseList)
    table.wipe(regexList)
    self:InvalidateCache()

    -- EXACT/PHRASE rule text is cleaned exactly like incoming messages
    -- (punctuation -> spaces), so both sides live in the same normalized
    -- space and rules like "m+ carry" or "pro-life" can actually match.
    local function AddRule(text, mode, category, packName)
        if not text or text == "" then return end
        local modeUpper = (mode or "EXACT"):upper()

        if modeUpper == "EXACT" or modeUpper == "PHRASE" then
            local cleanText = text:lower():gsub("[%p%c]", " "):gsub("%s+", " "):trim()
            local words = {}
            for w in cleanText:gmatch("%S+") do
                words[#words + 1] = w
            end

            if #words == 1 then
                -- Single tokens match via the O(1) token set
                exactWords[words[1]] = { text = text, mode = modeUpper, category = category, pack = packName }
            elseif #words > 1 then
                -- Multi-word entries (including multi-word EXACT input, which a
                -- single whitespace-free token could never satisfy) compile to a
                -- word-boundary-anchored phrase pattern
                for i = 1, #words do
                    words[i] = EscapePattern(words[i])
                end
                table.insert(phraseList, {
                    raw = text,
                    pattern = "%f[%w]" .. table.concat(words, "%s+") .. "%f[%W]",
                    category = category,
                    pack = packName,
                })
            end
        elseif modeUpper == "CONTAINS" then
            local lowered = text:lower():trim()
            if lowered ~= "" then
                -- Matched with plain (non-pattern) find; no escaping needed
                table.insert(containsList, {
                    raw = text,
                    text = lowered,
                    category = category,
                    pack = packName,
                })
            end
        elseif modeUpper == "REGEX" or modeUpper == "PATTERN" then
            table.insert(regexList, {
                raw = text,
                pattern = text,
                category = category,
                pack = packName,
            })
        end
    end

    -- 1. Index active default packs
    if CSPAM.Packs and CSPAM.db and CSPAM.db.packs then
        for packKey, packData in pairs(CSPAM.Packs) do
            if CSPAM.db.packs[packKey] and packData.words then
                for _, entry in ipairs(packData.words) do
                    AddRule(entry.text, entry.mode, packData.name, packKey)
                end
            end
        end
    end

    -- 2. Index custom user rules
    if CSPAM.db and CSPAM.db.customWords then
        for _, entry in ipairs(CSPAM.db.customWords) do
            if entry.enabled ~= false and entry.text and entry.text ~= "" then
                AddRule(entry.text, entry.mode or "EXACT", entry.category or "Custom", "custom")
            end
        end
    end
end

-- IFF Check (Identification Friend or Foe)
function E:IsSenderWhitelisted(senderName, senderGUID)
    if not senderName or senderName == "" then return false end
    local db = CSPAM.db
    if not db or not db.whitelist then return false end

    -- Self is always friendly
    local playerName = UnitName("player")
    if senderName == playerName or senderName:match("^" .. playerName .. "%-") then
        return true
    end

    -- 1. Friends list (BNet & Character)
    if db.whitelist.friends then
        if C_FriendList and C_FriendList.IsFriend then
            if senderGUID and C_FriendList.IsFriend(senderGUID) then return true end
        end
        local numFriends = C_FriendList.GetNumFriends and C_FriendList.GetNumFriends() or 0
        for i = 1, numFriends do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.name and (info.name == senderName or senderName:match("^" .. info.name .. "%-")) then
                return true
            end
        end
        if BNGetNumFriends then
            local numBNet = BNGetNumFriends()
            for i = 1, numBNet do
                local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
                if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName then
                    local cName = accountInfo.gameAccountInfo.characterName
                    if cName == senderName or senderName:match("^" .. cName .. "%-") then
                        return true
                    end
                end
            end
        end
    end

    -- 2. Guild Members
    if db.whitelist.guild and IsInGuild() then
        local numGuild = GetNumGuildMembers()
        for i = 1, numGuild do
            local name = GetGuildRosterInfo(i)
            if name and (name == senderName or name:match("^" .. senderName .. "%-") or senderName:match("^" .. name .. "%-")) then
                return true
            end
        end
    end

    -- 3. Party & Raid Members
    if db.whitelist.party and (IsInGroup() or IsInRaid()) then
        local numGroup = GetNumGroupMembers()
        local unitPrefix = IsInRaid() and "raid" or "party"
        for i = 1, numGroup do
            local unit = (unitPrefix == "party" and i == numGroup) and "player" or (unitPrefix .. i)
            local name, realm = UnitName(unit)
            if name then
                local fullName = realm and (name .. "-" .. realm) or name
                if fullName == senderName or name == senderName then
                    return true
                end
            end
        end
    end

    return false
end

-- Case- and leet-tolerant character classes for masking: "gold" becomes
-- "[gG69][oO0][lL|][dD]" so the censor can locate words the normalizer
-- matched regardless of case or leet substitutions in the original text.
local leetAliases = nil
local function GetLeetAliases()
    if not leetAliases then
        leetAliases = {}
        local map = CSPAM.Normalizer and CSPAM.Normalizer.LEET_MAP
        if map then
            for sym, letter in pairs(map) do
                local entry = EscapePattern(sym)
                if sym:match("^%a$") then
                    entry = entry .. sym:upper()
                end
                leetAliases[letter] = (leetAliases[letter] or "") .. entry
            end
        end
    end
    return leetAliases
end

local function FuzzyWordPattern(word)
    local aliases = GetLeetAliases()
    return (EscapePattern(word:lower()):gsub("%a", function(c)
        return "[" .. c .. c:upper() .. (aliases[c] or "") .. "]"
    end))
end

-- Electronic Jamming (Mask target words with asterisks)
function E:MaskMessage(rawMessage, matchedText, norm)
    if not matchedText or matchedText == "" then return rawMessage end

    local extracted, links = norm.extracted, norm.links

    -- Multi-word matches (PHRASE rules) tolerate any whitespace between words
    local words = {}
    for w in matchedText:gmatch("%S+") do
        words[#words + 1] = FuzzyWordPattern(w)
    end
    if #words == 0 then return rawMessage end

    local masked, count = extracted:gsub(table.concat(words, "%s+"), function(found)
        return string.rep("*", #found)
    end)

    if count == 0 then
        -- The rule matched a normalized variant (collapsed repeats, homoglyphs,
        -- REGEX pattern text) that cannot be located in the original message.
        -- Censor the whole payload rather than let confirmed spam through
        -- unmasked; hyperlinks are dropped along with it.
        masked = string.rep("*", 12)
        links = nil
    end

    return CSPAM.Normalizer.RestoreLinks(masked, links)
end

-- Record an intercepted message in the rolling log; identical repeats from
-- the same sender aggregate into the newest entry instead of flooding it
function E:LogIntercept(result, rawMessage, senderName, channelName)
    local db = CSPAM.db
    if not db.options.logFiltered then return end

    local log = db.filteredLog
    local newest = log[1]
    if newest and newest.message == rawMessage and newest.sender == (senderName or "Unknown") then
        newest.count = (newest.count or 1) + 1
        newest.timestamp = time()
    else
        table.insert(log, 1, {
            timestamp = time(),
            sender = senderName or "Unknown",
            channel = channelName or "Sector",
            matched = result.matchedWord or "Signature",
            category = result.category or "Custom",
            message = rawMessage,
        })
        while #log > (db.options.maxLogEntries or 100) do
            table.remove(log)
        end
    end

    -- Live UI update if Intercept Log tab is open
    if CSPAM.UI and CSPAM.UI.OnLogUpdated then
        CSPAM.UI:OnLogUpdated()
    end
end

-- Full (uncached) rule evaluation; caches its verdict
local function EvaluateFresh(self, rawMessage, senderName, channelName)
    local db = CSPAM.db
    local norm = CSPAM.Normalizer.NormalizeMessage(rawMessage, db.options)
    local matchedRule = nil
    local matchedWord = nil

    -- 1. O(1) Fast-Path Token Set Matching
    if norm.tokens then
        for token, _ in pairs(norm.tokens) do
            local rule = exactWords[token]
            if rule then
                matchedRule = rule
                matchedWord = token
                break
            end
        end
    end

    -- Check leet decoded tokens
    if not matchedRule and norm.leetTokens then
        for token, _ in pairs(norm.leetTokens) do
            local rule = exactWords[token]
            if rule then
                matchedRule = rule
                matchedWord = token
                break
            end
        end
    end

    -- 2. Phrase Matching (compiled patterns)
    if not matchedRule and #phraseList > 0 then
        for _, rule in ipairs(phraseList) do
            if norm.cleaned:find(rule.pattern) or (norm.leetClean and norm.leetClean:find(rule.pattern)) then
                matchedRule = rule
                matchedWord = rule.raw
                break
            end
        end
    end

    -- 3. Contains / Substring Scanning (plain find: no pattern compilation)
    if not matchedRule and #containsList > 0 then
        for _, rule in ipairs(containsList) do
            if norm.lower:find(rule.text, 1, true) or (norm.leetClean and norm.leetClean:find(rule.text, 1, true)) then
                matchedRule = rule
                matchedWord = rule.raw
                break
            end
        end
    end

    -- 4. Advanced Regex Patterns (pcall protected)
    if not matchedRule and #regexList > 0 then
        for _, rule in ipairs(regexList) do
            local ok, matchStart = pcall(string.find, norm.lower, rule.pattern)
            if ok and matchStart then
                matchedRule = rule
                matchedWord = rule.raw
                break
            end
        end
    end

    local result
    if matchedRule then
        db.stats.totalFiltered = (db.stats.totalFiltered or 0) + 1

        local action = db.action or "HIDE"
        local maskedText = nil
        if action == "MASK" then
            maskedText = self:MaskMessage(rawMessage, matchedWord, norm)
        end

        result = {
            shouldFilter = true,
            action = action,
            matchedWord = matchedWord,
            category = matchedRule.category,
            maskedText = maskedText,
        }
        self:LogIntercept(result, rawMessage, senderName, channelName)
    else
        result = { shouldFilter = false }
    end

    CacheDecision(rawMessage, matchedRule ~= nil, result)
    return result
end

-- Chat filters run once per chat frame subscribed to an event; the line ID
-- is unique per message, so repeat invocations for other chat frames reuse
-- the first decision without double-counting stats or the log
local lastLineID = nil
local lastLineResult = nil

-- Core Intercept Evaluation Engine
function E:EvaluateMessage(rawMessage, senderName, senderGUID, channelName, lineID)
    local db = CSPAM.db
    if not db or not db.enabled then
        return { shouldFilter = false }
    end

    if lineID and lineID ~= 0 and lineID == lastLineID then
        return lastLineResult
    end

    local result

    -- IFF Friendly check
    if self:IsSenderWhitelisted(senderName, senderGUID) then
        result = { shouldFilter = false }
    else
        db.stats.totalScanned = (db.stats.totalScanned or 0) + 1

        -- Check decision cache for repeat spam payloads
        local cached = decisionCache[rawMessage]
        if cached and (time() - cached.time < CACHE_TTL) then
            if cached.matched then
                db.stats.totalFiltered = (db.stats.totalFiltered or 0) + 1
                self:LogIntercept(cached.result, rawMessage, senderName, channelName)
                result = cached.result
            else
                result = { shouldFilter = false }
            end
        else
            result = EvaluateFresh(self, rawMessage, senderName, channelName)
        end
    end

    if lineID and lineID ~= 0 then
        lastLineID = lineID
        lastLineResult = result
    end
    return result
end
