import QtQuick
import qs.Commons

// Omarchy adapter for the ui/ Theme contract. Exposes the same fields the
// shared components read, but bound to the live Omarchy palette (qs.Commons
// Color/Style) so the widget tracks the user's theme, including live switches.
QtObject {
  id: theme

  // The host bar, for the resolved font family. Set by BarWidget.
  property var bar: null

  property color background: Color.popups.background
  property color surface:    Util.alpha(Color.foreground, 0.05)
  property color surfaceAlt:  Util.alpha(Color.foreground, 0.08)
  property color elevated:    Util.alpha(Color.foreground, 0.11)
  property color border:     Color.popups.border

  property color text:      Color.popups.text
  property color textMuted: Util.alpha(Color.popups.text, 0.6)
  property color textFaint: Util.alpha(Color.popups.text, 0.4)

  property color accent:  Color.accent
  property color accent2: Color.accent
  property color accent3: Color.accent
  property color urgent:  Color.urgent
  property color success: Color.accent

  property color accentInk: Color.popups.background
  property color ringTrack: Util.alpha(Color.foreground, 0.14)

  property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property int radius: Math.max(6, Style.cornerRadius)
  property int radiusSmall: Math.max(4, Style.cornerRadius)

  // Flat in whatever theme is active — no neon glow.
  property bool glow: false

  function alpha(c, a) { return Util.alpha(c, a) }
  function lift(c, amount) { return Qt.lighter(c, 1.0 + amount) }
}
