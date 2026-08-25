# Osiris Config

Personal [Omarchy](https://omarchy.org/) config: the **Osiris** theme (dark
indigo/violet, live animated wallpaper), a custom floating-islands status bar
with a now-playing pill (rounded art, live audio spectrum), a lock screen with
a clock and username, a retinted screensaver, and a matching Spotify theme via
Spicetify.

## Screenshots

![Live wallpaper and floating-islands bar](screenshots/wallpaper.png)
![btop and fastfetch themed to match](screenshots/terminal.png)

## What's here

```
.config/omarchy/
├── themes/osiris/            Theme: colors.toml + live wallpaper + static fallback
├── plugins/
│   ├── amendale.bar/         Custom bar (floating islands) — see its own README
│   ├── amendale.media/       Now-playing pill: rounded art, progress bar — see its own README
│   └── amendale.lock/        Lock screen: clock + username above the wallpaper — see its own README
├── hooks/theme-set.d/        Starts/stops the live wallpaper to match the active theme
├── themed/                   Extra theme templates Omarchy doesn't ship by default
│   ├── fastfetch.jsonc.tpl   Themes fastfetch (untouched by Omarchy's own templates)
│   └── lazygit.yml.tpl       Themes lazygit's UI chrome (borders/selection/accents)
└── shell.json                Bar layout + transparency

.config/hypr/
└── looknfeel.lua             10% opacity on unfocused windows, 8px rounding system-wide

.config/spicetify/Themes/Osiris/
└── color.ini                  Spotify color scheme, mapped from colors.toml (not auto-synced)

.local/bin/
└── omarchy-screensaver       Retints all ~35 TTE screensaver effects to Osiris — see Install for why this lives here instead of a theme file

.config/cava/
└── config.osiris             Feeds the media pill's audio-spectrum visualizer
```

Everything Omarchy already themes automatically from `colors.toml` — terminals
(Alacritty/Foot/Kitty/Ghostty), btop, Neovim, VS Code, Chromium, Obsidian,
keyboard RGB — needs no extra files here; it just picks up
`themes/osiris/colors.toml` on `omarchy theme set osiris`. Starship also follows
automatically since it uses semantic ANSI color names rather than hex. The lock
screen is also already theme-reactive by default (only the clock/username are
custom, in `amendale.lock`) — note this system doesn't actually run `hyprlock`
at all; Omarchy replaced it with its own Quickshell lock screen (same for
`hypridle` — see `amendale.bar`'s README for that discovery), so a traditional
`hyprlock.conf` has no effect here.

## Requirements

- [Omarchy](https://omarchy.org/)
- [`mpvpaper`](https://github.com/GhostNaN/mpvpaper) (AUR) — plays the live
  wallpaper. Without it, Omarchy falls back to the static still image.
- [`cava`](https://github.com/karlstav/cava) (official repos, `pacman -S cava`)
  — powers the live audio-spectrum visualizer in the media pill's popup. Needs
  PipeWire (standard on Omarchy). Without it, that section just shows idle dots.
- [`spicetify-cli`](https://github.com/spicetify/cli) (AUR) — only needed if
  you also want the matching Spotify theme; everything else works without it.

## Install

```bash
cp -r .config/omarchy/themes/osiris ~/.config/omarchy/themes/
cp -r .config/omarchy/plugins/amendale.bar ~/.config/omarchy/plugins/
cp -r .config/omarchy/plugins/amendale.media ~/.config/omarchy/plugins/
cp -r .config/omarchy/plugins/amendale.lock ~/.config/omarchy/plugins/
cp .config/omarchy/hooks/theme-set.d/osiris-live-wallpaper-hook.sh ~/.config/omarchy/hooks/theme-set.d/
cp .config/omarchy/themed/*.tpl ~/.config/omarchy/themed/
cp .config/omarchy/shell.json ~/.config/omarchy/shell.json
cp .config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua
mkdir -p ~/.config/cava && cp .config/cava/config.osiris ~/.config/cava/
mkdir -p ~/.local/bin && cp .local/bin/omarchy-screensaver ~/.local/bin/
chmod +x ~/.config/omarchy/hooks/theme-set.d/osiris-live-wallpaper-hook.sh ~/.local/bin/omarchy-screensaver

# fastfetch/lazygit read their live config through a symlink into the current
# theme's rendered output, matching how Omarchy wires up btop — these aren't
# copied files, they need to be (re)created on any machine this is installed on:
ln -sf ~/.local/state/omarchy/current/theme/fastfetch.jsonc ~/.config/fastfetch/config.jsonc
ln -sf ~/.local/state/omarchy/current/theme/lazygit.yml ~/.config/lazygit/config.yml

omarchy theme set osiris
```

The screensaver script needs `~/.local/bin` to come *before* `$OMARCHY_PATH/bin`
in `PATH`, or the stock (un-retinted) `omarchy-screensaver` keeps winning. Add
this to **`~/.bash_profile`** specifically, not `~/.bashrc` — Hyprland's exec
dispatcher spawns login-but-non-interactive shells, which skip `.bashrc`'s
entire customization section (its first line returns immediately unless `$-`
contains `i`), but still run `.bash_profile` unconditionally:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile
```

No restart needed — the next screensaver launch re-resolves the command.

The custom bar needs one extra step `shell.json` can't express on its own: set
`"bar": {"id": "amendale.bar"}` (already in the copied `shell.json`) — Omarchy's
plugin-clone bar-swap path has a bug where a `required property` on the cloned
`Bar.qml`'s root item fails construction (see the plugin's own README); this
clone works around it, but if you re-clone from stock `omarchy.bar` on a fresh
machine, you'll hit that same bug and need to drop `required` from
`omarchyPath` / `barWidgetRegistry` / `barConfig` again.

Similarly, `amendale.media`'s `shell.json` entry (also already in the copied
file) is `{"id": "amendale.media"}`, and `amendale.bar`'s pill-splitting filters
on that exact id — if you ever re-clone the media widget under a different
name, both need updating together (see each plugin's own README for why).

`amendale.lock` needs no such manual step — it's a `service`-kind plugin, so
the copied `shell.json`'s `plugins` array already lists `{"id": "amendale.lock"}`
and disables the original the same way `omarchy plugin clone` would.

## Spotify (optional)

```bash
mkdir -p ~/.config/spicetify/Themes/Osiris
cp .config/spicetify/Themes/Osiris/color.ini ~/.config/spicetify/Themes/Osiris/
spicetify config current_theme Osiris color_scheme Osiris
spicetify apply
```

Restart Spotify to see it — `spicetify apply` patches the installed app's
files on disk, so a copy already running won't pick up the change until then.
