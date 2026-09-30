import QtQuick

// Theme contract consumed by every ui/ component. Components are theme-agnostic
// and read colors/fonts from a `theme` object shaped like this one — they never
// reference a color singleton directly, so the same components render in the
// standalone app (this Midnight Neon Lo-Fi palette) and in the Omarchy plugin
// (OmarchyTheme, which binds the same fields to the live Omarchy theme).
//
// This file *is* the standalone Midnight Neon Lo-Fi theme. Palette approximated
// from the Google Stitch board; tune freely.
QtObject {
  id: theme

  // Surfaces (near-black navy -> raised cards).
  property color background: "#0D0B1A"
  property color surface:    "#181528"
  property color surfaceAlt: "#211C36"
  property color elevated:   "#2A2442"
  property color border:     "#332C4D"

  // Text.
  property color text:      "#EDEAF5"
  property color textMuted: "#9A93B4"
  property color textFaint: "#6E6788"

  // Neon accents: magenta primary, violet secondary, cyan tertiary.
  property color accent:  "#E24BF2"
  property color accent2: "#A855F7"
  property color accent3: "#22E3D0"
  property color urgent:  "#FF4D6D"
  property color success: "#3DE08A"

  // Text drawn on top of an accent fill.
  property color accentInk: "#140F22"

  // Countdown-ring unfilled track.
  property color ringTrack: "#2A2442"

  property string fontFamily: "monospace"

  property int radius: 14
  property int radiusSmall: 9

  // Soft neon glow around the primary CTA and the ring. Off in the Omarchy
  // adapter, where the widget should sit flat in whatever theme is active.
  property bool glow: true

  function alpha(c, a) {
    var col = (typeof c === "string") ? Qt.color(c) : c
    return Qt.rgba(col.r, col.g, col.b, a)
  }

  // Slightly lighten/darken for hover/pressed states.
  function lift(c, amount) {
    return Qt.lighter(c, 1.0 + amount)
  }
}
