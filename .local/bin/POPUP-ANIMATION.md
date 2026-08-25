# Popup slide animation

Every bar popup — volume, bluetooth, network, monitor, power, weather, clock,
agents, tailscale, dropbox, tray, media pill — springs out of the bar instead
of fading in place. The launcher menu does the same, but through a different
route (see below).

## Why this one is a patch

Omarchy's popups all funnel through two shared components:

```
Panel (lifecycle) ──> KeyboardPanel ──> volume, bluetooth, network, monitor,
                                        power, weather, clock, agents,
                                        tailscale, dropbox
                      PopupCard     ──> tray, media pill
```

That's the whole reason this is tractable: two files control a dozen popups.
The problem is both live in `/usr/share/omarchy/shell/Ui/`, which is
root-owned and replaced wholesale by `omarchy update`.

The usual rule is *never* edit `/usr/share/omarchy` — because naive edits get
silently reverted on the next update. There were two ways around that:

1. **Clone the ~10 panel plugins into user space.** Fully supported, but the
   panels get `KeyboardPanel` from `qs.Ui`, so cloning a plugin doesn't let
   you change it — the 418-line `KeyboardPanel` (with its subtle layer-shell
   focus-priming logic) would have to be forked too, and all ten plugins would
   freeze at today's version and stop receiving upstream fixes.

2. **Patch the two shared files and re-apply after every update.** What this
   does.

Option 2 keeps *closer* to upstream, not further from it. Each `omarchy
update` lands the new upstream files and the hook re-patches those, so the
animation rides along with upstream fixes rather than pinning a dozen plugins
to a snapshot. The cost is that an upstream refactor could move the code the
patch targets — handled below.

## How it survives updates

`~/.config/omarchy/hooks/post-update.d/osiris-popup-animation.sh` runs after
every `omarchy update` and calls the patcher, which needs root (it re-execs
itself under `sudo`; `omarchy update` runs from a terminal, so the prompt has
somewhere to go).

Every replacement is anchored to an exact snippet and must match **exactly
once**. If upstream refactors these files, the patcher aborts with a message
naming the anchor that failed and touches nothing — so the failure mode is
"popups fade instead of sliding, with a clear error", never a half-patched
shell. Fixing it means updating the anchor in the script.

```bash
osiris-popup-animation check     # patched / stock, no root needed
osiris-popup-animation apply     # patch (idempotent)
osiris-popup-animation revert    # restore from backup
```

`apply` is safe to re-run after changing the timings at the top of the script.
A patched file can't be re-patched in place (its anchors are gone), so `apply`
first recovers the pristine original from the backup, then patches that fresh
— and refuses, changing nothing, if the only backup it can find is itself
patched. Re-running with no changes is a no-op and skips the shell restart.

`apply` and `revert` need root and re-exec themselves to get it: `sudo` when
there's a terminal to prompt into, `pkexec` when there isn't (Omarchy's polkit
agent then raises a graphical prompt). That fallback matters — running this
from a non-interactive context, such as Claude Code's `!` prefix, gives sudo
nowhere to ask and it fails with *"a terminal is required to read the
password"*.

Originals are backed up to `~/.local/state/osiris/popup-animation-backup/`
before the first patch. `omarchy update` also restores stock files by itself,
so a broken patch is never more than an update away from clean.

That path is resolved against the *invoking* user's home, not `~` — once the
script has re-exec'd under sudo/pkexec, `os.path.expanduser("~")` gives root's
home, which would stash the originals somewhere the user who asked for the
patch can't read. The backup tree is `chown`ed back to that user afterwards,
since it was written as root. `revert` also checks the old root-owned location,
so a backup taken before this was fixed is still usable.

## The motion

12px travel, 600ms, `OutBack` with 1.35 overshoot on open; 400ms `InCubic` on
close. The card sits pulled toward the bar while hidden and springs away from
it, overshooting slightly before settling.

Distance is `Style.space(12)`, so it scales with the font/spacing scale rather
than being a fixed pixel count.

A few details that aren't obvious:

- **The close duration and the opacity fade are locked together.** Both
  components unmap the surface the moment opacity hits 0 (`visible: open ||
  card.opacity > 0`), so a retraction longer than the fade gets truncated
  mid-flight. The patch therefore rewrites the stock 140ms fade to match
  `CLOSE_MS` rather than leaving it alone — if you retune the close, move
  `FADE_MS` with it. Open has no such ceiling and can take as long as it likes.
- **Close is deliberately quicker than open.** Dismissing a popup shouldn't
  make you wait for it.
- **Direction follows the bar edge** (`slideEdge`), so a left/right/bottom bar
  slides on the correct axis instead of always dropping downward.
- **The slide is suppressed during a popout switch**, matching the stock
  opacity `Behavior`'s `enabled` guard. Clicking straight from the volume icon
  to the bluetooth icon should hand off instantly, not animate through an
  intermediate position.

### The two files need different techniques

`KeyboardPanel` is a **full-screen layer-shell surface** with the card
free-floating inside at `cardOrigin`, so the card can simply be translated —
nothing to clip against.

`PopupCard` is a real **xdg-popup sized to its content**, so translating the
card inside it would clip at the surface edge. Instead the window is padded by
`slideDistance` on the slide axis and the anchor rect is shifted back by the
same amount, which leaves the card's resting position on screen byte-identical
to stock while giving the motion room to travel. The anchoring math also had
to switch from measuring `implicitWidth/Height` (now padded) to
`contentWidth/Height` (the card), or every popup would drift by the pad.

Overshoot headroom is safe by construction: the card overshoots by
`0.35 × slideDistance` into far-side padding of a full `slideDistance`.

## The menu is not part of this

`amendale.menu` is already a user-space clone, so it got the same motion
directly in its own `Menu.qml` — no patching involved. It's driven off
`panel.visible` rather than `root.opened`, because `opened` flips before
`rowsLoaded` and animating on it would burn part of the travel while the
window is still unmapped. Closing hides the window outright, so only the open
direction is ever seen and no retraction easing is needed.
