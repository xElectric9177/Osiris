# amendale.menu — Osiris launcher menu

Clone of the built-in `omarchy.menu`. Two changes: the card is anchored to the
bar's launcher island instead of floating centered, and its chrome is lit in
accent purple rather than neutral foreground.

## Placement

Stock centers the card on the screen, independent of where the launcher icon
actually is. Since `amendale.bar` puts that icon in the left island, the menu
opening in the middle of the screen reads as disconnected from the thing that
opened it. This clone drops it directly under the bar, sharing the left
island's left edge:

```qml
readonly property int barGap: Style.space(8)          // same gap the islands use
readonly property int barInset: barGap                 // card's left edge
readonly property int barDrop: Style.bar.sizeHorizontal + barGap
```

Both are derived, not hardcoded — `Style.bar.sizeHorizontal` tracks the real
bar height, and `barGap` matches `amendale.bar`'s own `islandGap`, so the card
stays aligned if either changes.

### This also deletes a workaround

Stock had an anti-jump mechanism: the card was vertically centered, so every
time the row count changed (a search keystroke, drilling into a submenu) the
card re-centered and appeared to jump. It worked around that by freezing
`cardTop` at its centered value on the first such change (`centeredTop` /
`effectiveCardTop` / `freezeCardTop()`).

A fixed top edge makes that impossible by construction — the card can only
grow downward — so `cardTop` is now a constant and the freeze logic is gone.
`maxRowsHeight` freezing is kept, since it does something different: it caps
how tall the card may grow so drilling into a longer submenu scrolls behind
the fold rather than expanding the card.

`availableRowsHeight()` and `cardWidth` were updated to measure from the new
top/left offsets instead of `Style.gapsOut` on both sides.

## Slide-in

The card slides down out of the bar on open (12px, 600ms, `OutBack` with 1.35
overshoot), matching the system popups — those get it via a patch to the
packaged shell, but this plugin is user-space so it just has it inline.

It's driven off `panel.visible`, not `root.opened`: `opened` flips before
`rowsLoaded`, so animating on it would burn part of the travel while the
window is still unmapped. Closing hides the window outright, so only the open
direction is ever seen and no retraction easing is needed.

See `.local/bin/POPUP-ANIMATION.md` for the system-popup side.

## Colors

The colors are *not* in this plugin — they're a theme-level override at
`themes/osiris/shell.menu.toml`, which Omarchy merges into the generated
`shell.toml` (any `shell.<section>.toml` in a theme directory replaces that
section wholesale). That's the right layer for it: it's theme data, it
survives re-cloning this plugin, and the clipboard and emoji pickers inherit
the same `[menu]` tokens for free.

Stock derives `border`, `selected-background`, and `selected-border` from
`hyprland.active-border-foreground` — i.e. the foreground grey — which looked
inert next to the accent-lit bar islands, popups, and notifications. The
override pulls all three to `#9b2ecd`, with `selected-text` switched to the
light foreground so it reads against the purple wash.

## Setup

```
omarchy plugin clone omarchy.menu   # creates ~/.config/omarchy/plugins/<user>.menu/
```

then overwrite the clone's `Menu.qml` and `BarWidget.qml` with these.

**The clone process does not rewrite the plugin's references to itself.** Both
needed fixing by hand after cloning, and both fail silently rather than
erroring:

- `BarWidget.qml`'s `moduleName: "omarchy.menu"` → `"amendale.menu"`
- `BarWidget.qml`'s toggle command, `omarchy-shell shell toggle omarchy.menu
  '{"menu":"root"}'` → `... amendale.menu ...`

This is the same trap `amendale.media` hit — see its README. Unlike the bar,
there's no `required property` construction-order bug here to work around.
