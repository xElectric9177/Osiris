import QtQuick

// One button for the whole app. `variant` picks the palette:
//   primary  - filled magenta CTA (with optional neon glow)
//   danger   - filled red (abort)
//   outline  - bordered, transparent fill
//   ghost    - no border, subtle hover fill
Rectangle {
  id: root

  property var theme
  property string text: ""
  property string glyph: ""
  property string variant: "primary"
  property bool enabled: true
  property real fontSize: 13

  signal clicked()

  readonly property bool filled: variant === "primary" || variant === "danger"
  readonly property color baseColor: variant === "danger" ? theme.urgent
    : variant === "primary" ? theme.accent : theme.text

  implicitHeight: 40
  implicitWidth: Math.max(96, label.implicitWidth + 40)
  radius: theme.radiusSmall
  opacity: enabled ? 1.0 : 0.4

  color: {
    if (!enabled) return filled ? theme.alpha(baseColor, 0.5) : "transparent"
    if (variant === "primary") return ma.containsMouse ? theme.lift(theme.accent, 0.12) : theme.accent
    if (variant === "danger") return ma.containsMouse ? theme.lift(theme.urgent, 0.12) : theme.urgent
    if (variant === "outline") return ma.containsMouse ? theme.alpha(theme.text, 0.06) : "transparent"
    return ma.containsMouse ? theme.alpha(theme.text, 0.08) : "transparent"
  }

  border.width: variant === "outline" ? 1 : 0
  border.color: theme.alpha(theme.border, 1.0)

  Behavior on color { ColorAnimation { duration: 120 } }

  // Neon glow for the primary CTA.
  layer.enabled: theme.glow && variant === "primary" && enabled
  Rectangle {
    visible: theme.glow && variant === "primary" && enabled
    anchors.fill: parent
    anchors.margins: -2
    radius: parent.radius + 2
    color: "transparent"
    border.width: 2
    border.color: theme.alpha(theme.accent, ma.containsMouse ? 0.55 : 0.32)
    z: -1
  }

  Row {
    id: label
    anchors.centerIn: parent
    spacing: 8

    Text {
      visible: root.glyph !== ""
      text: root.glyph
      anchors.verticalCenter: parent.verticalCenter
      font.family: root.theme.fontFamily
      font.pixelSize: root.fontSize + 2
      color: root.filled ? root.theme.accentInk : root.baseColor
    }
    Text {
      visible: root.text !== ""
      text: root.text
      anchors.verticalCenter: parent.verticalCenter
      font.family: root.theme.fontFamily
      font.pixelSize: root.fontSize
      font.bold: true
      color: root.filled ? root.theme.accentInk : root.baseColor
    }
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
  }
}
