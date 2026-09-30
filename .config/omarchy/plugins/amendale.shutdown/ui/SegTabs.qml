import QtQuick

// Segmented control used for the Countdown | Specific Time mode switch.
Rectangle {
  id: root

  property var theme
  property var options: []          // array of strings
  property int currentIndex: 0

  signal selected(int index)

  implicitHeight: 38
  radius: theme.radiusSmall
  color: theme.alpha(theme.text, 0.05)
  border.width: 1
  border.color: theme.border

  // Sliding highlight.
  Rectangle {
    visible: root.options.length > 0
    width: root.options.length > 0 ? (root.width - 6) / root.options.length : 0
    height: root.height - 6
    y: 3
    x: 3 + root.currentIndex * width
    radius: root.theme.radiusSmall - 2
    color: root.theme.alpha(root.theme.accent, 0.22)
    border.width: 1
    border.color: root.theme.alpha(root.theme.accent, 0.6)
    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  }

  Row {
    anchors.fill: parent
    anchors.margins: 3
    Repeater {
      model: root.options
      Item {
        required property int index
        required property var modelData
        width: root.options.length > 0 ? (root.width - 6) / root.options.length : 0
        height: parent.height

        Text {
          anchors.centerIn: parent
          text: modelData
          font.family: root.theme.fontFamily
          font.pixelSize: 12
          font.bold: index === root.currentIndex
          color: index === root.currentIndex ? root.theme.text : root.theme.textMuted
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.currentIndex = index; root.selected(index) }
        }
      }
    }
  }
}
