# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.6] - 2026-08-15

### Fixed
- **Normalizer Leetspeak Capture Error**: Fixed Lua `invalid capture index` error in `Core/Normalizer.lua` (`ApplyLeetTranslation`). Replaced multi-loop regex pattern substitution with a fast, safe, single-pass table-driven `text:gsub(".", LEET_MAP)` lookup, completely eliminating Lua `%1`–`%9` regex capture bugs when scanning numbers and symbols in chat.

---

## [1.0.5] - 2026-08-15

### Fixed
- **Circular Minimap Icon**: Applied anti-aliased circular alpha masking and GPU `MaskTexture` (`TempPortraitAlphaMask`) in `UI/MinimapButton.lua`.
- **UI Description Text Wrapping**: Constrained all subtext font strings in the Radar & Config console tab with column-aware widths and `SetWordWrap(true)`.

---

## [1.0.4] - 2026-08-15

### Changed
- **WoW Retail 12.1.0 (Interface 120100) Compatibility**: Updated `.toc` interface headers to `120100` for client build `12.1.0.69299`.

---

## [1.0.3] - 2026-08-15

### Fixed
- **Icon Orientation**: Fixed upside-down orientation across all icon assets.

---

## [1.0.1] - 2026-08-15

### Fixed
- **Settings Persistence**: Fixed SavedVariables persistence on `/reload`.
- **`contentPanels` Nil Error**: Fixed table scope in `UI/FilterListUI.lua`.

---

## [1.0.0] - 2026-08-15

### Added
- Initial Release of C-SPAM Phalanx Defense System.
