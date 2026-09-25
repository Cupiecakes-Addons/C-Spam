# Changelog

All notable changes to **C-SPAM** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
Signatures from replaying the Sep 18–25 chat log (3,301 public-channel messages) through v1.8.0. Together they catch 107 more of those messages, and nothing previously caught is lost.
- **Carries, Boosting & Gold Seller Spam (`boosting`)**: `delve carries`; `quick mount run` (a mount-run ad posted 16 times in one week); `northern sky` (a raid-run community ad).
- **Political Discourse & Elections (`politics`)**: `rfk`, `rfkjr`, `president xi`, `iran`, `irans`, `latinx`, `jordan peterson`, `politics`, `political`. Drama personalities: `drdisrespect`, `dr disrespect`, `lowtiergod`, `wingsofredemption`, `nikocado`, `nickocado`, `hungryfatchick`, `hungryfatchicks`, `lolcow`, `lolcows`.
- **Sexuality, Gender & Identity (`sexuality`)**: `wlw`, `butch`, `butches`, `bottom surgery`.
- **Toxicity, Harassment & Hostile Slurs (`toxicity`)**: `cunty`, `fatty`, `manchild`.
- **Explicit & NSFW Chat (`nsfw`)**: `anal` (one player posted ~35 "Anal <spell name>" lines), `sex`, `horny`, `fap`, `thicc`, `kink`, `kinky`, `boner`, `hooker`, `hookers`, `bhole`, `big booty`, `jerk off`, `jerking off`, `jerked off`, `jerked it`. Deliberately left out: `booty` on its own (Booty Bay) and `kinks` ("work out the kinks").

---

## [1.8.0] - 2026-09-25

### Fixed
- **Leet-spelled phrases slipped through**: messages are matched in leet-decoded form (digits, symbols and `v` become letters), but rules were only compiled as written, so any rule containing a `v`, a digit or a `+` stopped matching once the message used leet anywhere: `p0wer leveling`, `m+ b00st`, `s@ved heroic`, `v@nce` all passed. Rules now carry a decoded twin. Single-word rules deliberately written in leet (`d1e`) get none, so `die` stays allowed.
- **Icons and color codes were matched as text**: ElvUI's chat emoji arrive as `|TInterface\AddOns\ElvUI\...|t` texture escapes and 12.x item links color by name (`|cnIQ4:`), so file paths and escape fragments leaked into the matcher. Both are now extracted like links, and loose color codes are stripped so a keyword another addon has colored still matches.
- **MASK censored inside longer words**: EXACT and PHRASE matches now censor whole words only (masking `gold` no longer turns `Goldshire` into `****shire`); CONTAINS still censors substrings. Masked messages also keep their original spacing around links.
- **Intercept Log rows overlapped**: long ads wrapped past the fixed 40px row into the entry below; rows now size to their message.
- Long custom signatures no longer run under the Threat Matrix mode column.
- The Settings panel's slash-command list was missing `/cs safe`.

### Changed
- **~10x faster evaluation**: phrase rules are indexed by their first word, so a message is tested only against phrases that could start in it instead of all ~450 patterns (~350µs → ~35µs per clean message in offline benchmarks).
- **12.x chat APIs**: filters register through `ChatFrameUtil.AddMessageEventFilter` and the chat box helpers use `ChatFrameUtil` and the edit box mixin, falling back to the `ChatFrame_*` / `ChatEdit_*` globals that 12.x keeps only as deprecation shims slated for removal next expansion.
- Pass-through filter returns no longer re-pack every chat argument.
- The release zip ships only `Media/icon.tga`; README and social-preview artwork (~3 MB) stays in the repo.

---

## [1.7.9] - 2026-09-18

### Added
- **Carries, Boosting & Gold Seller Spam (`boosting`)**:
  - Added commercial sales and carry advert phrases: `selling heroic`, `selling mythic`, `selling raid`, `selling m+`, `selling key`.
  - Added inverted raid boss count patterns: `heroic 8/8`, `mythic 8/8`.
  - Added commercial discount codes: `coupon code`, `off coupon`.
- **Political & Culture Discourse (`politics`)**:
  - Added political authority terms: `politician`, `politicians`.
  - Added modern slang / culture terms: `simp`, `simps`, `simping`, `simped`.
- **Explicit & NSFW Chat (`nsfw`)**:
  - Added calibrated anatomical terms (`EXACT` token matching only to preserve substrings like `peninsula`): `penis`, `penises`.

---

## [1.7.8] - 2026-09-18

### Added
- **Expanded Defense Packs from Live Log Telemetry**:
  - **Carries & Boosting (`boosting`)**: Added 46 high-confidence signatures targeting commercial services, external portals, and raid/dungeon sales:
    - **External Portals & Platforms**: `epiccarry`, `gamingcy`, `playhub`, `goldboost`, `wechat`.
    - **Sales Hooks & Boilerplate**: `cheapest price`, `cheapest prices`, `best price match`, `flash sale`, `hot deal`, `oneshot group`, `one shot group`, `all loot for buyers`, `reserve your spot`, `spots very limited`, `spot very limited`.
    - **Raid & Carry Terminology**: `armor stacking`, `free armor stacking`, `free funnels`, `loot trader`, `vip funnel`, `full vip funnel`, `vip run`, `vip runs`, `vip option`, `8/8 heroic`, `8/8 full run`, `heroic full clear`, `full heroic run`, `saved or unsaved`, `saved unsaved`.
    - **In-Raid Payment Variations**: `payment inside raid`, `payments in raid`, `payment made within raid`, `pay inside the raid`, `trade inside raid`, `traid in the raid`.
    - **AFK & Leveling Formats**: `afkable`, `afk able`, `semi afk`, `chill for afk`, `duo booster`, `tww leveling`, `war within leveling`, `skyriding glyphs`, `quick delves`, `delves tier`, `delves all tier`, `multi runs`, `multiple runs`, `multiply runs`.
    - **Casino & Roll Gambling**: `casino is open`, `double your bet`, `deathroll`, `death roll`.
  - **Political Discourse (`politics`)**: Added missing Middle East geopolitical terms (`israel`, `palestine`) and high-frequency controversy terms (`epstein`, `presidential election`, `war on drugs`).
  - **Toxicity & Slurs (`toxicity`)**: Added common toxic dismissals and hostile remarks: `git gud`, `skill issue`, `dogshit`, `shitter`, `shitters`.
- **Cyrillic Te Homoglyph Support**: Added Cyrillic Capital Letter Te (`Т` / `\208\162`) to `HOMOGLYPH_MAP` in `Normalizer.lua`, neutralizing `[WТS]` evasion payloads.

---

## [1.7.7] - 2026-09-14

### Added
- **Dedicated Defense Pack: Sexuality, Gender & Identity (`sexuality`)**: Spun off sexual orientation, gender identity, and presentation terms into their own dedicated defense pack (106 calibrated signatures):
  - **Sexual Orientation & Identity**: `homosexual`, `heterosexual`, `bisexual`, `pansexual`, `asexual`, `demisexual`, `gay`, `gays`, `lesbian`, `lesbians`, `queer`, `queers`, `lgbt`, `lgbtq`, `lgbtqia`.
  - **Gender Identity & Transitions**: `trans` (`EXACT` token matching only), `transgender`, `transsexual`, `transphobia`, `transphobic`, `nonbinary`, `non-binary`, `cisgender`, `intersex`, `hrt`, `mtf`, `ftm`, `afab`, `amab`.
  - **Gender Presentation, Slang & Subculture**: `femboy`, `femboys`, `ladyboy`, `ladyboys`, `shemale`, `shemales`, `tgirl`, `tgirls`, `t-girl`, `tman`, `tmans`, `t-man`, `twink`, `twinks`, `tomgirl`, `tomgirls`, `crossdresser`, `crossdressers`, `crossdressing`, `crossdress`, `sissy`, `sissies`, `catboy`, `catboys`, `tranny`, `trannies`, and `fudge packer`.
  - **Discourse & Community**: `pronouns`, `neopronoun`, `neopronouns`, `deadname`, `deadnaming`, `deadnamed`, `misgender`, `misgendering`, `misgendered`, `gender identity`, `gender dysphoria`, `gender ideology`, `gender transition`, `gender affirmation`, `gender affirming`, `sex change`, `puberty blocker`, `puberty blockers`, `pride month`, `pride flag`, `pride parade`, `trans rights`, `trans woman`, `trans women`, `trans man`, `trans men`, `trans people`, `trans person`, `trans flag`, `trans activist`.
- **Defense Packs Overview Card Scrolling**: Upgraded the Defense Packs cards view to embed a smooth `ScrollFrame` with mouse-wheel scrolling, allowing 5 (or more) defense pack cards to scroll cleanly within the console without overflowing.

### Changed
- **Scrubbed Existing Packs**:
  - **Political Discourse (`politics`)**: Removed sexuality and gender identity items; pack reverted to its focused political/electoral/governance scope (228 signatures).
  - **Explicit & NSFW Chat (`nsfw`)**: Removed `fudge packer`, reassigning it to the new Sexuality, Gender & Identity pack (257 signatures).
  - **Pack Order**: Reordered packs to: 1. Political Discourse, 2. Sexuality, Gender & Identity, 3. Carries & Boosting, 4. Toxicity & Slurs, 5. Explicit & NSFW Chat.

---

## [1.7.6] - 2026-09-14

### Added
- **Political Discourse Pack: Sexuality & Gender Identity Signatures**: Expanded the Political Discourse defense pack from 228 to 265 calibrated signatures to intercept culture-war and rage-bait topics spammed in public channels:
  - **Sexual Orientation Discourse**: Added `homosexual`, `homosexuals`, `homosexuality`, `heterosexual`, `heterosexuals`, `heterosexuality`, `bisexual`, `bisexuals`, `bisexuality`, `pansexual`, `asexual`, `gay`, `gays`, `lesbian`, `lesbians`, `queer`, `queers`, `lgbt`, `lgbtq`, and `lgbtqia`.
  - **Gender Identity & Discourse Phrases**: Added `transgender`, `transgenders`, `transsexual`, `transsexuals`, `transphobia`, `transphobic`, `nonbinary`, `non-binary`, `gender identity`, `gender dysphoria`, `gender ideology`, `pride month`, `trans rights`, `trans woman`, `trans women`, `trans man`, and `trans men`.
  - **WoW False-Positive Protection**: Single-word tokens use strict `EXACT` matching so normal in-game terms and abbreviations (`transmog`, `transmogrification`, `character transfer`, `transport ship`, `transmute`, `Lion's Pride Inn`, `Sha of Pride`) pass through without false positive interceptions.

---

## [1.7.5] - 2026-09-13

### Fixed
- **Window Dragging & Movement**: Fixed an issue where the main addon console could not be moved or dragged. Added `OnDragStart` and `OnDragStop` handlers to both the main frame and the top title/header bar, allowing you to freely drag the console anywhere on screen.
- **Window Position Persistence**: When dragged, the console now saves its coordinates to `CSPAM_DB` (`windowPosition`) and automatically restores to your preferred screen position across `/reload` and game sessions.

---

## [1.7.4] - 2026-09-12

### Added
- **Interactive Hyperlinks in Intercept Log**: Full native chat link integration on blocked messages in the Intercept Log telemetry tab:
  - **Hover Tooltips**: Hovering over any item, mount, achievement, dungeon keystone, spell, or quest link immediately displays its game tooltip at the cursor.
  - **Click Integration (`SetItemRef`)**: Left-clicking an achievement or quest link opens the corresponding UI; Ctrl-clicking items/mounts opens the 3D Dressing Room preview; Shift-clicking pastes the link into active chat/macros.
  - **Clickable Player Names**: Sender names in the telemetry header are now formatted as player links (`|Hplayer:...|h`), allowing instant whisper or player context menu interactions on click.
- **Mouse Wheel Scroll Integration**: Enabled smooth mouse wheel scrolling across all scrollable panels (Threat Matrix, Defense Pack details, and Intercept Log), with event forwarding so wheeling directly over message rows scrolls seamlessly.

---

## [1.7.3] - 2026-09-12

### Fixed
- **Defense Pack Signature Viewer Row Rendering**: Fixed an unhandled Lua error when evaluating alternating row background colors (`C_ROW_EVEN`) that prevented signatures beyond the first row from rendering. All signatures (228 politics, 216 boosting, 136 toxicity, 258 nsfw) now load and scroll cleanly.
- **Removed Redundant Close Button**: Removed the duplicate bottom close button from the signature detail view, keeping the top `< Back to Packs` button and maximizing vertical scroll space for signatures.
- **Font Glyph Compatibility**: Replaced the unicode left arrow with ASCII `< Back to Packs` to prevent missing glyph question-box symbols on standard client game fonts.
- **Dynamic Signature Counter**: Filtered search matches and signature counts now update directly in the header title (e.g. `POLITICS & ELECTIONS (3 of 228 Signatures)`).

---

## [1.7.2] - 2026-09-12

### Added
- **Interactive Defense Pack Signature Viewer**: Clicking any pack's calibrated signature badge (e.g. `(228 calibrated signatures [View List])`) in the Defense Packs tab now transitions directly to a dedicated in-window signature browser.
- **Real-Time Signature Search**: Type any word or phrase in the search box to instantly filter through the 200+ signatures in that pack.
- **Color-Coded Mode Badges**: Each signature in the list clearly displays its tracking mode (`EXACT` in cyan, `PHRASE` in gold, `CONTAINS` in violet, `REGEX` in green).
- **Smooth Navigation**: One-click `← Back to Packs` button returns to the defense pack cards overview; switching tabs or closing the console automatically resets the view.

### Fixed
- **WowUp Addon Updater Compatibility**: Automatic packaging of version-stamped release archives (`C-Spam-vX.Y.Z.zip`) and BigWigs `release.json` metadata for seamless detection and 1-click updates in WowUp.

---

## [1.7.1] - 2026-09-12

### Added
- **Political Discourse pack widened from 156 to 228 signatures** to cover the rage-bait topics that start fights in Trade: reproductive rights (`abortion`, `prolife`, `prochoice`, `planned parenthood`), extremist movements (`nazi`, `white nationalist`, `white supremacy`, `kkk`, `proud boys`, `oath keepers`, `boogaloo`, `groyper`), the Israel–Gaza conflict (`zionist`, `zionism`, `hamas`, `hezbollah`, `idf`, `gaza`), manosphere slang (`incel`, `femcel`, `mgtow`, `looksmax`, `soyboy`, `tradwife`, `sigma male`, `andrew tate`, `sneako`, `fresh and fit`), drama streamers (`asmongold`, `zackrawrr`, `hasanabi`, `hasan piker`, `destiny`, `adin ross`, `xqc`, `kick.com`, plus `charlie kirk`), and culture-war buzzwords (`groomer`, `virtue signal`, `cancel culture`, `snowflake`, `psyop`, `sjw`, `clown world`). `EXACT` rules match whole tokens and never stem, so plurals and inflections the singular would miss are signatures of their own — `incels`, `zionists`, `groomers`, `redpilled`, `virtue signaling`, `white supremacists` and so on.
- **Toxicity pack: `cucks` and `cucked`**, which the existing `cuck` token rule could not reach. A `CONTAINS` stem would have covered both but would also have intercepted `cuckoo`.
- **Regression test for duplicate signatures.** Single-token rules from every pack share one index, so a term listed in two packs silently overwrote the first and the Intercept Log credited whichever pack `pairs()` happened to visit last. The smoke test now fails on any duplicate.

### Changed
- Political Discourse pack description and example updated for the wider scope. The pack keeps its name and its `politics` toggle key, so existing on/off state carries over.
- README pack list now includes Explicit & NSFW Chat, which it had omitted since 1.7.0.

### Notes
- 25 requested terms were already present and were not duplicated: `pro-life`, `pro-choice`, `roe v wade`, `antifa`, `alt-right`, `fascist`, `fascism`, `marxist`, `marxism`, `commie`, `qanon`, `maga`, `trump`, `biden`, `kamala`, `libtard`, `blackpill`, `redpill`, `woke`, `anti-woke`, `dei`, `crt` and `deep state` in Political Discourse; `cuck` in Toxicity; `cuckold` in Explicit & NSFW Chat.
- Three more need no rule of their own: `anti-abortion` and `neo-nazi` are caught by the `abortion` and `nazi` tokens once punctuation is stripped, and the `looksmax` stem already covers `looksmaxxing`.
- **`destiny` also intercepts the game.** Whole-word matching stops it firing inside other words, but Destiny the streamer and Destiny 2 the game are the same word, so `anyone still play destiny 2?` is intercepted too. Drop the signature if the game matters more than the streamer.
- Other deliberate trade-offs: `kkk` is also Brazilian Portuguese laughter (only a token of exactly three k's matches, so `kkkkkk` still passes), `boogaloo` catches the "Electric Boogaloo" sequel joke, `nazi` catches "grammar nazi", and `asmongold`/`asmon` will remove ordinary WoW chat about the streamer.
- Deliberately left out: `mog`/`mogging` (transmog), `great replacement` ("a great replacement for my trinket"), `libs` (addon libraries), and the bare names `hasan` and `tate`.

---

## [1.7.0] - 2026-08-21

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
