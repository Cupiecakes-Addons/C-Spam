# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.9] - 2026-08-15

### Fixed
- **Subtext Right-Margin Bounding Widths**: Reduced subtext wrapping widths from `315px` to `280px` on 2-column cards, accounting for the 23px checkbox indentation so descriptions never bleed across the right border of cards.

---

## [1.0.8] - 2026-08-15

### Fixed
- **Radar & Config Card Heights & Padding**: Increased vertical padding and height on Monitored Airspace (Card 3).

---

## [1.0.7] - 2026-08-15

### Fixed
- **Normalizer Leetspeak Capture Error**: Replaced regex pattern substitution with single-pass table lookup (`text:gsub(".", LEET_MAP)`).

---

## [1.0.5] - 2026-08-15

### Fixed
- **Circular Minimap Icon**: Applied anti-aliased circular alpha masking and GPU `MaskTexture` (`TempPortraitAlphaMask`).
- **UI Description Text Wrapping**: Constrained all subtext font strings in the Radar & Config console tab.

---

## [1.0.4] - 2026-08-15

### Changed
- **WoW Retail 12.1.0 (Interface 120100) Compatibility**: Updated `.toc` interface headers to `120100`.

---

## [1.0.0] - 2026-08-15

### Added
- Initial Release of C-SPAM Phalanx Defense System.
