# Osiris Config

Personal [Omarchy](https://omarchy.org/) config: the **Osiris** theme (dark
indigo/violet, live animated wallpaper) and a custom floating-islands status bar.

## Screenshots

![Live wallpaper and floating-islands bar](screenshots/wallpaper.png)
![btop and fastfetch themed to match](screenshots/terminal.png)

## What's here

```
.config/omarchy/
├── themes/osiris/            Theme: colors.toml + live wallpaper + static fallback
├── plugins/
│   ├── amendale.bar/         Custom bar (floating islands) — see its own README
│   └── amendale.media/       Now-playing pill: rounded art, progress bar — see its own README
├── hooks/theme-set.d/        Starts/stops the live wallpaper to match the active theme
├── themed/                   Extra theme templates Omarchy doesn't ship by default
│   ├── fastfetch.jsonc.tpl   Themes fastfetch (untouched by Omarchy's own templates)
│   └── lazygit.yml.tpl       Themes lazygit's UI chrome (borders/selection/accents)
└── shell.json                Bar layout + transparency

.config/hypr/
└── looknfeel.lua             10% opacity on unfocused windows, 8px rounding system-wide
```

Everything Omarchy already themes automatically from `colors.toml` — terminals
(Alacritty/Foot/Kitty/Ghostty), btop, Neovim, VS Code, Hyprlock, Chromium,
Obsidian, keyboard RGB — needs no extra files here; it just picks up
`themes/osiris/colors.toml` on `omarchy theme set osiris`. Starship also follows
automatically since it uses semantic ANSI color names rather than hex.

## Requirements

- [Omarchy](https://omarchy.org/)
- [`mpvpaper`](https://github.com/GhostNaN/mpvpaper) (AUR) — plays the live
  wallpaper. Without it, Omarchy falls back to the static still image.

## Install

```bash
cp -r .config/omarchy/themes/osiris ~/.config/omarchy/themes/
cp -r .config/omarchy/plugins/amendale.bar ~/.config/omarchy/plugins/
cp -r .config/omarchy/plugins/amendale.media ~/.config/omarchy/plugins/
cp .config/omarchy/hooks/theme-set.d/osiris-live-wallpaper-hook.sh ~/.config/omarchy/hooks/theme-set.d/
cp .config/omarchy/themed/*.tpl ~/.config/omarchy/themed/
cp .config/omarchy/shell.json ~/.config/omarchy/shell.json
cp .config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua

chmod +x ~/.config/omarchy/hooks/theme-set.d/osiris-live-wallpaper-hook.sh

# fastfetch/lazygit read their live config through a symlink into the current
# theme's rendered output, matching how Omarchy wires up btop — these aren't
# copied files, they need to be (re)created on any machine this is installed on:
ln -sf ~/.local/state/omarchy/current/theme/fastfetch.jsonc ~/.config/fastfetch/config.jsonc
ln -sf ~/.local/state/omarchy/current/theme/lazygit.yml ~/.config/lazygit/config.yml

omarchy theme set osiris
```

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
