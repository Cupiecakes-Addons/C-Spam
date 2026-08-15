# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.1] - 2026-08-15

### Fixed
- **Settings Persistence on `/reload`**: Implemented recursive dictionary-only merge in `CopyDefaults` and registered `PLAYER_LOGOUT` handler in `Core/Init.lua` to ensure custom rules, channel toggles, and minimap angles are never wiped on UI reloads.
- **`contentPanels` Nil Error**: Elevated `contentPanels` and `tabButtons` to file-level scope in `UI/FilterListUI.lua`, resolving the Lua crash that occurred when switching tabs or refreshing state.
- **Minimap Mouseover Glitch**: Replaced Blizzard's default opaque `UI-Minimap-ZoomButton-Highlight` with a subtle white additive glow (`0.25` alpha) so the turret artwork remains sharp and visible on hover.
- **Minimap Button Frame**: Removed square backdrop and green bounding box from `UI/MinimapButton.lua`, rendering the turret icon as a seamless circular asset.

### Added
- **Dynamic Minimap Dragging**: Added smooth drag positioning around circular and square (ElvUI) minimap perimeters with angle persistence.
- **Smart Tooltip Placement**: Added screen-quadrant aware anchoring for the telemetry tooltip to prevent off-screen clipping.

---

## [1.0.0] - 2026-08-15

### Added
- **Core Interceptor Engine**: $O(1)$ fast-path token matching and compiled phrase pattern scanner.
- **Boundary Isolation & Normalizer**: Leetspeak normalization (`@` -> `a`, `0` -> `o`, `$` -> `s`, `!` -> `i`, `v` -> `u`), Cyrillic homoglyph translation, and stutter reduction (`"traaaash"` -> `"trash"`).
- **Hyperlink Shield**: Complete protection for `|c...|Hitem:...|h` links to prevent broken link colors and false positive intercepts.
- **Pre-Calibrated Defense Packs**: 1-click toggles for Political Discourse, Carries/Boosting Spam, and Toxicity/Hostile Slurs.
- **IFF Whitelist Bypass**: Automatic bypasses for Friends, Guildmates, and Party/Raid allies.
- **Dual Engagement Protocols**: Kinetic Intercept (silent drop) and Electronic Jamming (censor `***`).
- **ElvUI-Themed Console**: 5 tactical tabs with interactive tooltips, search filters, and import/export capabilities.
- **Custom Artwork**: High-resolution 32-bit RGBA C-RAM rotary turret icon textures (`Media/icon.tga`, `Media/icon.png`).
