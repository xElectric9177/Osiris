#!/bin/bash
# Theme changed: start the Osiris live wallpaper, or stop it for other themes.
# All the real logic (and the reason for mpvpaper's flags) lives in the shared
# launcher, which the post-boot hook calls too.
exec "$HOME/.local/bin/osiris-live-wallpaper" "$1"
