import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// GPU load and edge temperature, straight from amdgpu sysfs. Unlike the CPU
// this needs no delta -- gpu_busy_percent is already a percentage.
BarWidget {
  id: root
  moduleName: "amendale.gpu"

  property int usage: 0
  property int temperature: 0

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView { id: busyFile }
  FileView { id: tempFile }

  // Machines with an iGPU alongside a discrete card expose several DRM cards,
  // and their numbering is not stable across boots. Pick the one with the most
  // VRAM, which is the discrete card on any system where the distinction
  // matters. Resolved once at startup.
  Process {
    running: true
    command: ["bash", "-c",
      "best=; size=0; " +
      "for d in /sys/class/drm/card*/device; do " +
      "  [ -r \"$d/gpu_busy_percent\" ] || continue; " +
      "  v=$(cat \"$d/mem_info_vram_total\" 2>/dev/null || echo 0); " +
      "  [ \"$v\" -gt \"$size\" ] && { size=$v; best=$d; }; " +
      "done; " +
      "[ -n \"$best\" ] || exit 0; " +
      "echo \"$best/gpu_busy_percent\"; " +
      "for h in \"$best\"/hwmon/hwmon*; do " +
      "  [ -r \"$h/temp1_input\" ] && { echo \"$h/temp1_input\"; break; }; done"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = text.trim().split("\n")
        if (lines.length > 0 && lines[0] !== "") busyFile.path = lines[0]
        if (lines.length > 1 && lines[1] !== "") tempFile.path = lines[1]
      }
    }
  }

  function sample() {
    if (busyFile.path) {
      // FileView loads asynchronously, so early ticks see an empty string.
      var busy = (busyFile.text() || "").trim()
      if (busy !== "") usage = Math.max(0, Math.min(100, Math.round(Number(busy))))
    }
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
      if (busyFile.path) busyFile.reload()
      if (tempFile.path) tempFile.reload()
      root.sample()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical ? "󰢭" : "󰢭  " + root.usage + "%"
    tooltipText: root.temperature > 0
      ? "GPU " + root.usage + "% · " + root.temperature + "°C\nClick for btop"
      : "GPU " + root.usage + "%\nClick for btop"
    onPressed: if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
  }
}
