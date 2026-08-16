# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
