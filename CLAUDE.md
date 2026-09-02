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

## Requirements (for the config to fully work)

- Omarchy (base). `mpvpaper` (AUR) for the live wallpaper. `cava` for the media
  visualizer. Optional: `spicetify-cli` (Spotify), Vesktop+Vencord (Discord).
- Several pieces need manual symlinks / `PATH` ordering / a sudo patch on
  install — the README's **Install** section is the source of truth; keep it in
  sync when install steps change.

## Third-party assets (do not relicense)

- **`osiris-live.mp4`** (+ derived still): from DesktopHut, author unidentified.
  Not covered by this repo's GPL. See `NOTICE` / `themes/osiris/backgrounds/CREDITS.md`.
- **`Osiris-DarkPlus.theme.css`**: a recolour of DevEvil's Dark+, used with
  permission, imported live (not redistributed). See `NOTICE`.
- When touching either, preserve the credit/attribution and don't claim
  ownership.
