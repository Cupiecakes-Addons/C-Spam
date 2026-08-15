# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.4] - 2026-08-15

### Changed
- **Updated Interface Version to 12.1.0 (`120100`)**: Updated `.toc` interface headers (`## Interface: 120100` and `## Interface-Retail: 120100`) to match current retail client build `12.1.0.69299`, ensuring native out-of-the-box loading without "out of date" flags in WoW and WowUp.

---

## [1.0.3] - 2026-08-15

### Fixed
- **Icon Orientation & Color Accuracy**: Re-encoded `icon.png`, `icon.tga`, and `icon_64.tga` right-side up directly from the square source art.
- **GitHub README Logo**: Added `Media/logo.png` to bust GitHub Camo Markdown proxy cache.

---

## [1.0.1] - 2026-08-15

### Fixed
- **Settings Persistence on `/reload`**: Implemented recursive dictionary-only merge in `CopyDefaults` and registered `PLAYER_LOGOUT` handler in `Core/Init.lua`.
- **`contentPanels` Nil Error**: Elevated `contentPanels` and `tabButtons` to file-level scope in `UI/FilterListUI.lua`.
- **Minimap Button**: Replaced Blizzard zoom highlight with subtle additive glow and removed square backdrop.

---

## [1.0.0] - 2026-08-15

### Added
- Initial Release of C-SPAM Phalanx Defense System.
