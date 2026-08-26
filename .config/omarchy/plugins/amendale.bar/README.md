# amendale.bar — Osiris floating-islands bar

Clone of the built-in `omarchy.bar` plugin, modified to render the left/center/right
widget groups as separate floating pills (transparent background, thin glowing
accent-colored outline, rounded/pill radius) with gaps between them and the screen
edges, instead of one continuous bar strip.

## What's different from stock `omarchy.bar`

- **`omarchyPath`, `barWidgetRegistry`, `barConfig`** (top of `Bar.qml`) are plain
  `property` instead of `required property`. The host's `pluginBarLoader` mounts a
  cloned "kind: bar" plugin via `Loader.source`, which constructs the root item
  *before* any property can be supplied — a `required property` there fails
  construction outright and the bar never mounts (confirmed via `hyprctl layers`
  showing no `omarchy-bar` surface, plus a `ReferenceError` in the host's own
  error-handling path). `shell.qml`'s `configureBar()` still sets these correctly
  from `onLoaded`, just after construction instead of during it. This looks like a
  genuine upstream bug in this Omarchy build, not something specific to this clone.
- **`horizontalBar` / `verticalBar`** (~line 1108): each of `LeftModules` /
  `CenterModules` / `RightModules` gets its own `BorderSurface` pill behind it —
  transparent fill, `Border.flat(accent @ 0.8 alpha)`, `radius: height/2`.
- **Center pill positioning**: fixed to wrap the actual before/after widget group
  edges (`centerAnchorModule.x - beforeList.width - padding`) instead of
  `anchors.centerIn: parent` — the anchored clock layout hangs the before/after
  lists off the clock's own edges, not the parent's midpoint, so when those two
  groups differ in width (e.g. 1 indicator icon vs. 3 tray/network/etc. widgets)
  centering on the parent clips whichever side is wider.
- **Right pill / tray sizing**: the tray widget (`omarchy.tray`) always reports its
  fully-expanded `implicitWidth` (reserves space for its drawer so nothing else
  jumps when it opens), even while collapsed. The right pill now subtracts the
  tray's own `drawerExtent - revealExtent` (both public, already-animated
  properties) so it hugs the actual collapsed width and only grows — smoothly,
  matching the tray's own 600ms reveal animation — when the drawer is genuinely
  expanded.
- **The media widget gets its own pill**: `root.entriesExcludingId()` /
  `root.entryOnlyId()` split the `"left"` region's entries so `amendale.media`
  (see its own plugin README — it's a clone too) renders as a separate
  `ModuleList` + `BorderSurface` positioned right after the main left pill
  (`leftPill.x + leftPill.width + islandGap`), instead of sharing one island
  with the menu/workspaces group. Both `ModuleList`s keep `region: "left"` so
  hotkeys/drag-and-drop still treat it as one logical region; only the *visual*
  grouping is split. Same pattern mirrored in `verticalBar` (`topGroup` /
  `topMediaGroup`, stacked on the y-axis instead). The filter id is hardcoded
  to whatever the media widget's *current* plugin id is — if it's ever
  re-cloned under a different name, this needs updating too.

- **Double-click transparency toggle removed** (`onDoubleClicked`, ~line 1667):
  stock toggles `bar.transparent` when you double-click empty bar space and
  persists it to `shell.json`. On a floating-islands bar, "empty bar space" is
  most of the bar's width, so a stray double-click turns the islands into an
  opaque slab — silently, with no undo and nothing on screen to explain what
  happened. This was the actual cause of the bar "randomly losing
  transparency"; the give-away was `shell.json` being mode 600, the signature
  of the shell's own `mktemp`-and-`mv` config writer rather than a hand edit.
  The handler now swallows the event, and `omarchy bar transparent
  <true|false|toggle>` still sets it deliberately. `toggleTransparency()` is
  left defined but uncalled, to keep this clone easy to diff against upstream.

## Setup

```
omarchy plugin clone omarchy.bar   # creates ~/.config/omarchy/plugins/<user>.bar/
```

then overwrite the clone's `Bar.qml` with this one and set `"bar": {"id": "<user>.bar"}`
in `~/.config/omarchy/shell.json`. `omarchy-shell shell rescanPlugins` hot-reloads
QML edits, but has left stale objects behind after larger structural changes in
testing — prefer a full `omarchy restart shell` after editing this file.
