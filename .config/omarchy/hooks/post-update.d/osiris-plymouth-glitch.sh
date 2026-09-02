#!/bin/bash

# Reassert the OSIRIS glitch-reveal Plymouth theme after `omarchy update`.
#
# The theme lives in its own dir (/usr/share/plymouth/themes/osiris), which
# omarchy update doesn't touch, so its files survive. But an update (or a
# migration) can reset the Plymouth *default* back to the stock omarchy theme
# and rebuild the initramfs around it. If that happened, re-run the generator
# to set osiris back as default and rebuild; if the default is still osiris,
# do nothing (skips an expensive, redundant initramfs rebuild).

current=$(plymouth-set-default-theme 2>/dev/null || true)
if [[ -d /usr/share/plymouth/themes/osiris && $current != "osiris" ]]; then
  exec osiris-plymouth-glitch
fi
