local addonName, CSPAM = ...

CSPAM.Normalizer = {}
local N = CSPAM.Normalizer

local sbyte = string.byte
local schar = string.char
local sfind = string.find
local sgsub = string.gsub
local smatch = string.match
local tconcat = table.concat

-- Leetspeak & Symbol translation table (single-byte replacements applied per byte)
local LEET_MAP = {
    ["@"] = "a",
    ["4"] = "a",
    ["8"] = "b",
    ["("] = "c",
    ["3"] = "e",
    ["6"] = "g",
    ["9"] = "g",
    ["!"] = "i",
    ["1"] = "i",
    ["|"] = "l",
    ["0"] = "o",
    ["$"] = "s",
    ["5"] = "s",
    ["7"] = "t",
    ["+"] = "t",
    ["v"] = "u",
    ["2"] = "z",
}
N.LEET_MAP = LEET_MAP -- shared with Engine:MaskMessage's fuzzy character classes

-- Any byte that ApplyLeetTranslation can actually rewrite: all LEET_MAP keys,
-- the leading bytes of HOMOGLYPH_MAP (\208/\209), and EURO_SIGN (\226).
-- Messages containing none of these produce a leetClean identical to cleaned,
-- so NormalizeMessage can skip the entire second pass.
local HAS_LEET_CHARS = "[@48%(369!1|0%$57%+v2\208\209\226]"

-- Common Cyrillic / Multibyte Homoglyphs mapped to ASCII Latin.
-- Every key is a 2-byte UTF-8 sequence starting with \208 or \209, which lets
-- ApplyLeetTranslation replace all of them in one gsub pass.
local HOMOGLYPH_MAP = {
    ["\208\176"] = "a", -- Cyrillic Small Letter A
    ["\208\144"] = "a", -- Cyrillic Capital Letter A
    ["\208\181"] = "e", -- Cyrillic Small Letter Ie
    ["\208\149"] = "e", -- Cyrillic Capital Letter Ie
    ["\208\190"] = "o", -- Cyrillic Small Letter O
    ["\208\158"] = "o", -- Cyrillic Capital Letter O
    ["\209\128"] = "p", -- Cyrillic Small Letter Er
    ["\208\160"] = "p", -- Cyrillic Capital Letter Er
    ["\209\129"] = "c", -- Cyrillic Small Letter Es
    ["\208\161"] = "c", -- Cyrillic Capital Letter Es
    ["\209\131"] = "y", -- Cyrillic Small Letter U
    ["\208\163"] = "y", -- Cyrillic Capital Letter U
    ["\209\133"] = "x", -- Cyrillic Small Letter Ha
    ["\208\165"] = "x", -- Cyrillic Capital Letter Ha
    ["\209\150"] = "i", -- Cyrillic Small Letter Byelorussian-Ukrainian I
    ["\208\134"] = "i", -- Cyrillic Capital Letter Byelorussian-Ukrainian I
    ["\208\162"] = "t", -- Cyrillic Capital Letter Te
}

-- Multibyte sequences that need a length-specific replacement of their own
-- (a per-byte gsub can never match them)
local EURO_SIGN = "\226\130\172" -- €

-- Safely lowercase UTF-8 strings
function N.ToLower(str)
    if not str then return "" end
    if string.utf8lower then
        return string.utf8lower(str)
    end
    return string.lower(str)
end

-- Escape sequences swapped for placeholders before matching, tried in order.
-- 12.x item links color by quality name (|cnIQ4:) rather than hex, and other
-- addons' filters run first and splice icons into the text (ElvUI's chat
-- emoji arrive as |TInterface\AddOns\ElvUI\...|t), so without the last two
-- entries icon file paths would be matched as if a player had typed them.
local PROTECTED_PATTERNS = {
    "(|c%x+|H.-|h.-|h|r)",      -- hex-colored hyperlink
    "(|cn[^:|]*:|H.-|h.-|h|r)", -- named-color hyperlink
    "(|H.-|h.-|h)",             -- uncolored hyperlink
    "(|T.-|t)",                 -- texture icon
    "(|A.-|a)",                 -- atlas icon
}

-- Protect and extract Blizzard hyperlinks and inline icons
function N.ExtractLinks(text)
    local links = {}
    local count = 0
    -- Plain chat carries no escapes at all; skip the pattern passes
    if not text:find("|", 1, true) then
        return text, links
    end

    local function protect(link)
        count = count + 1
        links[count] = link
        return string.format(" ___CSPAMLINK%d___ ", count)
    end

    local masked = text
    for _, pattern in ipairs(PROTECTED_PATTERNS) do
        masked = masked:gsub(pattern, protect)
    end

    return masked, links
end

-- Restore preserved hyperlinks, along with the padding spaces ExtractLinks
-- put around each placeholder, so a masked message keeps its spacing
function N.RestoreLinks(text, links)
    if not links or #links == 0 then return text end
    return (text:gsub(" ?___CSPAMLINK(%d+)___ ?", function(id)
        local idx = tonumber(id)
        return (idx and links[idx]) or ""
    end))
end

-- Apply Leetspeak & Homoglyph translation to a single chunk.
local function TranslateChunk(chunk)
    -- Skip chunks with no Latin letter, Cyrillic byte, or Euro sign so numeric
    -- tokens like "(14)" (M+14 keystone -> "cia"), "(15)" ("cis"), "(8+)"
    -- ("cbt"), "+17" ("tit"), and "455%" ("ass") never decode into fake words.
    -- Also skip WoW currency/quantity literals like "35g" ("esg") or
    -- "600k"/"900k" ("gook").
    if #chunk >= 2 and not chunk:find("[%a\208\209]") and not chunk:find(EURO_SIGN, 1, true) then
        return chunk
    end
    if chunk:find("^%p*%d+[gkms]%p*$") then
        return chunk
    end

    -- 1. Multibyte homoglyphs: single pass, skipped entirely for pure-ASCII text
    if chunk:find("[\208\209]") then
        chunk = chunk:gsub("[\208\209][\128-\191]", HOMOGLYPH_MAP)
    end
    if chunk:find(EURO_SIGN, 1, true) then
        chunk = chunk:gsub(EURO_SIGN, "e")
    end

    -- 2. Single-byte Leet character translation
    return (chunk:gsub(".", LEET_MAP))
end

-- Apply Leetspeak & Homoglyph translation
function N.ApplyLeetTranslation(text)
    if not text or text == "" then return "" end
    if not sfind(text, HAS_LEET_CHARS) then return text end
    return (sgsub(text, "[^%s/%-]+", TranslateChunk))
end

-- Reusable scratch buffers for CollapseRepeats / AddJoinedRuns so the chat
-- hot path allocates no temporary array tables per message.
local collapseOne, collapseTwo = {}, {}
local joinBuf = {}

-- Collapse runs of 3+ identical letters. A gsub with "(%a)%1%1+" cannot do
-- this: Lua pattern quantifiers do not apply to back-references, so the '+'
-- is matched as a literal plus sign and the pattern never fires. Returns two
-- variants — runs reduced to a single letter ("trumpppp" -> "trump") and to
-- a double ("boooost" -> "boost") — since the target word may legitimately
-- contain doubled letters.
function N.CollapseRepeats(text)
    -- Fast path: no letter appears 3+ times in a row (back-references
    -- without quantifiers are valid pattern items)
    if not sfind(text, "(%a)%1%1") then
        return text, text
    end

    local n1, n2 = 0, 0
    local i, len = 1, #text
    while i <= len do
        local b = sbyte(text, i)
        local j = i + 1
        while j <= len and sbyte(text, j) == b do
            j = j + 1
        end
        local runLen = j - i
        local isLetter = (b >= 97 and b <= 122) or (b >= 65 and b <= 90)
        local keep1 = (isLetter and runLen >= 3) and 1 or runLen
        local keep2 = (isLetter and runLen >= 3) and 2 or runLen
        for _ = 1, keep1 do
            n1 = n1 + 1
            collapseOne[n1] = b
        end
        for _ = 1, keep2 do
            n2 = n2 + 1
            collapseTwo[n2] = b
        end
        i = j
    end
    return schar(unpack(collapseOne, 1, n1)), schar(unpack(collapseTwo, 1, n2))
end

-- Add every whitespace-separated word of `text` to the token set
local function AddTokens(text, set)
    for word in text:gmatch("%S+") do
        set[word] = true
    end
end

-- Join runs of 3+ consecutive single-character tokens into whole words so
-- spaced-out evasion ("t r u m p", "t.r.u.m.p" after cleaning) is tokenized too
local function AddJoinedRuns(text, set)
    -- Fast path: skip the gmatch scan when there aren't 3+ single-char tokens
    if not sfind(text, "^%S %S %S") and not sfind(text, " %S %S %S") then
        return
    end
    local n = 0
    local function flush()
        if n >= 3 then
            local joined = tconcat(joinBuf, "", 1, n)
            set[joined] = true
            local one, two = N.CollapseRepeats(joined)
            set[one] = true
            set[two] = true
        end
        n = 0
    end
    for word in text:gmatch("%S+") do
        if #word == 1 then
            n = n + 1
            joinBuf[n] = word
        else
            flush()
        end
    end
    flush()
end

-- Full normalization pipeline
function N.NormalizeMessage(rawMessage, options)
    options = options or (CSPAM.db and CSPAM.db.options) or {}

    local extracted, links = N.ExtractLinks(rawMessage)

    -- Spammers hide their ad text inside link display names (renamed battle
    -- pets, crafted links), so each placeholder is swapped for the link's
    -- VISIBLE text in the matching corpus. Link data (ids, colors, payload)
    -- stays excluded, so item ids and hex codes can never trip rules, and
    -- the placeholder sentinel itself never reaches the matcher.
    local matchSource
    if #links > 0 then
        matchSource = sgsub(extracted, "___CSPAMLINK(%d+)___", function(id)
            local link = links[tonumber(id)]
            local display = link and smatch(link, "|h(.-)|h")
            if not display then return " " end
            local text = sgsub(display, "[%[%]]", " ")
            return " " .. text .. " "
        end)
    else
        matchSource = extracted
    end
    -- Escapes left in the corpus: icons inside link display text, and loose
    -- color codes (another addon's filter highlighting a keyword) that would
    -- otherwise glue "cffff0000" onto the front of the word they color
    if sfind(matchSource, "|", 1, true) then
        matchSource = matchSource:gsub("|T.-|t", " "):gsub("|A.-|a", " ")
            :gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:|]*:", ""):gsub("|r", "")
    end
    local lower = N.ToLower(matchSource)

    -- Base sanitized text: replace punctuation/control chars with spaces
    local cleaned = lower:gsub("[%p%c]", " "):gsub("%s+", " "):trim()

    -- Token map for O(1) exact word lookup
    local tokens = {}
    AddTokens(cleaned, tokens)

    -- Leet / Homoglyph normalized variant. Skipped entirely when `lower`
    -- contains no translatable bytes (so leetClean would equal cleaned).
    local leetClean = nil
    local leetTokens = nil

    if options.checkLeet ~= false and sfind(lower, HAS_LEET_CHARS) then
        local translated = N.ApplyLeetTranslation(lower)
        if translated ~= lower then
            leetClean = translated:gsub("[%p%c]", " "):gsub("%s+", " "):trim()
            if leetClean ~= cleaned then
                leetTokens = {}
                AddTokens(leetClean, leetTokens)
            else
                leetClean = nil
            end
        end
    end

    if options.collapseRepeats ~= false then
        local one, two = N.CollapseRepeats(cleaned)
        if one ~= cleaned then AddTokens(one, tokens) end
        if two ~= cleaned and two ~= one then AddTokens(two, tokens) end
        AddJoinedRuns(cleaned, tokens)
        if leetClean then
            local leetOne, leetTwo = N.CollapseRepeats(leetClean)
            if leetOne ~= leetClean then AddTokens(leetOne, leetTokens) end
            if leetTwo ~= leetClean and leetTwo ~= leetOne then AddTokens(leetTwo, leetTokens) end
            AddJoinedRuns(leetClean, leetTokens)
        end
    end

    return {
        raw = rawMessage,
        extracted = extracted,
        links = links,
        lower = lower,
        cleaned = cleaned,
        tokens = tokens,
        leetClean = leetClean,
        leetTokens = leetTokens,
    }
end
