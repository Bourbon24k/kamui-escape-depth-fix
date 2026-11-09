# KAMUI 2.5.0 — full MCM container escape + Files browser

## What's new in 2.5.0

- **Files tab / full MCM container access**: browse app data, app groups,
  system groups, system data, internal daemons and plugins. Read, edit text,
  import and delete files through the class-7 escape.
- **Crash fix**: the post-load Gestalt key-sorting crash is fixed; keys are
  filtered to strings and sorted with CoreFoundation.
- **Localization** for the Files UI in English, Russian, Korean, Arabic,
  Turkish, Ukrainian and Vietnamese.
- All 2.4.16 Explore, Gestalt and import hardening is retained.

### Scope

This is full access across **MCM containers**, not root or arbitrary
filesystem access. A symlink inside a container to a path outside MCM is still
denied by the sandbox.

---

# KAMUI 2.4.16 — fix Explore filter contrast

## What's new in 2.4.16

- Add Explore source filters for Cowabunga, CAPlayground, or both catalogs, plus an Apple wallpaper filter for Cowabunga.
- Fix selected Explore filter labels disappearing in dark mode by using dynamic system colors and explicit label contrast.
- Retain the 2.4.15 safeguards for Gestalt value types, wallpaper archive sizes, bounded logs, and MCM symbol checks.

## Build details

- App version: `2.4.16`
- Build: `2416`
- IPA: `build/KAMUI-2.4.16.ipa`

---

# KAMUI 2.4.15 — harden value handling and imports

## What's new in 2.4.15

- Safely render Gestalt switches when CacheExtra values have unexpected plist types.
- Reject oversized wallpaper archives and ZIP entries to avoid excessive memory use during import.
- Keep the diagnostic log bounded by rotating it after 2 MB.
- Check required MCM symbols before attempting sandbox queries.

## Build details

- App version: `2.4.15`
- Build: `2415`
- IPA: `build/KAMUI-2.4.15.ipa`

---

# KAMUI 2.4.14 — stable Gestalt key sorting

## What's new in 2.4.14

- Replace selector-based MobileGestalt key sorting with CoreFoundation comparison to prevent the `localizedCaseInsensitiveCompare` crash.
- Keep non-string dictionary keys out of the displayed key list.

## Build details

- App version: `2.4.14`
- Build: `2414`
- IPA: `build/KAMUI-2.4.14.ipa`

---

# KAMUI 2.4.13 — avoid selector-based Gestalt key sorting

## What's new in 2.4.13

- Sort MobileGestalt keys with CoreFoundation string comparison instead of dynamically dispatching `localizedCaseInsensitiveCompare:`.
- Keep non-string dictionary keys out of the displayed key list.

## Build details

- App version: `2.4.13`
- Build: `2413`
- IPA: `build/KAMUI-2.4.13.ipa`

---

# KAMUI 2.4.12 — filter invalid wallpaper entries

## What's new in 2.4.12

- Skip macOS `.DS_Store` files and other non-descriptor entries when importing wallpaper packs, preventing junk entries from being written into PosterBoard.
- Validate descriptor folders before applying them.
- Reset PosterBoard once after installing this update to remove invalid entries written by older builds.

## Build details

- App version: `2.4.12`
- Build: `2412`
- IPA: `build/KAMUI-2.4.12.ipa`

---

# KAMUI 2.4.11 — restored Gestalt tools and settings

## What's new in 2.4.11

- Restored advanced Gestalt controls for version and AI device spoofing, Apple Intelligence, Siri region, experimental iPadOS mode, ResearchFuse, and Store Demo Mode. Risky changes require confirmation.
- Restored language selection for English, Russian, Korean, Arabic, Turkish, Ukrainian, and Vietnamese, plus the optional in-app test-device banner and editable group label.
- Preserved the current Gestalt backup validation, pending-edit protection, Dynamic Island handling, and PosterBoard workflow.
- Left the unsupported class-2 sandbox fallback out of Settings.

## Build details

- App version: `2.4.11`
- Build: `2411`
- IPA: `build/KAMUI-2.4.11.ipa`

---

# KAMUI 2.4.3 — iOS 27.0.1–27.2 sandbox escape + MobileGestalt editor

**Open source, MIT licensed and free for everyone.** There is no tester list,
private group or allowlist. Anyone can use, modify and redistribute KAMUI and
the MobileGestalt editor.

## Assets

- `KAMUI-2.4.3.ipa` — the app. Install it on any supported device.
- Source code and build instructions are in the repository.

## What's new in 2.4.3

- **Languages**: English, Russian, Korean, Arabic, Turkish, Ukrainian and
  Vietnamese. Settings → Language switches the app language and offers System
  default. Arabic uses RTL layout.
- **`.tendies` fix**: descriptors are written to both
  `com.apple.WallpaperKit.CollectionsPoster` and
  `com.apple.Posters.CollectionsPosterApp`, and the PosterBoard refresh marker
  (`com.apple.PosterBoard.unprotectedUserDefaults.plist`) is written. This
  targets the gray-poster/dummy-wallpaper problem. Container-format packs keep
  their original descriptor UUIDs.
- **Class-12 geod built-in container**: direct part-3 token for
  `com.apple.geod` (flags `0x8000000000`, `0x0800000000`, `0x8100000000`), then
  a symlinked `Library/Caches` to the target. This is the free-account
  route that does not require an app group or a restricted bundle ID.
- **Free-account bad_query file form**: class 13, MobileGestalt
  SystemGroup, part 3, an 8-level `..` traversal to
  `com.apple.MobileGestalt.plist`, flags `0x8000000000` (no include-path bit).
  This is the form used by GestaltEdit on iOS 27 and the one that has worked
  for some free Apple ID installs.
- **Class-2 `RENAME_SWAP` probe**: atomically swaps `Library/Caches` with a
  symlink to the target, queries class 2, then swaps back. This may bypass the
  plain-rename denial without moving Library or causing the 2.2 crash.
- **Class-2 staged symlink probe**: a fake `Library/Caches` tree inside the
  app’s own Caches, resolved through a `partDomain` symlink. It is safe, needs
  no app group, and verifies the token against the target before reporting
  success.
- **Class-2 subpath probe**: creates a temporary symlink inside the app’s own
  `Library/Caches` and asks MCM for part 3 with a `partDomain`. It is safe and
  needs no app group. Successful tokens are verified by opening the target.
- **All app groups**: class 7 tries every app group in the running build, not
  just the first one.
- The opt-in class-2 parent fallback and its crash guard remain from 2.3.1.
- The “MCM query returned no sandbox token” error is localized and points to
  `Documents/bqtool.log`.

## Runtime requirement

The primary 27.2 class-7 strategy needs at least one
`com.apple.security.application-groups` entitlement in the running app. If
there is none, KAMUI tries the safe class-2 subpath probe. The class-2 parent
fallback is opt-in in Settings because some builds terminate the app when
`Library` is moved.

## Tested

iOS 27.2 (24B115): MG read/write, PosterBoard descriptors, `.tendies` pipeline,
live Dynamic Island. 27.0.1–27.2 use the same MCM query; open an issue with
`Documents/bqtool.log` if a strategy fails.

## Warnings

iPadOS mode, AI/Siri spoofing, ResearchFuse, Store Demo Mode and version
spoofing are high risk. They can break Face ID, layout, OTA updates or boot
behavior. Keep `OriginalGestalt.plist` and use Revert if anything misbehaves.

## License

MIT. Use it, fork it, ship it, sell it — keep the copyright and permission
notice. See `LICENSE`.

## Disclosure

KAMUI is public research. If you find a bug in the app, open an issue. If you
want to report the underlying MCM behavior to Apple, use Apple Security
Bounty. See `SECURITY.md`.
