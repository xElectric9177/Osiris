import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Memory in use, from /proc/meminfo. Uses MemAvailable rather than MemFree, so
// reclaimable page cache doesn't read as memory pressure -- this is the same
// figure `free` reports as "available".
BarWidget {
  id: root
  moduleName: "amendale.memory"

  property int usage: 0
  property real usedGb: 0
  property real totalGb: 0

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView { id: memFile; path: "/proc/meminfo" }

  function sample() {
    var body = memFile.text() || ""
    // FileView loads asynchronously, so the first tick sees an empty string.
    if (body === "") return

    var total = 0
    var available = 0
    var lines = body.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^(MemTotal|MemAvailable):\s+(\d+) kB/)
      if (!m) continue
      if (m[1] === "MemTotal") total = Number(m[2])
      else available = Number(m[2])
      if (total > 0 && available > 0) break
    }
    if (total <= 0) return

    var used = total - available
    usage = Math.max(0, Math.min(100, Math.round((used / total) * 100)))
    usedGb = used / 1048576
    totalGb = total / 1048576
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      memFile.reload()
      root.sample()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical ? "" : "  " + root.usage + "%"
    tooltipText: "Memory " + root.usage + "% · "
      + root.usedGb.toFixed(1) + "G of " + root.totalGb.toFixed(1) + "G\nClick for btop"
    onPressed: if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
  }
}
