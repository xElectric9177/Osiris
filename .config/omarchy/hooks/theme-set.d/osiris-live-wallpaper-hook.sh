#!/bin/bash
# Starts/stops the Osiris live wallpaper (mpvpaper) to match the active theme.
THEME_NAME=$1
VIDEO="$HOME/.config/omarchy/themes/osiris/backgrounds/osiris-live.mp4"

pkill -9 -f "mpvpaper.*osiris-live\.mp4" 2>/dev/null
# SIGTERM isn't reliably reaped before the next mpvpaper claims the layer
# surface, so hard-kill and give it a moment to actually release before
# remapping — otherwise two instances briefly fight over the same output.
for i in 1 2 3 4 5; do
  pgrep -f "mpvpaper.*osiris-live\.mp4" >/dev/null || break
  sleep 0.2
done

if [[ "$THEME_NAME" == "osiris" && -f "$VIDEO" ]] && command -v mpvpaper >/dev/null; then
  mpvpaper -f -p -o "no-audio loop" ALL "$VIDEO"
fi
