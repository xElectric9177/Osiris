#!/usr/bin/env bash
# Osiris — one-command installer for Omarchy.
#
#   git clone https://github.com/xElectric9177/Osiris && ~/Osiris/install.sh
#   curl -fsSL https://raw.githubusercontent.com/xElectric9177/Osiris/main/install.sh | bash
#
# Installs the full Osiris desktop (theme, bar, plugins, hooks, scripts, editor
# links) automatically, then interactively offers the pieces that need sudo or
# touch other apps: the boot animation, the popup animation, and the Spotify and
# Discord themes. Safe to re-run — it overwrites Osiris's own files and backs up
# the two files most likely to hold your own edits (shell.json, looknfeel.lua).
#
# The README is the prose source of truth for what each step does and why; this
# script is the executable form of its Install section. Keep them in sync.
set -euo pipefail

REPO_URL="https://github.com/xElectric9177/Osiris.git"

# ---------------------------------------------------------------- output helpers
if [[ -t 1 ]]; then
  B=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'; YLW=$'\033[33m'; RED=$'\033[31m'; RST=$'\033[0m'
else
  B=""; DIM=""; GRN=""; YLW=""; RED=""; RST=""
fi
step() { printf '%s\n' "${B}==>${RST} ${B}$*${RST}"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    %s%s%s\n' "$GRN" "$*" "$RST"; }
warn() { printf '    %s%s%s\n' "$YLW" "$*" "$RST"; }
die()  { printf '%s%s%s\n' "$RED" "$*" "$RST" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ask "prompt" default(y|n) -> returns 0 for yes. Auto-answers with the default
# when stdin isn't a terminal (e.g. curl | bash with no tty).
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

# ------------------------------------------------------- locate payload / self-clone
# When run from a checkout, the payload sits next to this script. When piped
# through `curl | bash` there is no checkout, so clone one and use that.
SRC=""
self=${BASH_SOURCE[0]:-}
if [[ -n $self && -f $(dirname -- "$self")/.config/omarchy/shell.json ]]; then
  SRC=$(cd -- "$(dirname -- "$self")" && pwd)
else
  have git || die "git is required to fetch Osiris. Install git, or clone the repo and run ./install.sh."
  SRC=$(mktemp -d)
  step "Fetching Osiris"
  git clone --depth 1 "$REPO_URL" "$SRC" >/dev/null 2>&1 || die "Could not clone $REPO_URL"
  trap 'rm -rf "$SRC"' EXIT
  ok "cloned to $SRC"
fi

# ------------------------------------------------------------------ sanity checks
[[ $EUID -ne 0 ]] || die "Run this as your normal user, not root. It asks for sudo only when needed."
have omarchy || [[ -d $HOME/.config/omarchy ]] || \
  die "This doesn't look like an Omarchy system (no 'omarchy' command and no ~/.config/omarchy). Osiris targets Omarchy — see https://omarchy.org/."

CFG="$HOME/.config"
LOCALBIN="$HOME/.local/bin"

# copy SRC-relative path -> dest, creating the dest dir.
cp_into() { # cp_into <relative-src> <dest-dir>
  mkdir -p "$2"
  cp -r "$SRC/$1" "$2/"
}
# copy a file we expect the user might have edited, backing up the original once.
cp_backup() { # cp_backup <relative-src> <dest-file>
  local dest=$2
  if [[ -e $dest && ! -L $dest && ! -e $dest.pre-osiris ]]; then
    cp -p "$dest" "$dest.pre-osiris"
    info "backed up existing $(basename "$dest") → $(basename "$dest").pre-osiris"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$SRC/$1" "$dest"
}

echo
step "Installing Osiris from $SRC"
echo

# ------------------------------------------------------------------- dependencies
step "Checking dependencies"
pac_missing=(); aur_missing=()
have cava     || pac_missing+=(cava)
have mpvpaper || aur_missing+=(mpvpaper)

if ((${#pac_missing[@]})); then
  warn "missing (official repos): ${pac_missing[*]}"
  if ask "Install them now with pacman?" y; then
    sudo pacman -S --needed "${pac_missing[@]}"
  else
    info "Skipping — cava powers the media-pill spectrum; without it that popup shows idle dots."
  fi
else
  ok "cava present"
fi

if ((${#aur_missing[@]})); then
  warn "missing (AUR): ${aur_missing[*]}"
  helper=""
  for h in yay paru; do have "$h" && { helper=$h; break; }; done
  if [[ -n $helper ]]; then
    if ask "Install them now with $helper?" y; then
      "$helper" -S --needed "${aur_missing[@]}"
    else
      info "Skipping — without mpvpaper the wallpaper falls back to the static still."
    fi
  else
    warn "No AUR helper (yay/paru) found. Install manually: ${aur_missing[*]}"
    info "Without mpvpaper the wallpaper falls back to the static still image."
  fi
else
  ok "mpvpaper present"
fi
echo

# --------------------------------------------------------------------- core: theme
step "Theme, bar, plugins"
cp_into ".config/omarchy/themes/osiris" "$CFG/omarchy/themes"
for p in bar media lock menu cpu gpu memory notifications; do
  cp_into ".config/omarchy/plugins/amendale.$p" "$CFG/omarchy/plugins"
done
ok "theme + 8 plugins"

# ------------------------------------------------------------------- core: hooks
cp_into ".config/omarchy/hooks/theme-set.d/osiris-live-wallpaper-hook.sh" "$CFG/omarchy/hooks/theme-set.d"
cp_into ".config/omarchy/hooks/theme-set.d/osiris-about-logo.sh"          "$CFG/omarchy/hooks/theme-set.d"
cp_into ".config/omarchy/hooks/post-boot.d/osiris-live-wallpaper.sh"      "$CFG/omarchy/hooks/post-boot.d"

# --------------------------------------------------------- core: templates + config
cp_into ".config/omarchy/themed/fastfetch.jsonc.tpl" "$CFG/omarchy/themed"
cp_into ".config/omarchy/themed/lazygit.yml.tpl"     "$CFG/omarchy/themed"
cp_backup ".config/omarchy/shell.json" "$CFG/omarchy/shell.json"
cp_backup ".config/hypr/looknfeel.lua" "$CFG/hypr/looknfeel.lua"
mkdir -p "$CFG/cava" && cp "$SRC/.config/cava/config.osiris" "$CFG/cava/"

# --------------------------------------------------------------- core: branding art
cp_into ".config/omarchy/branding/osiris-eye.txt"   "$CFG/omarchy/branding"
cp_into ".config/omarchy/branding/screensaver.txt"  "$CFG/omarchy/branding"

# ------------------------------------------------------------------ core: user bin
mkdir -p "$LOCALBIN"
cp "$SRC/.local/bin/omarchy-screensaver" \
   "$SRC/.local/bin/osiris-live-wallpaper" \
   "$SRC/.local/bin/osiris-eye-logo" "$LOCALBIN/"
chmod +x "$LOCALBIN/omarchy-screensaver" "$LOCALBIN/osiris-live-wallpaper" "$LOCALBIN/osiris-eye-logo" \
         "$CFG/omarchy/hooks/theme-set.d/osiris-live-wallpaper-hook.sh" \
         "$CFG/omarchy/hooks/theme-set.d/osiris-about-logo.sh" \
         "$CFG/omarchy/hooks/post-boot.d/osiris-live-wallpaper.sh"
ok "scripts + branding"

# ------------------------------------------------------------------ core: PATH order
# ~/.local/bin must precede $OMARCHY_PATH/bin so the retinted omarchy-screensaver
# wins. It goes in .bash_profile (not .bashrc) — Hyprland's exec dispatcher spawns
# login-but-non-interactive shells that skip .bashrc but still run .bash_profile.
profile="$HOME/.bash_profile"
line='export PATH="$HOME/.local/bin:$PATH"'
if [[ ! -f $profile ]] || ! grep -qxF "$line" "$profile"; then
  printf '%s\n' "$line" >> "$profile"
  ok "added ~/.local/bin to PATH in .bash_profile"
else
  ok "PATH already set in .bash_profile"
fi

# ----------------------------------------------------------- core: editor theme links
# fastfetch/lazygit/neovim read the current theme through symlinks into Omarchy's
# rendered theme output (same wiring as btop). Neovim's target is *relative* — the
# exact spelling Omarchy's own migrations match on, so future migrations maintain it.
step "Editor theme links"
mkdir -p "$CFG/fastfetch" "$CFG/lazygit" "$CFG/nvim/lua/plugins"
ln -sf  "$HOME/.local/state/omarchy/current/theme/fastfetch.jsonc" "$CFG/fastfetch/config.jsonc"
ln -sf  "$HOME/.local/state/omarchy/current/theme/lazygit.yml"     "$CFG/lazygit/config.yml"
ln -sfn "../../../../.local/state/omarchy/current/theme/neovim.lua" "$CFG/nvim/lua/plugins/theme.lua"
if cp /etc/skel/.config/nvim/lua/plugins/omarchy-theme-hotreload.lua \
      /etc/skel/.config/nvim/lua/plugins/all-themes.lua \
      "$CFG/nvim/lua/plugins/" 2>/dev/null; then
  ok "fastfetch, lazygit, neovim linked (+ neovim glue from /etc/skel)"
else
  ok "fastfetch, lazygit, neovim linked"
  warn "Omarchy's neovim glue files weren't in /etc/skel — theme hot-reload/all-themes skipped."
fi
echo

# --------------------------------------------------------------- core: apply the theme
step "Applying theme"
if have omarchy-shell; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || warn "plugin rescan failed (shell may not be running yet)"
fi
have omarchy && omarchy restart shell >/dev/null 2>&1 || true
if have omarchy; then
  omarchy theme set osiris && ok "theme set to osiris"
else
  warn "'omarchy' command not found — set the theme yourself with: omarchy theme set osiris"
fi
echo

# =================================================================== optional pieces
step "Optional extras"

# --- boot animation (Plymouth, needs sudo, rebuilds initramfs) -----------------
if ask "Install the OSIRIS boot animation? (needs sudo, rebuilds the initramfs)" n; then
  cp "$SRC/.local/bin/osiris-plymouth-glitch" "$LOCALBIN/"
  cp_into ".config/omarchy/hooks/post-update.d/osiris-plymouth-glitch.sh" "$CFG/omarchy/hooks/post-update.d"
  chmod +x "$LOCALBIN/osiris-plymouth-glitch" "$CFG/omarchy/hooks/post-update.d/osiris-plymouth-glitch.sh"
  info "Rendering + installing the Plymouth theme (this will prompt for sudo)…"
  if "$LOCALBIN/osiris-plymouth-glitch"; then
    ok "boot animation installed — reboot to see it"
  else
    warn "generator exited non-zero; rollback: sudo plymouth-set-default-theme omarchy && sudo limine-mkinitcpio"
  fi
  echo
fi

# --- popup animation (patches the packaged omarchy tree, needs sudo) -----------
if ask "Install the popup slide-out animation? (needs sudo, patches Omarchy's shell)" n; then
  cp "$SRC/.local/bin/osiris-popup-animation" "$LOCALBIN/"
  cp_into ".config/omarchy/hooks/post-update.d/osiris-popup-animation.sh" "$CFG/omarchy/hooks/post-update.d"
  chmod +x "$LOCALBIN/osiris-popup-animation" "$CFG/omarchy/hooks/post-update.d/osiris-popup-animation.sh"
  if "$LOCALBIN/osiris-popup-animation" apply; then
    ok "popup animation applied"
  else
    warn "patcher aborted (upstream may have moved) — nothing changed. 'osiris-popup-animation revert' to undo."
  fi
  echo
fi

# --- Spotify theme (spicetify) -------------------------------------------------
if ask "Apply the Spotify (spicetify) theme?" n; then
  if have spicetify; then
    mkdir -p "$CFG/spicetify/Themes/Osiris"
    cp "$SRC/.config/spicetify/Themes/Osiris/color.ini" "$CFG/spicetify/Themes/Osiris/"
    spicetify config current_theme Osiris color_scheme Osiris
    spicetify apply || warn "spicetify apply failed — is Spotify installed and set up?"
    ok "Spotify theme applied (restart Spotify to see it)"
  else
    warn "spicetify not found — install spicetify-cli (AUR), then re-run and choose this again."
  fi
  echo
fi

# --- Discord theme (Vesktop/Vencord) -------------------------------------------
if ask "Install the Discord (Vesktop/Vencord) themes?" n; then
  dest="$CFG/vesktop/themes"
  [[ -d $HOME/.config/Vencord/themes && ! -d $HOME/.config/vesktop ]] && dest="$HOME/.config/Vencord/themes"
  mkdir -p "$dest"
  cp "$SRC/.config/vesktop/themes/Osiris.theme.css" "$dest/"
  cp "$SRC/.config/vesktop/themes/Osiris-DarkPlus.theme.css" "$dest/"
  ok "Discord themes copied to $dest"
  info "Enable one in Discord → Settings → Themes."
  echo
fi

# ============================================================================ done
step "Done."
info "Osiris is installed. A couple of things worth knowing:"
info "  • If the screensaver looks un-themed, open a new shell so .bash_profile's PATH takes effect."
info "  • Confirm the live wallpaper with:  hyprctl layers | grep -A2 mpvpaper"
info "  • Full details and rollback steps are in the README."
