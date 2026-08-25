#!/bin/bash

# `omarchy update` replaces /usr/share/omarchy wholesale, which reverts the
# popup slide animation patched into the shared Ui components. Re-apply it.
#
# This runs after the new upstream files have landed, so the patch is applied
# to the *current* version rather than restoring stale copies — the animation
# rides along with upstream fixes instead of freezing them.
#
# If upstream refactors the code the patch targets, the patcher aborts with a
# specific error and leaves the shell working, just without the animation.

exec osiris-popup-animation apply
