import QtQuick

// HH : MM : SS duration steppers. Exposes totalSeconds.
Item {
  id: root

  property var theme
  property int hours: 1
  property int minutes: 0
  property int seconds: 0
  readonly property int totalSeconds: hours * 3600 + minutes * 60 + seconds

  signal edited()

  function setTotalSeconds(total) {
    total = Math.max(0, Math.floor(total))
    hours = Math.min(99, Math.floor(total / 3600))
    minutes = Math.floor((total % 3600) / 60)
    seconds = total % 60
  }

  implicitHeight: row.implicitHeight
  implicitWidth: row.implicitWidth

  Row {
    id: row
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 8

    Stepper {
      theme: root.theme; unit: "HOURS"
      value: root.hours; minValue: 0; maxValue: 99; wrap: false
      onChanged: function (v) { root.hours = v; root.edited() }
    }
    Text { anchors.verticalCenter: parent.verticalCenter; text: ":"; font.pixelSize: 28; color: root.theme.textFaint; font.family: root.theme.fontFamily }
    Stepper {
      theme: root.theme; unit: "MINUTES"
      value: root.minutes; minValue: 0; maxValue: 59; wrap: true
      onChanged: function (v) { root.minutes = v; root.edited() }
    }
    Text { anchors.verticalCenter: parent.verticalCenter; text: ":"; font.pixelSize: 28; color: root.theme.textFaint; font.family: root.theme.fontFamily }
    Stepper {
      theme: root.theme; unit: "SECONDS"
      value: root.seconds; minValue: 0; maxValue: 59; wrap: true
      onChanged: function (v) { root.seconds = v; root.edited() }
    }
  }
}
