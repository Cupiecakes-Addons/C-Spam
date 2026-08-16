# <img src="Media/logo.png" width="36" height="36" align="center" /> C-SPAM: Counter-Spam Phalanx System

[![WoW Retail](https://img.shields.io/badge/WoW%20Retail-12.1.0%20%2F%2011.x-00e5ff.svg)](https://worldofwarcraft.com)
[![Interface](https://img.shields.io/badge/Interface-120100-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-MIT-orange.svg)]()
[![Design](https://img.shields.io/badge/Style-Tactical%201px-ff3b30.svg)]()

**C-SPAM** is an automated in-game chat threat interceptor inspired by military **C-RAM** (Counter-Rocket, Artillery, and Mortar) air defense systems. It tracks, decodes, and neutralizes political discourse, gold/carry advertising, and toxic keywords with zero FPS impact.

---

## 🎯 Why Legacy Chat Filters Fail (And C-SPAM Succeeds)

| Vulnerability in Common Addons | C-SPAM Phalanx Defense |
|---|---|
| **Misses words due to punctuation** (`"trump!"`, `"(biden)"`, `"kamala,"`) | **Boundary Isolation Engine**: Automatically strips punctuation before matching. |
| **Bypassed by Leetspeak / Homoglyphs** (`@ss`, `tr0mp`, `b!den`, Russian Cyrillic lookalikes) | **Camouflage & Leet Decoder**: Normalizes `@` $\rightarrow$ `a`, `0` $\rightarrow$ `o`, `$` $\rightarrow$ `s`, `1` $\rightarrow$ `i`, `v` $\rightarrow$ `u`, and Cyrillic homoglyphs (`а`, `е`, `о`, `р`, `с`) to Latin base characters. |
| **High Trade/LFG Channel Lag** | **$O(1)$ Hash Set Engine**: Single words evaluate in microsecond time ($O(N)$ where $N$ is only the word count of the incoming sentence). High-volume duplicate spam lines are resolved instantly from a fast LRU hash cache. |
| **Item/Spell Links Broken or False-Triggered** | **Hyperlink Shield**: Shields all `|c...|Hitem:...|h[Name]|h|r` links so item names, hex color codes, and item IDs never trigger false positives or break in chat. |
| **False-Positive Substrings** | Strict separation between **Exact Standalone Words** (blocking `"trump"` will **never** block `"strumpet"` or `"trumpet"`), **Contains**, and **Phrases**. |

---

## 🛠️ Features

- ⚙️ **ElvUI-Themed Tactical Console**: Sleek 1-pixel borders, matte charcoal panels, cyan/red accenting, and informative inline tooltips with concrete examples.
- 🛸 **Custom Minimap Turret Button**: Draggable circular turret button with live hover telemetry (*Airspace Scanned*, *Threats Intercepted*, *% Intercept Rate*) and 1-click console access.
- 📦 **1-Click Pre-Calibrated Defense Packs**:
  - 🏛️ **Political Discourse**: Candidates, elections, partisan arguments, and campaign phrases.
  - 💰 **Carries, Boosting & Gold Spam**: M+ carry ads, raid loot sales, AFK leveling, and external Discord/gold seller links.
  - 🚫 **Toxicity & Hostile Slurs**: Severe harassment, toxicity, and unmoderated hate speech.
- 🛡️ **IFF Safe Allies (Bypasses)**: Automatic bypasses for Battle.net/character Friends, Guildmates, and Party/Raid group members.
- 📡 **Monitored Airspace**: Per-channel radar toggles for Public Channels (Trade, Services, General, LFG), Communities, Local Say/Yell, and Direct Whispers.
- 🎯 **Dual Engagement Protocols**:
  - **Kinetic Intercept**: Silently drops matching messages completely (zero chat clutter or sound).
  - **Electronic Jamming**: Censoring matched keywords with `***` while keeping all item/spell links safe.
- 📋 **Import / Export**: Easily export and share your threat signatures (`MODE:KEYWORD`) with guildmates.

---

## 🎮 Tactical Slash Commands

| Command | Action |
|---|---|
| `/cs` or `/cspam` | Open the **C-SPAM Tactical Defense Console** |
| `/cs toggle` | Quick toggle **ARM / DISARM** intercept status |
| `/cs add <word or phrase>` | Register a signature (multi-word input becomes a PHRASE) |
| `/cs safe <name>` | Toggle a character on the IFF safe-ally whitelist |
| `/cs stats` | Output telemetry report to chat |

---

## 📥 Installation

**From a packaged release (recommended):**
1. Grab the latest zip from the [GitHub Releases](https://github.com/Cupiecakes-Addons/C-Spam/releases) page (WowUp can also install from the repo URL once a release exists).
2. Extract it straight into `World of Warcraft\_retail_\Interface\AddOns\` — you end up with `Interface\AddOns\C-Spam\C-Spam.toc`. LibStub / LibDataBroker / LibDBIcon are bundled for ElvUI & minimap-bar integration.

**From source (git checkout):**
1. Clone or copy this repository into `Interface\AddOns\` and make sure the folder is named exactly `C-Spam` — WoW only loads `<Folder>\<Folder>.toc`. The checkout is a complete addon (libraries are vendored in `Libs/`).
2. To build the release-style zip locally, run `scripts/package.sh` and drop `dist/C-Spam.zip` contents into your AddOns folder.

Then launch WoW (or type `/reload`) and type `/cs` or click the Minimap Turret icon to configure.

---

## 📜 Blizzard Addon Policy Compliance

- **100% Free & Open Source**: No paywalls, paid tiers, or monetization.
- **Official APIs**: Uses standard `ChatFrame_AddMessageEventFilter` APIs.
- **Client-Side Only**: Does not execute external out-of-game code or violate the Terms of Service.
