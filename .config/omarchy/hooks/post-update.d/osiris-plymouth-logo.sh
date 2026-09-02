#!/bin/bash

# `omarchy update` overwrites /usr/share/plymouth/themes/omarchy and the SDDM
# theme wholesale, reverting the boot/login screen to the stock Omarchy logo.
# Re-apply the OSIRIS logo (rendered from the branding art, tinted to the
# current theme) after the update lands.
#
# omarchy-plymouth-set needs sudo (it rebuilds the initramfs), but the updater
# keeps a sudo credential alive, so this runs without an extra password prompt.
# If it ever can't (no cached sudo, missing tool), it just logs and the system
# is left on the stock logo -- nothing else in the update is affected.

exec osiris-plymouth-logo
