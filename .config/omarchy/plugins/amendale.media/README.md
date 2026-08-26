# amendale.media — Osiris media player pill

Clone of the built-in `omarchy.media` widget (MPRIS now-playing), rendered as its
own floating pill (via `amendale.bar`'s pill-splitting) instead of sharing the
left island with the menu/workspaces, with a redesigned popup and a fixed
scrolling-title animation.

## What's different from stock `omarchy.media`

- **`moduleName` and the service lookup** (`bar?.shell?.firstPartyServiceFor(...)`)
  point at `amendale.media` instead of `omarchy.media`. Services are registered
  by their plugin manifest's own `id`, so a clone's service instance lives under
  the clone's id — the clone process copies the QML verbatim and doesn't rewrite
  these internal self-references, so left as `omarchy.media` the widget would
  silently find no service (the original is disabled) and never show anything.
- **Click mapping swapped**: left-click now opens the popup (was play/pause),
  right-click is the quick play/pause toggle (was popup). Middle-click (next)
  and scroll (prev/next) are unchanged.
- **Rounded album art**: plain `clip: true` on a `Rectangle` only clips to its
  bounding box, not its rounded shape, so genuinely rounding the art needed the
  same `MultiEffect` + mask-`Item` technique used elsewhere in the shell
  (`image-picker/ImagePicker.qml`) — a hidden `Item` with `layer.enabled: true`
  containing a plain rounded `Rectangle`, used as `maskSource` for a
  `layer.effect: MultiEffect { maskEnabled: true }` wrapping the `Image`.
- **Live cava audio-spectrum visualizer + elapsed/total time**, added below the
  art/title row (replaced an earlier flat progress-fill bar). A `cava` process
  (config: `~/.config/cava/config.osiris` — 24 bars, PipeWire input targeting
  `@DEFAULT_SINK@.monitor` explicitly, since "auto" picked up the *default
  source* — usually a microphone — rather than a monitor of what's actually
  playing, raw ASCII output) runs only while the popup is open and something's
  playing; each line of output is 24 semicolon-separated 0–100 values driving
  a row of animated bars. Needs a few seconds after each fresh start for
  cava's own `autosens` to calibrate — quiet/flat at first is normal, not a
  bug. Time labels use the same interpolated-position mechanism as before:
  MPRIS only pushes `position` updates on seeks or play/pause, not every
  second, so a local `trackPositionBase` + timestamp is interpolated between
  updates via a 500ms timer and resynced on
  `positionChanged`/`isPlayingChanged`.
- **Scrolling title fix**: `labelText.implicitWidth` is volatile — it takes a
  couple of layout passes to settle after font load, and changes again on every
  track change. The stock widget binds the scroll animation's `from`/`to`/
  `duration` live to it, so every settle-jump implicitly restarts the
  animation before it's visibly moved, and a long track changing to another
  long track leaves stale distances (since `needsScroll` never flips false in
  between to trigger a recompute). Fixed with a 150ms debounce on any
  text/width change that snapshots a stable scroll span, or resets `x` to 0 for
  a short title that doesn't need to scroll (previously: a short title after a
  long one could get stuck showing blank space instead of full static text).
- **Scroll ordering fix** (the debounce above wasn't enough): the animation was
  a `NumberAnimation on x` value source whose `running` was bound to
  `needsScroll` and whose `from`/`to` were bound to properties the debounce
  timer assigned. The timer set `needsScroll` on its *first* line, which flipped
  `running` true before `from`/`to` were assigned two lines later — so the
  animation captured the initial `0 -> 0` span and looped over zero distance.
  Changing `from`/`to` on a running animation does not restart it, and
  `needsScroll` then stayed true from one long track to the next, so `running`
  never went false -> true again and the real distances were never picked up.
  Net effect: the first long title never scrolled, and later ones reused stale
  spans. Now the animation is a plain `NumberAnimation` targeting
  `labelText.x`, stopped and restarted explicitly in `applyScroll()`, which has
  no ordering dependency. Confirmed in an isolated QML harness: the old shape
  leaves `x` at 0 indefinitely, the new one scrolls.
- **Whitespace collapse in the label**: MPRIS titles can carry embedded
  newlines (Brave reports `"LATIN MAFIA\n Fred again.. - Alvafro"`), which
  turns the label into a two-line `Text` inside a single-line-height clip — the
  second line is invisible and `implicitWidth` measures only the longest line,
  so the scroll span is wrong too. The label text now collapses whitespace runs
  to single spaces.

## Setup

```
omarchy plugin clone omarchy.media   # creates ~/.config/omarchy/plugins/<user>.media/
```

then overwrite the clone's `BarWidget.qml` with this one, add `{"id": "<user>.media"}`
to `shell.json`'s bar layout (the clone process does this automatically and
disables the original), and make sure `<user>.bar`'s pill-splitting filters on
the clone's id, not `omarchy.media` — see `amendale.bar`'s README.
