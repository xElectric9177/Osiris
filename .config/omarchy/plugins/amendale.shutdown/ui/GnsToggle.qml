import QtQuick

// A labelled toggle row: title + subtitle on the left, switch on the right.
Item {
  id: root

  property var theme
  property string title: ""
  property string subtitle: ""
  property bool checked: false
  property bool enabled: true

  signal toggled(bool value)

  implicitHeight: Math.max(36, col.implicitHeight)
  implicitWidth: 260
  opacity: enabled ? 1.0 : 0.4

  Column {
    id: col
    anchors.left: parent.left
    anchors.right: sw.left
    anchors.rightMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Text {
      text: root.title
      width: parent.width
      elide: Text.ElideRight
      font.family: root.theme.fontFamily
      font.pixelSize: 12
      color: root.theme.text
    }
    Text {
      visible: root.subtitle !== ""
      text: root.subtitle
      width: parent.width
      elide: Text.ElideRight
      wrapMode: Text.NoWrap
      font.family: root.theme.fontFamily
      font.pixelSize: 10
      color: root.theme.textFaint
    }
  }

  Rectangle {
    id: sw
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: 40
    height: 22
    radius: height / 2
    color: root.checked ? root.theme.accent : root.theme.alpha(root.theme.text, 0.12)
    border.width: root.checked ? 0 : 1
    border.color: root.theme.border

    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
      width: 16
      height: 16
      radius: 8
      y: (parent.height - height) / 2
      x: root.checked ? parent.width - width - 3 : 3
      color: root.checked ? root.theme.accentInk : root.theme.text
      Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.checked = !root.checked
      root.toggled(root.checked)
    }
  }
}
