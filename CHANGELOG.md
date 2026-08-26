# Changelog

Notable changes to this config, newest first.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions are milestones for how much of the desktop changed — this is a
personal config, not an API, so semver is followed in spirit rather than to
the letter.

## [v0.4] — 2026-08-26

Adds Neovim and Discord to the set of things Osiris themes, and fixes two
things that had quietly stopped working.

### Added

- **Osiris theme for Discord** (`.config/vesktop/themes/Osiris.theme.css`),
  for Vesktop/Vencord. Original work rather than a fork: nearly all the colour
  comes from assigning Discord's own design tokens, so it fits in under 300
  lines where brute-forcing hashed class names takes well over a thousand and
  breaks on every client rebuild. Both the current token family
  (`--background-base-*`) and the legacy one (`--background-primary`) are set,
  so it survives either client generation. The member list keeps the collapse-
  to-60px / expand-to-240px-on-hover behaviour, targeted with substring
  selectors instead of exact hashes so a Discord rebuild doesn't break it.
  Self-contained — no `@import`, no remote assets.

- **Neovim/LazyVim now follows the theme.** Omarchy renders a complete LazyVim
  colorscheme spec (`bjarneo/aether.nvim` fed the Osiris palette) into
  `~/.local/state/omarchy/current/theme/neovim.lua`, but reaches it only via a
  symlink at `~/.config/nvim/lua/plugins/theme.lua` that it never creates
  retroactively — both migrations that touch it bail unless the link already
  exists. A Neovim config predating the Omarchy install therefore stays on stock
  tokyonight indefinitely, which is what had happened here. Added that symlink,
  plus Omarchy's `omarchy-theme-hotreload.lua` and `all-themes.lua` from
  `/etc/skel`, so Neovim retints along with `omarchy theme set` instead of being
  pinned to one palette.

### Fixed

- **Media pill's scrolling title had stopped.** The scroll was a
  `NumberAnimation on x` value source whose `running` was bound to
  `needsScroll` while its `from`/`to` were assigned afterwards by the debounce
  timer — so it started with the initial `0 -> 0` span and looped over zero
  distance. Changing from/to on a running animation does not restart it, and
  `needsScroll` stayed true across track changes, so the real distances were
  never picked up: the first long title never scrolled and later ones reused
  stale spans. Driven explicitly now via `applyScroll()`, confirmed against an
  isolated QML harness. The label also collapses whitespace runs, since MPRIS
  titles can carry newlines that turn it into a clipped two-line `Text`.

- **Live wallpaper appearing as a media player.** The `mpv-mpris` package
  symlinks its plugin into mpv's system-wide script directory, so every mpv
  process registers on D-Bus — including the one `mpvpaper` runs for the
  wallpaper. It showed in the now-playing popup as `osiris-live.mp4`, and not
  merely as clutter: a looping video is permanently "playing" and starts before
  anything else, so the shell's oldest-playing-wins tiebreak gave it the bar
  label over whatever music was actually on, and the media keys — which route
  through the same service — could land on the wallpaper. The wallpaper's mpv
  now runs with `load-scripts=no`, so it never registers at all. Scoped to that
  one process: mpv used normally keeps its MPRIS integration and the
  `mpv-mpris` package is untouched.

## [v0.3.1] — 2026-08-26

Bug-fix release. Two problems kept coming back — the live wallpaper freezing
and the bar losing its transparency — and both turned out to have specific
causes rather than being flaky.

### Fixed

- **Live wallpaper silently buried by any shell restart.** `mpvpaper` ran on
  the `background` layer, the same one Omarchy's shell uses for its own
  `omarchy-background` surface. Hyprland stacks within a single layer by map
  order, so every shell restart — an `omarchy update`, a plugin reload,
  `omarchy restart shell` — remapped the still image on top of the video. The
  video kept playing underneath at ~35% CPU, completely invisible, which read
  as "the wallpaper stopped animating". It now runs with `-l bottom`, a whole
  layer level above `omarchy-background`, so the ordering can no longer be lost
  to a race no matter what remaps or when.
- **Bar losing transparency at random.** Stock `omarchy.bar` toggles
  `bar.transparent` on a double-click of empty bar space and persists it to
  `shell.json`. On a floating-islands bar, "empty bar space" is most of the
  bar's width, so a stray double-click flattened the islands into an opaque
  slab — with no undo and nothing on screen to explain it. The gesture is
  removed from `amendale.bar`; `omarchy bar transparent <true|false|toggle>`
  still sets it deliberately, and `toggleTransparency()` is left defined but
  uncalled so the clone stays easy to diff against upstream.
- **Live wallpaper did not survive a reboot.** It only ever started from the
  `theme-set` hook, which fires on theme *changes*, so a fresh login left the
  static fallback on screen until the theme was re-applied by hand.

### Added

- `hooks/post-boot.d/osiris-live-wallpaper.sh` — starts the live wallpaper at
  login. Reads the active theme itself, so it is a no-op under any theme other
  than `osiris`.
- `.local/bin/osiris-live-wallpaper` — shared launcher called by both the
  `theme-set` and `post-boot` hooks, so the `mpvpaper` flags and the reasoning
  behind them live in exactly one place.
- README section on the live wallpaper: why `-l bottom` is load-bearing rather
  than a preference, and how to confirm the layer order with `hyprctl layers`.

### Changed

- Wallpaper attribution. `NOTICE` and
  `themes/osiris/backgrounds/CREDITS.md` record where the video came from
  (DesktopHut) and state plainly that we are not its author or copyright
  holder. The GPL v3 is scoped explicitly to our own config, plugins, scripts,
  and documentation, and does not cover the wallpaper.

## [v0.3] — 2026-08-25

- Launcher menu cloned to `amendale.menu` and anchored under the bar's left
  island instead of floating centered, sharing the island's left edge. This
  also deleted stock's anti-jump workaround: with a fixed top edge, the card
  can only grow downward, so the centered-card freeze logic became unnecessary.
- Slide-out animation on every popup — volume, bluetooth, network, monitor,
  power, weather, clock, agents, tailscale, dropbox, tray, media pill, and the
  launcher menu. 12px travel, 600ms `OutBack` open, 400ms close.
- `osiris-popup-animation`, a patcher for the two shared Quickshell components
  every popup funnels through, plus a `post-update` hook that re-applies it
  after each `omarchy update` so the animation tracks upstream instead of
  freezing a dozen plugins at one version.
- Menu chrome recoloured to accent purple via `themes/osiris/shell.menu.toml`,
  a theme-level section override — so it survives re-cloning the plugin, and
  the clipboard and emoji pickers inherit it for free.
- GNU GPL v3 licence added.

## [v0.2] — 2026-08-25

- Live audio-spectrum visualizer in the media pill's popup, fed by `cava`.
- Matching Spotify theme via Spicetify.
- All ~35 TTE screensaver effects retinted to the Osiris palette.
- Lock screen clock and username via `amendale.lock`, after finding that this
  system does not run `hyprlock` at all — Omarchy replaced it with its own
  Quickshell lock screen, so a traditional `hyprlock.conf` has no effect.

## [v0.1] — 2026-08-25

- Initial Osiris theme: dark indigo/violet palette, live animated wallpaper
  with a static fallback.
- Custom floating-islands status bar (`amendale.bar`), rendering the
  left/center/right widget groups as separate accent-outlined pills.
- Now-playing media pill (`amendale.media`) with rounded album art and a
  progress bar, split out into its own bar island.
- System-wide 8px rounding and reduced opacity on unfocused windows.

[v0.4]: https://github.com/xElectric9177/Osiris/compare/v0.3.1...v0.4
[v0.3.1]: https://github.com/xElectric9177/Osiris/compare/v0.3...v0.3.1
[v0.3]: https://github.com/xElectric9177/Osiris/compare/v0.2...v0.3
[v0.2]: https://github.com/xElectric9177/Osiris/compare/v0.1...v0.2
[v0.1]: https://github.com/xElectric9177/Osiris/releases/tag/v0.1
