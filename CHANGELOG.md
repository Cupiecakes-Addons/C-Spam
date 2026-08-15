# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.5] - 2026-08-15

### Fixed
- **Circular Minimap Icon**: Applied anti-aliased circular alpha masking to `icon.tga` and `icon.png` (transparent background outside the bronze porthole ring) and integrated GPU `MaskTexture` (`TempPortraitAlphaMask`) in `UI/MinimapButton.lua` to guarantee a 100% round silhouette on all minimap layouts.

---

## [1.0.4] - 2026-08-15

### Changed
- **WoW Retail 12.1.0 (Interface 120100) Compatibility**: Updated `.toc` interface headers to `120100` for client `12.1.0.69299`.

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
