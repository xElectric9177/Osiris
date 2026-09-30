import QtQuick

// Monospace preview of the exact command that will be scheduled, with a copy
// affordance. The text is display-only; the real argv is run without a shell.
Rectangle {
  id: root

  property var theme
  property string command: ""

  signal copyRequested(string text)

  implicitHeight: Math.max(48, cmd.implicitHeight + 20)
  radius: theme.radiusSmall
  color: theme.background
  border.width: 1
  border.color: theme.border
  clip: true

  Text {
    id: cmd
    anchors.left: parent.left
    anchors.right: copyBtn.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 12
    anchors.rightMargin: 8
    text: root.command
    wrapMode: Text.WrapAnywhere
    maximumLineCount: 3
    elide: Text.ElideRight
    font.family: root.theme.fontFamily
    font.pixelSize: 11
    color: root.theme.accent3
  }

  Rectangle {
    id: copyBtn
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: 8
    width: 28; height: 28
    radius: 6
    color: copyMa.containsMouse ? root.theme.alpha(root.theme.text, 0.1) : "transparent"
    Text {
      anchors.centerIn: parent
      text: "⎘"       // copy-ish glyph
      font.pixelSize: 14
      color: root.theme.textMuted
    }
    MouseArea {
      id: copyMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.copyRequested(root.command)
    }
  }
}
