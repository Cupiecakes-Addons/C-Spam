# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
