#!/bin/bash

# `omarchy update` replaces /usr/share/omarchy wholesale, which reverts the
# app-library fix patched into the packaged shell.qml. Without it, a cloned
# menu plugin (amendale.menu) loses its Apps list ("Nothing here yet"). This
# re-applies the patch after every update.
#
# This runs after the new upstream shell.qml has landed, so the patch rides
# along with upstream fixes rather than freezing a vendored copy. It is the fix
# from omacom/omarchy PR #10785, which was closed unmerged, so it is not coming
# upstream.
#
# If upstream refactors the code the patch targets, the patcher aborts with a
# specific error and leaves the shell working, just without the fix.

exec osiris-menu-applibrary-patch apply
