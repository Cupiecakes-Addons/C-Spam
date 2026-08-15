local addonName, CSPAM = ...

CSPAM.Packs = {
    politics = {
        name = "Political Discourse",
        description = "Political candidates, parties, elections, and government discourse.",
        enabled = true,
        words = {
            -- Exact Key Words
            { text = "trump", mode = "EXACT" },
            { text = "biden", mode = "EXACT" },
            { text = "kamala", mode = "EXACT" },
            { text = "harris", mode = "EXACT" },
            { text = "maga", mode = "EXACT" },
            { text = "democrat", mode = "EXACT" },
            { text = "democrats", mode = "EXACT" },
            { text = "republican", mode = "EXACT" },
            { text = "republicans", mode = "EXACT" },
            { text = "gop", mode = "EXACT" },
            { text = "liberals", mode = "EXACT" },
            { text = "conservatives", mode = "EXACT" },
            { text = "libtard", mode = "EXACT" },
            { text = "potus", mode = "EXACT" },
            { text = "vance", mode = "EXACT" },
            { text = "walz", mode = "EXACT" },
            { text = "obama", mode = "EXACT" },
            { text = "clinton", mode = "EXACT" },
            { text = "pelosi", mode = "EXACT" },
            { text = "mcconnell", mode = "EXACT" },
            { text = "schumer", mode = "EXACT" },
            { text = "desantis", mode = "EXACT" },
            { text = "putin", mode = "EXACT" },
            { text = "zelensky", mode = "EXACT" },
            { text = "antifa", mode = "EXACT" },
            { text = "election", mode = "EXACT" },
            
            -- Phrases
            { text = "project 2025", mode = "PHRASE" },
            { text = "white house", mode = "PHRASE" },
            { text = "supreme court", mode = "PHRASE" },
            { text = "electoral college", mode = "PHRASE" },
            { text = "donald trump", mode = "PHRASE" },
            { text = "joe biden", mode = "PHRASE" },
            { text = "kamala harris", mode = "PHRASE" },
            { text = "jd vance", mode = "PHRASE" },
            { text = "tim walz", mode = "PHRASE" },
            { text = "vote blue", mode = "PHRASE" },
            { text = "vote red", mode = "PHRASE" },
        }
    },

    boosting = {
        name = "Carries & Gold Spam",
        description = "WTS carries, paid M+ boosts, power leveling, and gold sellers.",
        enabled = false,
        words = {
            { text = "wts boost", mode = "PHRASE" },
            { text = "wts carry", mode = "PHRASE" },
            { text = "wts m+", mode = "PHRASE" },
            { text = "mythic+ boost", mode = "PHRASE" },
            { text = "mythic plus boost", mode = "PHRASE" },
            { text = "m+ boost", mode = "PHRASE" },
            { text = "afk leveling", mode = "PHRASE" },
            { text = "level boost", mode = "PHRASE" },
            { text = "gladiator boost", mode = "PHRASE" },
            { text = "raid carry", mode = "PHRASE" },
            { text = "heroic carry", mode = "PHRASE" },
            { text = "mythic carry", mode = "PHRASE" },
            { text = "cheap gold", mode = "PHRASE" },
            { text = "gold only fast", mode = "PHRASE" },
            { text = "discord.gg/", mode = "CONTAINS" },
            { text = "d.i.s.c.o.r.d", mode = "CONTAINS" },
        }
    },

    toxicity = {
        name = "Toxicity & Hostile Slurs",
        description = "Hate speech, severe harassment, and unmoderated toxicity.",
        enabled = true,
        words = {
            { text = "kys", mode = "EXACT" },
            { text = "kill yourself", mode = "PHRASE" },
            { text = "kill urself", mode = "PHRASE" },
            { text = "retard", mode = "EXACT" },
            { text = "retarded", mode = "EXACT" },
            { text = "autistic", mode = "EXACT" },
            { text = "fag", mode = "EXACT" },
            { text = "faggot", mode = "EXACT" },
            { text = "nigger", mode = "EXACT" },
            { text = "nigga", mode = "EXACT" },
            { text = "cunt", mode = "EXACT" },
        }
    }
}
