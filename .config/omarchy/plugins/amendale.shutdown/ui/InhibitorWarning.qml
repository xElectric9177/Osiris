import QtQuick

// Warning card shown when one or more processes hold a sleep/shutdown inhibitor
// lock (e.g. a media player). `inhibitors` is the array from Scheduler.
Rectangle {
  id: root

  property var theme
  property var inhibitors: []
  property bool forceEnabled: false

  visible: inhibitors.length > 0
  implicitHeight: visible ? col.implicitHeight + 20 : 0
  radius: theme.radiusSmall
  color: theme.alpha(theme.urgent, 0.12)
  border.width: 1
  border.color: theme.alpha(theme.urgent, 0.5)

  Row {
    anchors.fill: parent
    anchors.margins: 10
    spacing: 10

    Text {
      text: "⚠"
      font.pixelSize: 18
      color: root.theme.urgent
      anchors.top: parent.top
    }

    Column {
      id: col
      width: parent.width - 28
      spacing: 3

      Text {
        text: root.inhibitors.length + " inhibitor lock" + (root.inhibitors.length === 1 ? "" : "s") + " active"
        font.family: root.theme.fontFamily
        font.pixelSize: 12
        font.bold: true
        color: root.theme.text
      }
      Repeater {
        model: root.inhibitors
        Text {
          required property var modelData
          width: col.width
          elide: Text.ElideRight
          text: "• " + (modelData.who || "process") + " — " + (modelData.what || "sleep")
          font.family: root.theme.fontFamily
          font.pixelSize: 10
          color: root.theme.textMuted
        }
      }
      Text {
        width: col.width
        wrapMode: Text.WordWrap
        text: root.forceEnabled
          ? "Force is on — the lock will be ignored."
          : "Enable Force to override, or the action may be blocked."
        font.family: root.theme.fontFamily
        font.pixelSize: 10
        color: root.theme.textFaint
      }
    }
  }
}
