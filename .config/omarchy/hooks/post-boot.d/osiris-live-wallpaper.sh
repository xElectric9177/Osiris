#!/bin/bash
# Session started: bring the live wallpaper up.
#
# Without this the wallpaper only ever starts from the theme-set hook, so a
# reboot leaves the static fallback on screen until the theme is re-applied by
# hand. Reads the active theme itself, so it's a no-op on any other theme.
exec "$HOME/.local/bin/osiris-live-wallpaper"
