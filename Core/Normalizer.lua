local addonName, CSPAM = ...

CSPAM.Normalizer = {}
local N = CSPAM.Normalizer

-- Leetspeak & Symbol translation table (1-byte ASCII replacements)
local LEET_MAP = {
    ["@"] = "a",
    ["4"] = "a",
    ["8"] = "b",
    ["("] = "c",
    ["3"] = "e",
    ["€"] = "e",
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

-- Common Cyrillic / Multibyte Homoglyphs mapped to ASCII Latin
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

-- Apply Leetspeak & Homoglyph translation (Safe O(N) table-driven gsub)
function N.ApplyLeetTranslation(text)
    if not text then return "" end

    -- 1. Replace Cyrillic / Multibyte homoglyphs
    for glyph, replacement in pairs(HOMOGLYPH_MAP) do
        text = text:gsub(glyph, replacement)
    end

    -- 2. Fast single-pass Leet character translation (bypasses Lua pattern capture index bugs)
    text = text:gsub(".", LEET_MAP)

    return text
end

-- Collapse consecutive identical characters (e.g. "traaaash" -> "trash", "trumpppp" -> "trump")
function N.CollapseRepeats(text)
    return text:gsub("(%a)%1%1+", "%1")
end

-- Full normalization pipeline
function N.NormalizeMessage(rawMessage, options)
    options = options or (CSPAM.db and CSPAM.db.options) or {}
    
    local extracted, links = N.ExtractLinks(rawMessage)
    local lower = N.ToLower(extracted)

    -- Base sanitized text: replace punctuation with space, but keep characters
    local cleaned = lower:gsub("[%p%c]", " ")
    cleaned = cleaned:gsub("%s+", " "):trim()

    -- Generate token map for O(1) exact word lookup
    local tokens = {}
    for word in cleaned:gmatch("%S+") do
        if not word:match("^___cspamlink%d+___$") then
            tokens[word] = true
        end
    end

    -- Leet / Homoglyph normalized variant
    local leetClean = nil
    local leetTokens = nil
    local collapsedClean = nil

    if options.checkLeet ~= false then
        local leetStr = N.ApplyLeetTranslation(lower)
        leetClean = leetStr:gsub("[%p%c]", " "):gsub("%s+", " "):trim()
        leetTokens = {}
        for word in leetClean:gmatch("%S+") do
            if not word:match("^___cspamlink%d+___$") then
                leetTokens[word] = true
            end
        end
    end

    if options.collapseRepeats ~= false then
        collapsedClean = N.CollapseRepeats(cleaned)
        if leetClean then
            local collapsedLeet = N.CollapseRepeats(leetClean)
            for word in collapsedLeet:gmatch("%S+") do
                if not word:match("^___cspamlink%d+___$") then
                    if leetTokens then leetTokens[word] = true end
                    tokens[word] = true
                end
            end
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
        collapsedClean = collapsedClean,
    }
end
