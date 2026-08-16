local addonName, CSPAM = ...

CSPAM.Normalizer = {}
local N = CSPAM.Normalizer

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

-- Protect and extract Blizzard hyperlinks (|c...|H...|h...|h|r)
function N.ExtractLinks(text)
    local links = {}
    local count = 0

    local masked = text:gsub("(|c%x+|H.-|h.-|h|r)", function(link)
        count = count + 1
        links[count] = link
        return string.format(" ___CSPAMLINK%d___ ", count)
    end)

    -- Also mask loose raw item/spell/url links if any
    masked = masked:gsub("(|H.-|h.-|h)", function(link)
        count = count + 1
        links[count] = link
        return string.format(" ___CSPAMLINK%d___ ", count)
    end)

    return masked, links
end

-- Restore preserved hyperlinks
function N.RestoreLinks(text, links)
    if not links or #links == 0 then return text end
    return text:gsub("___CSPAMLINK(%d+)___", function(id)
        local idx = tonumber(id)
        return (idx and links[idx]) or ""
    end)
end

-- Apply Leetspeak & Homoglyph translation
function N.ApplyLeetTranslation(text)
    if not text then return "" end

    -- 1. Multibyte homoglyphs: single pass, skipped entirely for pure-ASCII text
    if text:find("[\208\209]") then
        text = text:gsub("[\208\209][\128-\191]", HOMOGLYPH_MAP)
    end
    if text:find(EURO_SIGN, 1, true) then
        text = text:gsub(EURO_SIGN, "e")
    end

    -- 2. Single-byte Leet character translation
    return (text:gsub(".", LEET_MAP))
end

-- Collapse runs of 3+ identical letters. A gsub with "(%a)%1%1+" cannot do
-- this: Lua pattern quantifiers do not apply to back-references, so the '+'
-- is matched as a literal plus sign and the pattern never fires. Returns two
-- variants — runs reduced to a single letter ("trumpppp" -> "trump") and to
-- a double ("boooost" -> "boost") — since the target word may legitimately
-- contain doubled letters.
function N.CollapseRepeats(text)
    -- Fast path: no letter appears 3+ times in a row (back-references
    -- without quantifiers are valid pattern items)
    if not text:find("(%a)%1%1") then
        return text, text
    end

    local one, two = {}, {}
    local n1, n2 = 0, 0
    local i, len = 1, #text
    while i <= len do
        local b = text:byte(i)
        local j = i + 1
        while j <= len and text:byte(j) == b do
            j = j + 1
        end
        local runLen = j - i
        local isLetter = (b >= 97 and b <= 122) or (b >= 65 and b <= 90)
        local keep1 = (isLetter and runLen >= 3) and 1 or runLen
        local keep2 = (isLetter and runLen >= 3) and 2 or runLen
        for _ = 1, keep1 do
            n1 = n1 + 1
            one[n1] = b
        end
        for _ = 1, keep2 do
            n2 = n2 + 1
            two[n2] = b
        end
        i = j
    end
    return string.char(unpack(one, 1, n1)), string.char(unpack(two, 1, n2))
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
    local buf, n = {}, 0
    local function flush()
        if n >= 3 then
            local joined = table.concat(buf, "", 1, n)
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
            buf[n] = word
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

    -- Links only need to survive in `extracted` (for masking/restore). Strip the
    -- placeholders from everything the matcher sees so they can never trip rules.
    local matchSource = extracted:gsub("___CSPAMLINK%d+___", " ")
    local lower = N.ToLower(matchSource)

    -- Base sanitized text: replace punctuation/control chars with spaces
    local cleaned = lower:gsub("[%p%c]", " "):gsub("%s+", " "):trim()

    -- Token map for O(1) exact word lookup
    local tokens = {}
    AddTokens(cleaned, tokens)

    -- Leet / Homoglyph normalized variant
    local leetClean = nil
    local leetTokens = nil

    if options.checkLeet ~= false then
        leetClean = N.ApplyLeetTranslation(lower):gsub("[%p%c]", " "):gsub("%s+", " "):trim()
        leetTokens = {}
        AddTokens(leetClean, leetTokens)
    end

    if options.collapseRepeats ~= false then
        local one, two = N.CollapseRepeats(cleaned)
        AddTokens(one, tokens)
        AddTokens(two, tokens)
        AddJoinedRuns(cleaned, tokens)
        if leetClean then
            local leetOne, leetTwo = N.CollapseRepeats(leetClean)
            AddTokens(leetOne, leetTokens)
            AddTokens(leetTwo, leetTokens)
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
