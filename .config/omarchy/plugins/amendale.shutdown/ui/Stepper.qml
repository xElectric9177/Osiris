import QtQuick

// A vertical number stepper: ▲ over a big 2-digit value over ▼, with a unit
// caption. Scroll to adjust; click the chevrons to step. Used by both the
// duration picker (HH/MM/SS) and the specific-time picker (HH/MM).
Rectangle {
  id: root

  property var theme
  property int value: 0
  property int minValue: 0
  property int maxValue: 59
  property int step: 1
  property bool wrap: true
  property string unit: ""

  signal changed(int value)

  implicitWidth: 76
  implicitHeight: 118
  radius: theme.radiusSmall
  color: theme.alpha(theme.text, 0.04)
  border.width: 1
  border.color: theme.border

  function _apply(v) {
    if (root.wrap) {
      var span = root.maxValue - root.minValue + 1
      v = ((v - root.minValue) % span + span) % span + root.minValue
    } else {
      v = Math.max(root.minValue, Math.min(root.maxValue, v))
    }
    if (v !== root.value) { root.value = v; root.changed(v) }
  }

  function inc() { _apply(root.value + root.step) }
  function dec() { _apply(root.value - root.step) }

  Column {
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "▲"
      font.pixelSize: 11
      color: upMa.containsMouse ? root.theme.accent : root.theme.textMuted
      MouseArea { id: upMa; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.inc() }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: (root.value < 10 ? "0" : "") + root.value
      font.family: root.theme.fontFamily
      font.pixelSize: 30
      font.bold: true
      color: root.theme.text
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "▼"
      font.pixelSize: 11
      color: downMa.containsMouse ? root.theme.accent : root.theme.textMuted
      MouseArea { id: downMa; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dec() }
    }

    Text {
      visible: root.unit !== ""
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.unit
      font.family: root.theme.fontFamily
      font.pixelSize: 9
      font.letterSpacing: 1
      color: root.theme.textFaint
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    onWheel: function (wheel) { if (wheel.angleDelta.y > 0) root.inc(); else root.dec() }
  }
}
