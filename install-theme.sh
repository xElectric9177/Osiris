#!/usr/bin/env bash
# Osiris — theme-only installer for Omarchy.
#
#   git clone https://github.com/xElectric9177/Osiris && ~/Osiris/install-theme.sh
#   curl -fsSL https://raw.githubusercontent.com/xElectric9177/Osiris/main/install-theme.sh | bash
#
# Installs and applies only the Osiris theme + wallpaper. For the full desktop
# use ./install.sh. Live animated wallpaper is an opt-in prompt.
set -euo pipefail

REPO_URL="https://github.com/xElectric9177/Osiris.git"

# --- output helpers
if [[ -t 1 ]]; then
  B=$'\033[1m'; GRN=$'\033[32m'; YLW=$'\033[33m'; RED=$'\033[31m'; RST=$'\033[0m'
else
  B=""; GRN=""; YLW=""; RED=""; RST=""
fi
step() { printf '%s\n' "${B}==>${RST} ${B}$*${RST}"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    %s%s%s\n' "$GRN" "$*" "$RST"; }
warn() { printf '    %s%s%s\n' "$YLW" "$*" "$RST"; }
die()  { printf '%s%s%s\n' "$RED" "$*" "$RST" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ask "prompt" default(y|n); auto-answers the default when stdin isn't a tty.
ask() {
  local prompt=$1 default=${2:-n} reply hint
  [[ $default == y ]] && hint="[Y/n]" || hint="[y/N]"
  if [[ ! -t 0 ]]; then
    [[ $default == y ]] && return 0 || return 1
  fi
  read -r -p "    ${prompt} ${hint} " reply || true
  reply=${reply:-$default}
  [[ $reply =~ ^[Yy] ]]
}

# --- locate payload, or self-clone when piped through curl | bash
SRC=""
self=${BASH_SOURCE[0]:-}
if [[ -n $self && -f $(dirname -- "$self")/.config/omarchy/themes/osiris/colors.toml ]]; then
  SRC=$(cd -- "$(dirname -- "$self")" && pwd)
else
  have git || die "git is required to fetch Osiris."
  SRC=$(mktemp -d)
  step "Fetching Osiris"
  git clone --depth 1 "$REPO_URL" "$SRC" >/dev/null 2>&1 || die "Could not clone $REPO_URL"
  trap 'rm -rf "$SRC"' EXIT
  ok "cloned to $SRC"
fi

# --- sanity checks
[[ $EUID -ne 0 ]] || die "Run this as your normal user, not root."
have omarchy || [[ -d $HOME/.config/omarchy ]] || \
  die "This doesn't look like an Omarchy system — see https://omarchy.org/."

CFG="$HOME/.config"
LOCALBIN="$HOME/.local/bin"

echo
step "Installing the Osiris theme"
mkdir -p "$CFG/omarchy/themes"
cp -r "$SRC/.config/omarchy/themes/osiris" "$CFG/omarchy/themes/"
ok "theme copied to ~/.config/omarchy/themes/osiris"
echo

# --- optional: live animated wallpaper (needs mpvpaper)
if ask "Enable the live animated wallpaper? (needs mpvpaper; otherwise a static still is used)" n; then
  if ! have mpvpaper; then
    helper=""
    for h in yay paru; do have "$h" && { helper=$h; break; }; done
    if [[ -n $helper ]] && ask "mpvpaper isn't installed — install it now with $helper?" y; then
      "$helper" -S --needed mpvpaper || warn "mpvpaper install failed; using the static still."
    else
      warn "Without mpvpaper the wallpaper stays the static still. Install mpvpaper (AUR), then re-run."
    fi
  fi
  if have mpvpaper; then
    mkdir -p "$LOCALBIN" \
             "$CFG/omarchy/hooks/theme-set.d" \
             "$CFG/omarchy/hooks/post-boot.d"
    cp "$SRC/.local/bin/osiris-live-wallpaper" "$LOCALBIN/"
    cp "$SRC/.config/omarchy/hooks/theme-set.d/osiris-live-wallpaper-hook.sh" "$CFG/omarchy/hooks/theme-set.d/"
    cp "$SRC/.config/omarchy/hooks/post-boot.d/osiris-live-wallpaper.sh"      "$CFG/omarchy/hooks/post-boot.d/"
    chmod +x "$LOCALBIN/osiris-live-wallpaper" \
             "$CFG/omarchy/hooks/theme-set.d/osiris-live-wallpaper-hook.sh" \
             "$CFG/omarchy/hooks/post-boot.d/osiris-live-wallpaper.sh"
    ok "live wallpaper script + hooks installed"
  fi
  echo
fi

# --- apply the theme
step "Applying theme"
if have omarchy; then
  omarchy theme set osiris && ok "theme set to osiris"
else
  warn "'omarchy' not found — set it yourself with: omarchy theme set osiris"
fi
echo

step "Done."
info "Theme only. For the full desktop run ./install.sh"
