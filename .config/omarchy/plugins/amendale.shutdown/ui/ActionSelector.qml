import QtQuick

// 2x2 grid of the four power actions. Emits the selected action id
// ("poweroff" | "reboot" | "suspend" | "hibernate").
Item {
  id: root

  property var theme
  property string action: "poweroff"
  property bool hibernateEnabled: true

  signal selected(string action)

  readonly property var items: [
    { id: "poweroff",  glyph: "⏻", label: "Power Off",  sub: "Full shutdown" },
    { id: "reboot",    glyph: "⟳", label: "Restart",    sub: "Reboot now" },
    { id: "suspend",   glyph: "☾", label: "Suspend",    sub: "Sleep to RAM" },
    { id: "hibernate", glyph: "❄", label: "Hibernate",  sub: "Save to disk" }
  ]

  implicitHeight: grid.implicitHeight
  implicitWidth: grid.implicitWidth

  Grid {
    id: grid
    columns: 2
    columnSpacing: 8
    rowSpacing: 8
    width: parent.width

    Repeater {
      model: root.items
      Rectangle {
        id: card
        required property var modelData
        readonly property bool isSelected: root.action === modelData.id
        readonly property bool disabled: modelData.id === "hibernate" && !root.hibernateEnabled

        width: (grid.width - grid.columnSpacing) / 2
        height: 58
        radius: root.theme.radiusSmall
        opacity: disabled ? 0.4 : 1.0
        color: isSelected ? root.theme.alpha(root.theme.accent, 0.16)
          : (cardMa.containsMouse ? root.theme.alpha(root.theme.text, 0.06) : root.theme.alpha(root.theme.text, 0.03))
        border.width: 1
        border.color: isSelected ? root.theme.alpha(root.theme.accent, 0.7) : root.theme.border

        Behavior on color { ColorAnimation { duration: 110 } }

        Row {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 10
          spacing: 10

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.glyph
            font.pixelSize: 22
            color: isSelected ? root.theme.accent : root.theme.textMuted
          }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
              text: modelData.label
              font.family: root.theme.fontFamily
              font.pixelSize: 12
              font.bold: true
              color: root.theme.text
            }
            Text {
              text: card.disabled ? "No swap" : modelData.sub
              font.family: root.theme.fontFamily
              font.pixelSize: 9
              color: root.theme.textFaint
            }
          }
        }

        MouseArea {
          id: cardMa
          anchors.fill: parent
          hoverEnabled: true
          enabled: !card.disabled
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.action = modelData.id; root.selected(modelData.id) }
        }
      }
    }
  }
}
