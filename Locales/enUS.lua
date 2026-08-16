local addonName, CSPAM = ...

CSPAM.L = CSPAM.L or {}
local L = CSPAM.L

-- System Identity
L["ADDON_TITLE"] = "C-SPAM"
L["ADDON_SUBTITLE"] = "Counter-Spam Defense & Intercept System"
L["ADDON_LOADED"] = "|cffff3b30C-SPAM|r v%s |cff00ff00[ONLINE]|r. Phalanx chat defense active. Type |cff00e5ff/cspam|r or |cff00e5ff/cs|r for command console."

-- Slash Commands
L["SLASH_HELP_HEADER"] = "|cffff3b30C-SPAM Defense Console Commands:|r"
L["SLASH_HELP_OPEN"] = "  |cff00e5ff/cs|r or |cff00e5ff/cspam|r - Open Tactical Defense Console"
L["SLASH_HELP_TOGGLE"] = "  |cff00e5ff/cs toggle|r - ARM / DISARM intercept system"
L["SLASH_HELP_ADD"] = "  |cff00e5ff/cs add <keyword>|r - Quick add threat signature to blocklist"
L["SLASH_HELP_STATS"] = "  |cff00e5ff/cs stats|r - Display telemetry & intercept report"
L["SLASH_ADDED_WORD"] = "|cffff3b30C-SPAM:|r Threat signature |cffffd100%s|r added to Active Intercept Matrix."
L["SLASH_WORD_EXISTS"] = "|cffff3b30C-SPAM:|r Signature |cffffd100%s|r is already registered in the matrix."
L["SLASH_TOGGLE_ON"] = "|cffff3b30C-SPAM:|r Interceptor status: |cff00ff00[ARMED & ACTIVE]|r"
L["SLASH_TOGGLE_OFF"] = "|cffff3b30C-SPAM:|r Interceptor status: |cffff2020[DISARMED / STANDBY]|r"
L["SLASH_HELP_SAFE"] = "  |cff00e5ff/cs safe <name>|r - Toggle a character on the IFF safe-ally whitelist"
L["SLASH_SAFE_ADDED"] = "|cffff3b30C-SPAM:|r |cffffd100%s|r added to IFF safe allies."
L["SLASH_SAFE_REMOVED"] = "|cffff3b30C-SPAM:|r |cffffd100%s|r removed from IFF safe allies."
L["SLASH_SAFE_LIST"] = "|cffff3b30C-SPAM:|r IFF safe allies: |cffffd100%s|r"
L["SLASH_SAFE_EMPTY"] = "|cffff3b30C-SPAM:|r No characters registered as IFF safe allies."

-- Console Tabs
L["TAB_CUSTOM"] = "Threat Matrix"
L["TAB_PACKS"] = "Defense Packs"
L["TAB_LOG"] = "Intercept Log"
L["TAB_SETTINGS"] = "Radar & Config"
L["TAB_IMPORT_EXPORT"] = "Import / Export"

-- Headers & Columns
L["COL_KEYWORD"] = "Target Signature / Pattern"
L["COL_MODE"] = "Tracking Mode"
L["COL_CATEGORY"] = "Classification"
L["COL_STATUS"] = "Active"
L["COL_DELETE"] = "Del"

-- Tracking Modes
L["MODE_EXACT"] = "Exact Word"
L["MODE_CONTAINS"] = "Contains"
L["MODE_PHRASE"] = "Phrase"
L["MODE_REGEX"] = "Regex / Pattern"

L["MODE_EXACT_DESC"] = "Matches exact isolated words only. E.g. 'trump' intercepts 'vote for trump' but NOT 'strumpet'."
L["MODE_CONTAINS_DESC"] = "Intercepts signature anywhere in message string. E.g. 'sell' matches 'reseller'."
L["MODE_PHRASE_DESC"] = "Multi-word sequence matching with normalized spacing. E.g. 'project 2025' or 'kamala harris'."
L["MODE_REGEX_DESC"] = "Advanced Lua pattern matching for complex signatures."

-- Intercept Actions
L["ACTION_HIDE"] = "Kinetic Intercept (Silently drop incoming message)"
L["ACTION_MASK"] = "Electronic Jamming (Censor target keywords with ***)"
L["ACTION_LOG_ONLY"] = "Passive Surveillance (Log only, pass through to chat)"

-- Defense Packs
L["PACK_POLITICS"] = "Political Discourse"
L["PACK_POLITICS_DESC"] = "Intercepts political candidates, election arguments, government discourse, and party rhetoric."
L["PACK_BOOSTING"] = "Carries & Gold Spam"
L["PACK_BOOSTING_DESC"] = "Neutralizes advertising for paid M+ carries, raid sales, leveling, and gold sellers."
L["PACK_TOXICITY"] = "Toxicity & Hostile Slurs"
L["PACK_TOXICITY_DESC"] = "Intercepts severe harassment, abusive hostility, and unmoderated hate slurs."

-- Radar / Config Settings
L["SETTING_ENABLE"] = "Arm C-SPAM Interceptor"
L["SETTING_ENABLE_DESC"] = "Master armed switch for all automated chat intercept operations."
L["SETTING_ACTION"] = "Engagement Doctrine"
L["SETTING_LEET"] = "Decode Evasion & Homoglyphs"
L["SETTING_LEET_DESC"] = "Translates camouflage substitutions like '@' -> 'a', '0' -> 'o', '1' -> 'i', '$' -> 's', and Cyrillic lookalikes before scanning."
L["SETTING_PUNCTUATION"] = "De-punctuate & Space Compression"
L["SETTING_PUNCTUATION_DESC"] = "Neutralizes spaced-out evasion techniques like 't.r.u.m.p' or 't r u m p'."
L["SETTING_REPEAT_CHARS"] = "Collapse Repeated Letters"
L["SETTING_REPEAT_CHARS_DESC"] = "Collapses stutter evasion tactics like 'traaaash' -> 'trash'."

-- Whitelist / IFF (Identification Friend or Foe)
L["WHITELIST_HEADER"] = "IFF Whitelist (Safe Allies - Bypass Interceptor)"
L["WHITELIST_FRIENDS"] = "Safe: Friends List"
L["WHITELIST_GUILD"] = "Safe: Guild Roster"
L["WHITELIST_GROUP"] = "Safe: Party & Raid Allies"

-- Channel Radar
L["CHANNELS_HEADER"] = "Monitored Airspace (Chat Channels)"
L["CHAN_PUBLIC"] = "Public Sectors (Trade, Services, General, LFG)"
L["CHAN_COMMUNITIES"] = "Communities & Club Channels"
L["CHAN_SAY"] = "Local Say & Yell"
L["CHAN_WHISPER"] = "Direct Whispers"
L["CHAN_EMOTE"] = "Emotes"

-- Intercept Log
L["LOG_EMPTY"] = "Airspace clear. No incoming threats intercepted yet."
L["LOG_COL_TIME"] = "Intercept Time"
L["LOG_COL_SENDER"] = "Origin"
L["LOG_COL_CHAN"] = "Sector"
L["LOG_COL_MATCH"] = "Threat Tag"
L["LOG_COL_MSG"] = "Intercepted Payload"
L["BTN_CLEAR_LOG"] = "Purge Log"

-- Import / Export
L["IE_TITLE"] = "Threat Matrix Telemetry Data (Import / Export)"
L["IE_DESC"] = "Export active threat signatures to share with guildmates, or paste a signature list to import."
L["BTN_IMPORT"] = "Import Matrix"
L["BTN_EXPORT"] = "Export Matrix"
L["IE_SUCCESS"] = "|cffff3b30C-SPAM:|r Successfully loaded %d threat signatures into Active Matrix."
L["IE_SUCCESS_DETAIL"] = "|cffff3b30C-SPAM:|r Loaded %d new threat signatures into the Active Matrix (%d duplicates skipped)."
L["IE_ERROR"] = "|cffff2020C-SPAM Error:|r Invalid signature payload format."
