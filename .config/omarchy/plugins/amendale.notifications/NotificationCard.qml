import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// One notification row. Presentational only; the parent owns the data and the
// clear action. Same BorderSurface base and Color.notifications.* tokens the
// stock toast card uses, so it reads as native — with the Osiris accent edge.
BorderSurface {
  id: card

  property string app: ""
  property string summary: ""
  property string body: ""
  property string glyph: ""
  property int urgency: 1
  property string timeText: ""

  signal closeRequested()

  radius: Style.cornerRadius
  // 10% translucent surface, like the rest of the UI; alpha on the fill only so
  // the text stays crisp.
  color: Qt.rgba(Color.notifications.background.r, Color.notifications.background.g, Color.notifications.background.b, 0.9)
  borderSpec: Border.flat(urgency === 2
    ? Color.urgent
    : Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.30), 1)
  implicitHeight: rowLayout.implicitHeight + Style.space(20)

  RowLayout {
    id: rowLayout
    anchors.fill: parent
    anchors.margins: Style.space(10)
    spacing: Style.space(10)

    // The notification's own glyph if it carries one, else the app initial.
    Text {
      Layout.alignment: Qt.AlignTop
      text: card.glyph && card.glyph.length ? card.glyph
            : (card.app && card.app.length ? card.app.charAt(0).toUpperCase() : "")
      color: card.urgency === 2 ? Color.urgent : Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.subtitle
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.space(3)

      Text {
        Layout.fillWidth: true
        text: card.summary && card.summary.length ? card.summary : card.app
        color: Color.notifications.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        font.bold: true
        elide: Text.ElideRight
      }
      Text {
        Layout.fillWidth: true
        visible: !!card.body
        text: card.body
        color: Qt.darker(Color.notifications.text, 1.15)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        maximumLineCount: 4
        elide: Text.ElideRight
        textFormat: Text.PlainText
      }
      Text {
        text: card.timeText
        color: Qt.darker(Color.notifications.text, 1.5)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    // Per-item clear.
    Text {
      Layout.alignment: Qt.AlignTop
      text: ""
      color: closeArea.containsMouse ? Color.urgent : Qt.darker(Color.notifications.text, 1.4)
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      MouseArea {
        id: closeArea
        anchors.fill: parent
        anchors.margins: -8
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.closeRequested()
      }
    }
  }
}
