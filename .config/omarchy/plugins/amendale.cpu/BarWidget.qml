import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// CPU load and package temperature. Load comes from /proc/stat deltas -- the
// file holds cumulative jiffies since boot, so a single read says nothing and
// the first tick always reports 0%.
BarWidget {
  id: root
  moduleName: "amendale.cpu"

  property int usage: 0
  property int temperature: 0

  // Previous cumulative totals, for the delta.
  property real lastTotal: 0
  property real lastIdle: 0

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView { id: statFile; path: "/proc/stat" }
  FileView { id: tempFile }

  // hwmon indices are assignment-ordered, so k10temp is not always hwmon3.
  // Resolve it once rather than hardcoding an index that survives until the
  // next boot. Empty output just leaves the temperature off the readout.
  Process {
    running: true
    command: ["bash", "-c",
      "for h in /sys/class/hwmon/hwmon*; do " +
      "[ \"$(cat \"$h/name\" 2>/dev/null)\" = k10temp ] && { echo \"$h/temp1_input\"; break; }; done"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var path = text.trim()
        if (path !== "") tempFile.path = path
      }
    }
  }

  function sample() {
    var body = statFile.text() || ""
    // FileView loads asynchronously, so the first tick sees an empty string.
    if (body === "") return

    var line = body.split("\n")[0]
    if (line.indexOf("cpu ") !== 0) return

    var parts = line.trim().split(/\s+/)
    var total = 0
    for (var i = 1; i < parts.length; i++) total += Number(parts[i])
    // Fields 4 and 5 are idle and iowait; both count as not-busy.
    var idle = Number(parts[4]) + Number(parts[5])

    if (lastTotal > 0) {
      var dTotal = total - lastTotal
      var dIdle = idle - lastIdle
      if (dTotal > 0) usage = Math.max(0, Math.min(100, Math.round((1 - dIdle / dTotal) * 100)))
    }

    lastTotal = total
    lastIdle = idle

    if (tempFile.path) {
      var raw = (tempFile.text() || "").trim()
      if (raw !== "") temperature = Math.round(Number(raw) / 1000)
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statFile.reload()
      if (tempFile.path) tempFile.reload()
      root.sample()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // A vertical bar has no room for the number beside the glyph.
    text: root.vertical ? "" : "  " + root.usage + "%"
    tooltipText: root.temperature > 0
      ? "CPU " + root.usage + "% · " + root.temperature + "°C\nClick for btop"
      : "CPU " + root.usage + "%\nClick for btop"
    onPressed: if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
  }
}
