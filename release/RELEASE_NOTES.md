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
  a symlinked `Library/Caches` to the target. This is the free-certificate
  route that does not require an app group or a restricted bundle ID.
- **Free-certificate bad_query file form**: class 13, MobileGestalt
  SystemGroup, part 3, an 8-level `..` traversal to
  `com.apple.MobileGestalt.plist`, flags `0x8000000000` (no include-path bit).
  This is the form used by GestaltEdit on iOS 27 and the one that has worked
  for some free Apple ID signatures.
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
