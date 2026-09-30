import QtQuick

// Circular T-minus progress ring with the HH:MM:SS clock in the centre.
// `progress` is 0..1 elapsed; the ring depletes clockwise as time runs down.
Item {
  id: root

  property var theme
  property real progress: 0          // 0 = just armed, 1 = due
  property string clockText: "00:00:00"
  property string caption: "T-MINUS"

  implicitWidth: 200
  implicitHeight: 200

  Canvas {
    id: canvas
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var cx = width / 2, cy = height / 2
      var lw = 12
      var r = Math.min(cx, cy) - lw
      var start = -Math.PI / 2
      var remaining = 1 - Math.max(0, Math.min(1, root.progress))

      // Track.
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, 2 * Math.PI)
      ctx.lineWidth = lw
      ctx.strokeStyle = root.theme.ringTrack
      ctx.stroke()

      // Remaining arc.
      ctx.beginPath()
      ctx.arc(cx, cy, r, start, start + remaining * 2 * Math.PI)
      ctx.lineWidth = lw
      ctx.lineCap = "round"
      ctx.strokeStyle = root.theme.accent
      ctx.stroke()
    }
  }

  // Repaint whenever inputs change (Canvas doesn't auto-track bindings). The
  // clock ticks `progress` every second, so this also picks up a late theme
  // color change within a second.
  onProgressChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()
  Component.onCompleted: canvas.requestPaint()

  // Soft outer glow.
  Rectangle {
    visible: root.theme.glow
    anchors.centerIn: parent
    width: parent.width - 8
    height: parent.height - 8
    radius: width / 2
    color: "transparent"
    border.width: 2
    border.color: root.theme.alpha(root.theme.accent, 0.25)
  }

  Column {
    anchors.centerIn: parent
    spacing: 4
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.caption
      font.family: root.theme.fontFamily
      font.pixelSize: 10
      font.letterSpacing: 3
      color: root.theme.textMuted
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.clockText
      font.family: root.theme.fontFamily
      font.pixelSize: 30
      font.bold: true
      color: root.theme.text
    }
  }
}
