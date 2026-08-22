# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **Relative age on every intercepted message.** The Intercept Log now shows how long ago each entry landed — `now`, `12s`, `4m`, `3h`, `2d` — in a column on the right of the row, ticking once per second while the tab is open. Anything under a minute old is green so a live intercept stands out; older entries are grey. The absolute `HH:MM:SS` clock still leads the line and is unchanged. Because the log persists between sessions, a row stamped `22:06` could just as easily be from last night as from a minute ago — the age column is what tells the two apart.
- **`LAST INTERCEPT` readout in the log header**, beside Purge Telemetry, so the time since the most recent hit is readable without scanning the rows.
- **Running intercept tallies in the console header.** The title bar now carries `INTERCEPTED <n> ALL-TIME · <n> SESSION`, visible from every tab and climbing live as messages are caught. The all-time figure is the existing persisted `totalFiltered`, so it reflects real history rather than starting from zero; the session figure is in-memory and resets on `/reload`. `/cs stats` reports the session count too. Both tallies are incremented at a single seam covering the fresh-evaluation and cache-hit paths, and keep counting when the intercept log is disabled.
- **New defense pack: Explicit & NSFW Chat** — 258 signatures spanning sex acts, anatomical slang, bodily fluids, strong profanity, fetishes and paraphilias, adult-industry terms, and chat slang. Match modes are chosen per term rather than uniformly: distinctive stems are `CONTAINS`, so `fuck` alone covers `fucker`/`fucking`/`motherfucker`/`clusterfuck` and `masturb` covers the whole `-ate/-ating/-ation/-ator` family, while short anatomical words are `EXACT` token matches because a substring rule there would intercept `class`, `assist`, `titan`, `title`, `document`, `cucumber`, `analysis`, `scatter`, `coarse`, `cockatrice`, `dragoon` and `lagoon`. Camouflage needs no signatures of its own — the normalizer already resolves `g00ning` and `goooooning`. Regression tests cover both directions.

### Fixed
- **Tooltips now repaint while the cursor is still on the button.** Clicking the mode selector in Threat Matrix cycled the mode but left the visible tooltip describing the *previous* mode until you moved the mouse away and back. The tooltip text was only assembled inside `OnEnter`, and because `SetElvTooltip` registered it with `HookScript` (which appends rather than replaces), every click also stacked another `OnEnter`/`OnLeave` handler on the button for the rest of the session. Tooltip content now lives on the frame, is hooked exactly once, and repaints in place when the frame already owns the tooltip.

### Changed
- The log header line (timestamp, channel, sender, target) is now bounded by the age column, so a long sender or channel name truncates instead of running the full width of the row.

### Notes
- Eighteen requested terms were deliberately left out of the NSFW pack because each fires on ordinary WoW chat: `of`, `69`, `sub`, `dom`, `bd`, `bde`, `dtr`, `meat` (cooking reagent), `junk` (vendor trash), `pole` (fishing pole), `hog` (Mechano-Hog), `taint` (corruption lore), `domination` (Shadowlands shards), `crushing` (a combat mechanic), `trampling`, `nut`, `nuts` and `balls`.
- `bastard` will also intercept the classic item name "Bastard Sword".
- The bare `goon` and `goons` signatures are deliberately broad and will also intercept the ordinary English word — a guild advertising itself as "Goon Squad", or someone calling a boss's adds hired goons. Untick **Explicit & NSFW Chat** in Defense Packs, or drop those two entries, if that trade-off is not worth it.

---

## [1.6.2] - 2026-08-16

### Fixed
- **Ads hidden inside hyperlink text are now caught.** Sellers wrap their entire ad in link display text (renamed battle pets / crafted links — the yellow "[WTS M+0 Dungeons…]" style), which the Hyperlink Shield previously excluded from matching entirely. The matcher now sees each link's *visible* text while still excluding link *data* (item ids, hex codes), so legitimate item/spell links keep their false-positive protection. Technique inspired by how BadBoy handles link spam.

### Added
- Boosting pack: `mythicstore` (boost-shop domain) and `vault fills` signatures.

---

## [1.6.1] - 2026-08-16

### Added
- **Boosting pack: 13 signatures for modern raid-sale spam** observed live in Trade (Services): `saved heroic`, `gold only`, `pay in raid`, `best service`, `best price guaranteed`, `gear service`, `pm for booking`, `world tour`, `24/7 support`, refreshed `80-90` leveling ranges, and the `gamer-choice` boost shop. These ads avoid the classic boost/carry/gold vocabulary entirely, advertising via raid links plus phrases like "SAVED HEROIC [GOLD ONLY · PAY IN RAID]".

### Notes
- Enabling a pack only affects messages that arrive afterward — lines already in your chat window are never retro-filtered.
- The `aotc` signature is intentionally aggressive and will also intercept guild-recruitment messages that mention AOTC.

---

## [1.6.0] - 2026-08-16

### Fixed
- **Electronic Jamming (MASK) now actually censors.** The old masking pattern used PCRE syntax Lua doesn't support, so matched spam passed through completely uncensored while being counted as intercepted. Masking is now case- and leet-tolerant (`TRUMP`, `g0ld`, `TRVMP` all censor) and falls back to censoring the whole message when a normalized-only match can't be located.
- **29 punctuated PHRASE signatures were dead** (`wts m+`, `m+ carry`, `pro-life`, `wts 1-80`, `discord . gg`, `raider.io boost`, ...). Rules are now compiled into the same punctuation-stripped space messages are matched in, with word-boundary anchors.
- **Repo/TOC mismatch**: the TOC is now `C-Spam.toc` (matching the repository folder), texture paths derive from the installed folder name, and a release workflow packages correctly-named zips with LibStub/LibDataBroker/LibDBIcon bundled.
- **Per-character whitelist works again** (it was silently dropped in 1.5.0) and is manageable via `/cs safe <name>`.
- **Stats no longer double-count** when multiple chat windows show the same channel, and identical repeat spam inside the cache window now reaches the Intercept Log (aggregated as `(xN)` instead of flooding it).
- **Hyperlink placeholders can no longer trigger rules** (e.g. a custom `link`/`spam` CONTAINS rule matching every message containing an item link).
- **`/cs add` with multi-word input** now registers a working PHRASE rule instead of an EXACT rule that could never match; import validates modes, infers them for unprefixed lines, and skips duplicates.
- **Emote filtering has a toggle** — channel checkboxes are generated from one descriptor shared with the event filter, ending Say/Yell read/write drift.
- **ElvUI round minimaps** no longer force the fallback button onto square-edge math; changing engagement protocol or decoder options takes effect immediately (decision cache invalidates).

### Changed
- Spaced-out evasion (`t r u m p`, `t.r.u.m.p`) is now genuinely decoded, as the UI always claimed; repeat-collapse works with leet decoding disabled.
- Whitelist checks are O(1) lookups rebuilt on roster events instead of full friends/BNet/guild scans per message; homoglyph decoding is a single pass; the live Intercept Log coalesces refreshes and rows no longer rebuild backdrops/closures every refresh.
- Defense Packs tab renders from `Data/DefaultPacks.lua` (new `example`/`order` fields) — new packs appear automatically; the minimap button and console share one toggle/tooltip implementation.

### Removed
- Dead SavedVariables fields (`options.checkPunctuation`, `whitelist.raid`, `stats.startTime`), the unused `C_SPAM` global alias, and the no-op `PLAYER_LOGOUT` handler.

---

## [1.5.0] - 2026-08-15

### Fixed
- **Upright Minimap & Titlebar Icon**: Fixed TGA vertical scanline orientation in `icon.tga` and `icon_64.tga` so the turret icon renders completely upright in-game.
- **Minimap Button Size & LibDBIcon Integration**: Standardized button dimensions to `31x31` and integrated `LibDataBroker-1.1` and `LibDBIcon-1.0` so ElvUI and minimap bar addons automatically dock, scale, and skin the C-SPAM button alongside your other addon buttons.
- **ElvUI Dark Transparent Backdrops**: Updated the console's backdrop styling to use `SetTemplate("Transparent")` / 78% translucent dark backdrops, matching ElvUI's frosted aesthetic where the game world is visible through the window.

---

## [1.4.1] - 2026-08-15

### Fixed
- **Live Intercept Log Telemetry**: Intercepted threats now stream live into Tab 3 in real-time.

---

## [1.4.0] - 2026-08-15

### Added
- **Expanded Defense Matrix**: 491 signatures across all 3 packs.
