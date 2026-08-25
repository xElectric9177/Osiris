# amendale.lock — Osiris lock screen

Clone of the built-in `omarchy.lock` service. This system doesn't actually use
`hyprlock` — `omarchy-system-lock` calls `omarchy-shell lock lock`, Omarchy's
own Quickshell lock screen (`LockView.qml`, driven by `Service.qml`'s PAM
flow). The traditional `~/.config/hypr/hyprlock.conf` is vestigial here, same
as `hypridle.conf` (see `amendale.bar`'s README for that pattern) — editing it
does nothing.

The stock lock screen was already fully theme-reactive (`Color.lock.*`,
`Style.cornerRadius`, background from the current theme's background symlink)
with zero changes needed for the wallpaper. What it didn't have: a clock or a
username.

## What's different from stock `omarchy.lock`

- **`import Quickshell`** added to `LockView.qml` for `Quickshell.env("USER")`.
- **Clock + username**, added as a `Column` anchored above the password field
  (`anchors.bottom: inputField.top`): large bold time, smaller dimmed date
  below it, then the username (`Quickshell.env("USER") || Quickshell.env("LOGNAME")`)
  above the input field itself. A 1-second `Timer` re-renders the clock text.
  Uses the same `Color.lock.text` / `Color.lock.placeholder` tokens the stock
  input field already used, so it stays theme-reactive for any future Omarchy
  theme, not just Osiris.

## Testing safely

`amendale.lock`'s `Service.qml` exposes a Quickshell IPC target (`target:
"lock"`) with `preview` / `hidePreview` functions — these show/hide the exact
same `LockView` full-screen (`inputEnabled: false`, no PAM involved) without
actually locking the session:

```bash
omarchy-shell lock preview      # show it
omarchy-shell lock hidePreview  # dismiss it
```

Use this instead of a real `omarchy-system-lock` when testing changes here —
a real lock needs the actual account password to dismiss, so a mistake in a
change is much lower-stakes to catch through the preview first.

Note the preview only maps on whichever monitor Quickshell picks (in testing,
consistently the last enumerated one, not necessarily monitor 0) — check
`hyprctl layers | grep lock-preview` for the `xywh` position if it doesn't
appear where expected.

## Setup

```
omarchy plugin clone omarchy.lock   # creates ~/.config/omarchy/plugins/<user>.lock/
```

then overwrite the clone's `LockView.qml` with this one. The clone process
adds `{"id": "<user>.lock"}` to `shell.json`'s `plugins` array and disables
the original automatically — no manual shell.json editing needed here (unlike
`amendale.bar`, since lock is a `service`-kind plugin rather than a
swappable-by-id `bar` one).
