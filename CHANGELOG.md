# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.4.1] - 2026-08-15

### Fixed
- **Live Intercept Log Telemetry Stream**: Connected the engine's message intercept pipeline directly to the UI (`UI:OnLogUpdated()`). New intercepted threat entries now stream and render into the **Intercept Log** tab in real-time without requiring a tab switch or reload.
- **Radar Standby Telemetry Display**: Added an aesthetic empty state message (`[ RADAR ACTIVE ] Standing by for telemetry...`) displayed when the log is purged or empty.

---

## [1.4.0] - 2026-08-15

### Added
- **Complete Defense Matrix Expansion (491 Total Calibrated Signatures)**: Added political leaders, governance terms, boosting packages, payment services, death wishes, match griefing, and slur evasions.
