# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-08-15

### Added
- **Expanded Boosting & Carries Defense Pack**: Added 38 new calibrated signatures to the *Carries & Gold Spam* pack covering power leveling, AFK leveling, dungeon/delve carries, level brackets (`power level`, `powerleveling`, `fast power level`, `can afk`, `full afk`, `wts 1-80`, `wts 70-80`, `delve boost`, `wts keys`, etc.) to eliminate modern Trade/Services spam.

---

## [1.0.9] - 2026-08-15

### Fixed
- **Subtext Right-Margin Bounding Widths**: Reduced subtext wrapping widths to `280px` on 2-column cards.

---

## [1.0.8] - 2026-08-15

### Fixed
- **Radar & Config Card Heights & Padding**: Increased vertical padding and height on Monitored Airspace (Card 3).

---

## [1.0.7] - 2026-08-15

### Fixed
- **Normalizer Leetspeak Capture Error**: Replaced regex pattern substitution with single-pass table lookup.

---

## [1.0.5] - 2026-08-15

### Fixed
- **Circular Minimap Icon**: Applied anti-aliased circular alpha masking and GPU `MaskTexture`.

---

## [1.0.4] - 2026-08-15

### Changed
- **WoW Retail 12.1.0 Compatibility**: Updated `.toc` interface headers to `120100`.
