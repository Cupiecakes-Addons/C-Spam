local addonName, CSPAM = ...

CSPAM.Engine = {}
local E = CSPAM.Engine

-- Compiled Index Tables
local exactWords = {}
local containsList = {}
local phraseList = {}
local regexList = {}

-- LRU Cache for repeat message handling
local decisionCache = {}
local cacheOrder = {}
local MAX_CACHE_SIZE = 128

local function GetStringHash(str)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash * 33) + str:byte(i)) % 4294967296
    end
    return hash
end

function E:RebuildIndex()
    table.wipe(exactWords)
    table.wipe(containsList)
    table.wipe(phraseList)
    table.wipe(regexList)
    table.wipe(decisionCache)
    table.wipe(cacheOrder)

    local function AddRule(text, mode, category, packName)
        if not text or text == "" then return end
        local cleanText = text:lower():trim()
        local modeUpper = (mode or "EXACT"):upper()

        if modeUpper == "EXACT" then
            exactWords[cleanText] = { text = text, mode = modeUpper, category = category, pack = packName }
        elseif modeUpper == "CONTAINS" then
            local escaped = cleanText:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
            table.insert(containsList, {
                raw = text,
                pattern = escaped,
                category = category,
                pack = packName,
            })
        elseif modeUpper == "PHRASE" then
            local words = {}
            for w in cleanText:gmatch("%S+") do
                table.insert(words, (w:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")))
            end
            if #words > 0 then
                local pattern = table.concat(words, "%s+")
                table.insert(phraseList, {
                    raw = text,
                    pattern = pattern,
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

    -- Character name whitelist
    local senderClean = senderName:lower():gsub("%-.+$", "")
    if db.whitelist.characters and db.whitelist.characters[senderClean] then
        return true
    end

    -- Friends Whitelist
    if db.whitelist.friends and senderGUID and senderGUID ~= "" then
        if C_FriendList and C_FriendList.IsFriend and C_FriendList.IsFriend(senderGUID) then
            return true
        end
        if C_BattleNet and C_BattleNet.GetAccountInfoByGUID and C_BattleNet.GetAccountInfoByGUID(senderGUID) then
            return true
        end
    end

    -- Guild Whitelist
    if db.whitelist.guild and UnitIsInMyGuild and UnitIsInMyGuild(senderName) then
        return true
    end

    -- Party / Raid Whitelist
    if db.whitelist.party then
        if (UnitInParty and UnitInParty(senderName)) or (UnitInRaid and UnitInRaid(senderName)) then
            return true
        end
    end

    return false
end

-- Electronic Jamming (Mask target words with asterisks)
function E:MaskMessage(rawMessage, matchedText, norm)
    if not matchedText or matchedText == "" then return rawMessage end
    
    local extracted, links = norm.extracted, norm.links
    local escapedMatch = matchedText:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    
    local masked, _ = extracted:gsub("(?i)" .. escapedMatch, function(found)
        return string.rep("*", #found)
    end)

    if masked == extracted then
        masked = extracted:gsub(escapedMatch, string.rep("*", #matchedText))
    end

    return CSPAM.Normalizer.RestoreLinks(masked, links)
end

-- Core Intercept Evaluation Engine
function E:EvaluateMessage(rawMessage, senderName, senderGUID, channelName)
    local db = CSPAM.db
    if not db or not db.enabled then
        return { shouldFilter = false }
    end

    -- IFF Friendly check
    if self:IsSenderWhitelisted(senderName, senderGUID) then
        return { shouldFilter = false }
    end

    db.stats.totalScanned = (db.stats.totalScanned or 0) + 1

    -- Check LRU Cache for repeat spam payloads
    local hash = GetStringHash(rawMessage)
    local cached = decisionCache[hash]
    if cached and (time() - cached.time < 20) then
        if cached.matched then
            db.stats.totalFiltered = (db.stats.totalFiltered or 0) + 1
            return cached.result
        else
            return { shouldFilter = false }
        end
    end

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

    -- 3. Contains / Substring Scanning
    if not matchedRule and #containsList > 0 then
        for _, rule in ipairs(containsList) do
            if norm.lower:find(rule.pattern) or (norm.leetClean and norm.leetClean:find(rule.pattern)) then
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

    local result = nil
    if matchedRule then
        db.stats.totalFiltered = (db.stats.totalFiltered or 0) + 1
        
        -- Record in Intercept Log
        if db.options.logFiltered then
            table.insert(db.filteredLog, 1, {
                timestamp = time(),
                sender = senderName or "Unknown",
                channel = channelName or "Sector",
                matched = matchedWord or (matchedRule and matchedRule.text) or "Signature",
                category = matchedRule.category or "Custom",
                message = rawMessage,
            })
            while #db.filteredLog > (db.options.maxLogEntries or 100) do
                table.remove(db.filteredLog)
            end
        end

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
    else
        result = { shouldFilter = false }
    end

    -- Store in LRU cache
    if #cacheOrder >= MAX_CACHE_SIZE then
        local oldest = table.remove(cacheOrder, 1)
        decisionCache[oldest] = nil
    end
    table.insert(cacheOrder, hash)
    decisionCache[hash] = {
        time = time(),
        matched = (matchedRule ~= nil),
        result = result,
    }

    return result
end
