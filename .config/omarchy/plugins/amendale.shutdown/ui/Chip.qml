import QtQuick

// A small pill: quick-preset chips and the Today/Tomorrow day selector.
Rectangle {
  id: root

  property var theme
  property string text: ""
  property bool active: false

  signal clicked()

  implicitHeight: 28
  implicitWidth: label.implicitWidth + 24
  radius: height / 2
  color: active ? theme.alpha(theme.accent, 0.22)
    : (ma.containsMouse ? theme.alpha(theme.text, 0.08) : theme.alpha(theme.text, 0.04))
  border.width: 1
  border.color: active ? theme.alpha(theme.accent, 0.7) : theme.border

  Behavior on color { ColorAnimation { duration: 100 } }

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text
    font.family: root.theme.fontFamily
    font.pixelSize: 11
    font.bold: root.active
    color: root.active ? root.theme.text : root.theme.textMuted
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
