import QtQuick

// Small uppercase section header, e.g. "ACTION TYPE".
Text {
  property var theme
  text: ""
  font.family: theme.fontFamily
  font.pixelSize: 10
  font.bold: true
  font.letterSpacing: 1.5
  color: theme.textMuted
  textFormat: Text.PlainText
}
