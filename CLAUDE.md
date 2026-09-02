# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

**Osiris** is a personal [Omarchy](https://omarchy.org/) (Hyprland/Quickshell)
desktop config: a dark indigo/violet theme with a live animated wallpaper, a
custom floating-islands status bar, a now-playing media pill with an audio
spectrum, an accent-lit launcher menu, a themed lock screen and screensaver,
and matching Neovim, Spotify, and Discord themes.

- **Remote:** `github.com/xElectric9177/Osiris`, branch `main`.
- **License:** GPL v3 (`LICENSE`), except third-party assets noted in `NOTICE`.
- This is a **curated release repo, not a full config mirror.** It vendors
  specific files (README, LICENSE, NOTICE, CHANGELOG, screenshots, the
  `amendale.*` plugins, `osiris-*` scripts, theme files). It does not track the
  whole `~/.config`.

## Critical: this working tree is a separate copy from `~/.config`

The live config lives in `~/.config` and `~/.local`. This repo (`~/Osiris`) is
a **separate copy**. A change made live does **not** appear here automatically,
and vice versa.

**When applying a live config edit to this repo:** copy the edited file from
`~/.config/...` (or `~/.local/...`) into the matching path under
`~/Osiris/.config/...` (or `~/Osiris/.local/...`), *then* commit. Never assume
the repo copy is current — diff it first.

## Repo layout

```
.config/omarchy/
├── themes/osiris/            colors.toml, live wallpaper + still, shell.menu.toml
├── plugins/amendale.*/       custom Quickshell plugins (each has its own README)
├── hooks/                    theme-set.d, post-boot.d, post-update.d
├── branding/osiris-eye.txt   braille eye logo (fastfetch + About)
├── themed/*.tpl              fastfetch + lazygit theme templates
└── shell.json                bar layout + transparency
.config/hypr/                 looknfeel.lua, input.lua (user overrides)
.config/cava/config.osiris    feeds the media pill visualizer
.config/spicetify/…           Spotify theme (color.ini, not auto-synced)
.config/vesktop/themes/       Discord themes (.theme.css)
.local/bin/                   osiris-* scripts + omarchy-screensaver + POPUP-ANIMATION.md
install.sh                    full one-command installer (see below)
install-theme.sh              theme-only installer (see below)
CHANGELOG.md  README.md  LICENSE  NOTICE  screenshots/
```

The `amendale.*` bar plugins and the `osiris-*` scripts each carry their own
README or header explaining load-bearing details — **read the relevant one
before editing a plugin or script.** Notable ones:
`.config/omarchy/plugins/amendale.bar/README.md`, `amendale.media/README.md`,
`amendale.menu/README.md`, `amendale.lock/README.md`, and
`.local/bin/POPUP-ANIMATION.md`.

## Naming conventions

- **"osiris"** is the user's personal namespace. Keep it: `osiris-*` for
  scripts/hooks/theme, `amendale.*` for bar plugins, `-- Osiris:` comment
  prefix and `_G.__osiris_*` globals in Hyprland `.lua` files.
- Plugin ids are load-bearing and cross-referenced by other files (e.g.
  `amendale.bar` filters on the exact id `amendale.media`). Don't rename a
  plugin without updating every reference — see each plugin's README.

## Git / commit workflow

- **Commit subjects:** imperative mood ("Add a notification center to the bar").
- **Two release styles** — ask the user which unless they've said:
  1. **Full release:** add a `CHANGELOG.md` entry (Keep a Changelog format,
     newest first) + bump the version, commit "cut the release" style.
  2. **Plain commit:** for small fixes, just commit (no changelog/version bump).
- CHANGELOG versions are milestones ("how much of the desktop changed"), semver
  in spirit only — this is a personal config, not an API.
- Adding a **not-yet-tracked file** to the repo: confirm with the user first
  (some live files are intentionally untracked).
- **Never** push to a branch other than `main` here, force-push, or merge
  without being asked. Confirm before pushing.
- **Always update this `CLAUDE.md`** as part of any change to the repo (standing
  request from the user) — document new components, gotchas, and workflows here
  so the next session can make changes without rediscovering them.

## Boot animation (Plymouth) — `osiris-plymouth-glitch`

The boot/unlock splash is a **custom Plymouth theme**, not the stock Omarchy one.
Root is LUKS-encrypted, so Plymouth's unlock screen is the first thing at boot
(not SDDM — autologin is on; not the Quickshell lock — that's the idle/manual
locker `amendale.lock`).

- **Why a separate theme, not a patch:** `omarchy update` overwrites
  `/usr/share/plymouth/themes/omarchy`, and `omarchy-plymouth-set` always
  republishes the packaged `omarchy.script`. So the animation lives in its own
  theme dir `/usr/share/plymouth/themes/osiris`, set as default via
  `plymouth-set-default-theme` — omarchy update never touches it.
- **`.local/bin/osiris-plymouth-glitch`** is the generator. It reads the active
  theme's `colors.toml`, renders `branding/screensaver.txt` (the OSIRIS wordmark)
  into a baked block-decrypt glitch frame sequence + a faded braille "eye"
  backdrop + recoloured password/progress assets, emits `osiris.script` +
  `osiris.plymouth`, installs to the osiris theme dir, sets it default, and
  rebuilds + **signs** the initramfs (`limine-mkinitcpio`, else `mkinitcpio -P`).
  Needs sudo. `STAGE_ONLY=1` renders + stages into a temp dir and skips every
  privileged step (use it to preview / test without touching the system).
  Tunables at the top: `OSIRIS_GLITCH_FRAMES`, `FRAME_W`, `BLOCK`,
  `OSIRIS_PLYMOUTH_COLOR`, `OSIRIS_EYE_COLOR`.
- **Hook** `hooks/post-update.d/osiris-plymouth-glitch.sh` reasserts osiris as
  the default *only if* an update reset it (skips a redundant initramfs rebuild).
- **Gotchas baked into the generator, keep them:**
  - Plymouth can't run ImageMagick at boot, so the glitch is **pre-baked frames**
    the script cycles via `SetRefreshFunction`; the block-decrypt reveal keeps the
    frames small (~1.2 MB total) vs. per-pixel noise (~7.6 MB).
  - Sprites scale to a **fraction of `Window.GetWidth()`** at boot and frames are
    baked hi-res → crisp on **1440p minimum, up to 4K** (downscale, never up).
  - The Plymouth script dialect: **no bare `return;`** (use if/else); and in the
    generator, read `identify` dims via `$(...)` not `read` (its `-format` output
    has no trailing newline, which trips `read` under `set -e`).
- **Re-tint after a theme switch:** re-run `osiris-plymouth-glitch` (not
  automatic — it would sudo + rebuild the initramfs on every theme change).
- **Rollback:** `sudo plymouth-set-default-theme omarchy && sudo limine-mkinitcpio`.
- `branding/screensaver.txt` is shared: the **screensaver** (`omarchy-screensaver`
  → `ttfx`) and the boot splash both render it, so rebranding the wordmark
  changes both. (Superseded and removed: the older `osiris-plymouth-logo`, which
  only swapped a static logo onto the stock omarchy Plymouth/SDDM theme.)

## Requirements (for the config to fully work)

- Omarchy (base). `mpvpaper` (AUR) for the live wallpaper. `cava` for the media
  visualizer. Optional: `spicetify-cli` (Spotify), Vesktop+Vencord (Discord).
- Several pieces need manual symlinks / `PATH` ordering / a sudo patch on
  install — the README's **Install** section is the source of truth; keep it in
  sync when install steps change.

## `install.sh` — one-command installer

`install.sh` at the repo root is the **executable form of the README's Install
section**: it installs the full desktop (theme, bar, all 8 `amendale.*` plugins,
hooks, `themed/*.tpl`, `shell.json`, `looknfeel.lua`, cava config, the `osiris-*`
+ `omarchy-screensaver` scripts, branding art, the fastfetch eye logo, the
`.bash_profile` PATH line, and the fastfetch/lazygit/neovim theme links), then
prompts (default *no*) for the pieces that need sudo or touch other apps: the
Plymouth boot animation, the popup-animation patch, and the Spotify/Discord
themes. It also offers to install `cava` (pacman) and `mpvpaper` (yay/paru).

- It supports `curl | bash` by self-cloning when no checkout sits beside it;
  with no tty every prompt takes its default (core in, extras out).
- It backs up `shell.json` and `looknfeel.lua` to `*.pre-osiris` before
  overwriting, and is idempotent.
- **It does NOT copy `input.lua`** — that file holds machine-specific rules
  (the Steam/DP-3 fix) and is deliberately left out, matching the README.
- **Keep it in lockstep with the README Install section and this file.** When an
  install step, plugin, script, or dependency changes, update `install.sh`, the
  README, and this note together. `bash -n install.sh` before committing.

`install-theme.sh` is the **theme-only** sibling: it copies just the theme dir
(`.config/omarchy/themes/osiris`) and runs `omarchy theme set osiris` — the
palette everywhere Omarchy's theme system reaches, nothing else (no bar,
plugins, scripts, hooks, or boot animation). Its one opt-in prompt is the live
animated wallpaper (copies `osiris-live-wallpaper` + its two hooks, offers to
install `mpvpaper`); declined, the theme uses the static still. Same helpers,
self-clone, and no-tty defaulting as `install.sh`. Keep both in sync — a change
to the theme dir or the live-wallpaper wiring touches this script too.

## Third-party assets (do not relicense)

- **`osiris-live.mp4`** (+ derived still): from DesktopHut, author unidentified.
  Not covered by this repo's GPL. See `NOTICE` / `themes/osiris/backgrounds/CREDITS.md`.
- **`Osiris-DarkPlus.theme.css`**: a recolour of DevEvil's Dark+, used with
  permission, imported live (not redistributed). See `NOTICE`.
- When touching either, preserve the credit/attribution and don't claim
  ownership.
