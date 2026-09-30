import QtQuick
import Quickshell.Io
import "../core"

// The whole timer UI. Self-contained: owns the Scheduler engine and the pure
// helpers, and renders either the configuration view (pick a schedule) or the
// active view (a running countdown with abort). The only thing a frontend
// provides is `theme`.
Item {
  id: panel

  property var theme
  property bool use24h: true

  // Height the content wants; frontends use this to size their window/popup.
  readonly property real contentHeight: scheduler.active ? activeCol.implicitHeight + 32
                                                         : configCol.implicitHeight + 32

  // Live scheduler state, surfaced so a host (e.g. the Omarchy bar button) can
  // show a countdown without reaching into internals.
  readonly property bool active: scheduler.active
  readonly property real remainingSeconds: scheduler.remainingSeconds
  readonly property string activeAction: scheduler.activeAction

  implicitWidth: 360
  implicitHeight: contentHeight

  // The engine may be supplied by the host (the Omarchy bar widget owns one so
  // the bar can show a countdown while the popup is closed); otherwise we own
  // one (the standalone app).
  property var externalScheduler: null
  readonly property var scheduler: externalScheduler ? externalScheduler : ownScheduler.item
  Loader {
    id: ownScheduler
    active: !panel.externalScheduler
    sourceComponent: Component { Scheduler {} }
  }

  Formatting { id: fmt }
  CommandBuilder { id: cb }

  // --- configuration state --------------------------------------------------
  property int mode: 0                 // 0 = countdown, 1 = specific time
  property string action: "poweroff"
  property bool optForce: false
  property bool optWall: true
  property bool optNotify: true

  property int specHour: {
    var d = new Date(); d.setHours(d.getHours() + 1); return d.getHours()
  }
  property int specMinute: 0
  property int dayOffset: 0            // 0 = today, 1 = tomorrow

  readonly property bool hibernateAvailable: true   // refined by hasSwap probe below

  // Target Date for the specific-time mode, in local time. Auto-rolls to
  // tomorrow if "Today" + the picked time has already passed.
  function specificDate() {
    var now = new Date()
    var d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + panel.dayOffset,
                     panel.specHour, panel.specMinute, 0, 0)
    if (panel.dayOffset === 0 && d.getTime() <= now.getTime()) d.setDate(d.getDate() + 1)
    return d
  }

  function currentSpec() {
    if (panel.mode === 0) {
      var secs = durationPicker.totalSeconds
      return { kind: "countdown", seconds: secs, secondsUntil: secs,
               targetEpochMs: Date.now() + secs * 1000 }
    }
    var d = panel.specificDate()
    var until = (d.getTime() - Date.now()) / 1000
    return { kind: "specific", calendar: fmt.onCalendar(d), secondsUntil: until,
             targetEpochMs: d.getTime() }
  }

  readonly property var opts: ({ force: optForce, wall: optWall, notify: optNotify })
  readonly property bool armEnabled: panel.mode === 0 ? durationPicker.totalSeconds > 0
                                                      : currentSpec().secondsUntil > 0
  readonly property string previewText: cb.preview(currentSpec(), panel.action, panel.opts)

  function arm() {
    if (!panel.armEnabled) return
    scheduler.arm(panel.currentSpec(), panel.action, panel.opts)
  }

  Process { id: copyProc }
  function copy(text) { copyProc.command = ["wl-copy", "--", text]; copyProc.running = true }

  // Detect swap so Hibernate can be disabled when it would just fail.
  property bool _hasSwap: true
  Process {
    id: swapProc
    // /proc/swaps reports size 0 to stat, so `test -s` is wrong here — count
    // data lines instead (header + at least one swap device).
    command: ["bash", "-lc", "[ \"$(wc -l < /proc/swaps)\" -gt 1 ]"]
    onExited: function (code) { panel._hasSwap = (code === 0) }
  }
  Component.onCompleted: swapProc.running = true

  // ==========================================================================
  // Configuration view
  // ==========================================================================
  Flickable {
    anchors.fill: parent
    contentWidth: width
    contentHeight: scheduler.active ? activeCol.implicitHeight : configCol.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: configCol
      visible: !scheduler.active
      width: parent.width
      spacing: 14

      SegTabs {
        theme: panel.theme
        width: parent.width
        options: ["Countdown", "Specific Time"]
        currentIndex: panel.mode
        onSelected: function (i) { panel.mode = i }
      }

      // ---- Countdown sub-view ----
      Column {
        visible: panel.mode === 0
        width: parent.width
        spacing: 10

        DurationPicker {
          id: durationPicker
          theme: panel.theme
          width: parent.width
          hours: 1
        }

        Flow {
          width: parent.width
          spacing: 6
          Chip { theme: panel.theme; text: "+15m"; onClicked: durationPicker.setTotalSeconds(durationPicker.totalSeconds + 900) }
          Chip { theme: panel.theme; text: "+30m"; onClicked: durationPicker.setTotalSeconds(durationPicker.totalSeconds + 1800) }
          Chip { theme: panel.theme; text: "+1h";  onClicked: durationPicker.setTotalSeconds(durationPicker.totalSeconds + 3600) }
          Chip { theme: panel.theme; text: "Reset"; onClicked: durationPicker.setTotalSeconds(0) }
        }
      }

      // ---- Specific-time sub-view ----
      Column {
        visible: panel.mode === 1
        width: parent.width
        spacing: 10

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 8
          Stepper {
            theme: panel.theme; unit: "HOUR"
            value: panel.specHour; minValue: 0; maxValue: 23; wrap: true
            onChanged: function (v) { panel.specHour = v }
          }
          Text { anchors.verticalCenter: parent.verticalCenter; text: ":"; font.pixelSize: 28; color: panel.theme.textFaint; font.family: panel.theme.fontFamily }
          Stepper {
            theme: panel.theme; unit: "MINUTE"
            value: panel.specMinute; minValue: 0; maxValue: 59; wrap: true
            onChanged: function (v) { panel.specMinute = v }
          }
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 6
          Chip { theme: panel.theme; text: "Today";    active: panel.dayOffset === 0; onClicked: panel.dayOffset = 0 }
          Chip { theme: panel.theme; text: "Tomorrow"; active: panel.dayOffset === 1; onClicked: panel.dayOffset = 1 }
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: "Fires " + fmt.firesIn(panel.currentSpec().secondsUntil) + "  ·  "
                + (scheduler.localTz || fmt.tzAbbrev()) + " · Local Time"
          font.family: panel.theme.fontFamily
          font.pixelSize: 11
          color: panel.theme.accent3
        }

        Flow {
          width: parent.width
          spacing: 6
          Chip { theme: panel.theme; text: "Midnight";     onClicked: { panel.specHour = 0;  panel.specMinute = 0; panel.dayOffset = 1 } }
          Chip { theme: panel.theme; text: "End of Work";   onClicked: { panel.specHour = 18; panel.specMinute = 0; panel.dayOffset = 0 } }
          Chip { theme: panel.theme; text: "02:00";         onClicked: { panel.specHour = 2;  panel.specMinute = 0; panel.dayOffset = 1 } }
        }
      }

      SectionLabel { theme: panel.theme; text: "ACTION TYPE" }
      ActionSelector {
        theme: panel.theme
        width: parent.width
        action: panel.action
        hibernateEnabled: panel._hasSwap
        onSelected: function (a) { panel.action = a }
      }

      SectionLabel { theme: panel.theme; text: "BEHAVIOUR" }
      Column {
        width: parent.width
        spacing: 2
        GnsToggle {
          theme: panel.theme; width: parent.width
          title: "Force"
          subtitle: cb.supportsWall(panel.action) ? "Skip clean shutdown (--force)" : "Ignore inhibitor locks (-i)"
          checked: panel.optForce
          onToggled: function (v) { panel.optForce = v }
        }
        GnsToggle {
          theme: panel.theme; width: parent.width
          title: "Wall broadcast"
          subtitle: "Warn other TTY sessions"
          checked: panel.optWall
          enabled: cb.supportsWall(panel.action)
          onToggled: function (v) { panel.optWall = v }
        }
        GnsToggle {
          theme: panel.theme; width: parent.width
          title: "Desktop notification"
          subtitle: "notify-send on arm + before firing"
          checked: panel.optNotify
          onToggled: function (v) { panel.optNotify = v }
        }
      }

      InhibitorWarning {
        theme: panel.theme
        width: parent.width
        inhibitors: scheduler.inhibitors
        forceEnabled: panel.optForce
      }

      SectionLabel { theme: panel.theme; text: "COMMAND" }
      CommandPreview {
        theme: panel.theme
        width: parent.width
        command: panel.previewText
        onCopyRequested: function (t) { panel.copy(t) }
      }

      GnsButton {
        theme: panel.theme
        width: parent.width
        variant: "primary"
        glyph: "⏻"
        text: panel.mode === 0 ? "Schedule " + cb.actionLabel(panel.action)
                               : "Arm " + cb.actionLabel(panel.action)
        enabled: panel.armEnabled
        onClicked: panel.arm()
      }

      Text {
        visible: scheduler.lastError !== ""
        width: parent.width
        wrapMode: Text.WordWrap
        text: scheduler.lastError
        font.family: panel.theme.fontFamily
        font.pixelSize: 10
        color: panel.theme.urgent
      }
    }

    // ========================================================================
    // Active view
    // ========================================================================
    Column {
      id: activeCol
      visible: scheduler.active
      width: parent.width
      spacing: 14

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8
        Rectangle { width: 8; height: 8; radius: 4; anchors.verticalCenter: parent.verticalCenter; color: panel.theme.accent
          SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0.3; duration: 700 } NumberAnimation { to: 1.0; duration: 700 } }
        }
        Text {
          text: "ARMED · " + cb.actionLabel(scheduler.activeAction).toUpperCase()
          font.family: panel.theme.fontFamily
          font.pixelSize: 12
          font.bold: true
          font.letterSpacing: 2
          color: panel.theme.text
        }
      }

      CountdownRing {
        anchors.horizontalCenter: parent.horizontalCenter
        theme: panel.theme
        clockText: fmt.clock(scheduler.remainingSeconds)
        progress: {
          var total = (scheduler.targetEpochMs - scheduler.activeCreatedMs) / 1000
          if (total <= 0) return 1
          return (scheduler.nowMs - scheduler.activeCreatedMs) / 1000 / total
        }
      }

      Column {
        width: parent.width
        spacing: 3
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: fmt.targetLabel(new Date(scheduler.targetEpochMs), panel.use24h)
          font.family: panel.theme.fontFamily
          font.pixelSize: 13
          color: panel.theme.text
        }
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: (scheduler.localTz || fmt.tzAbbrev()) + " · Local Time"
          font.family: panel.theme.fontFamily
          font.pixelSize: 10
          color: panel.theme.textMuted
        }
      }

      Rectangle {
        width: parent.width
        height: regLabel.implicitHeight + 20
        radius: panel.theme.radiusSmall
        color: panel.theme.background
        border.width: 1
        border.color: panel.theme.border
        Text {
          id: regLabel
          anchors.left: parent.left; anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: 12; anchors.rightMargin: 12
          text: "systemctl " + scheduler.activeAction
          font.family: panel.theme.fontFamily
          font.pixelSize: 11
          color: panel.theme.accent3
          elide: Text.ElideRight
        }
      }

      InhibitorWarning {
        theme: panel.theme
        width: parent.width
        inhibitors: scheduler.inhibitors
      }

      GnsButton {
        theme: panel.theme
        width: parent.width
        variant: "danger"
        glyph: "✕"
        text: "Abort"
        onClicked: scheduler.abort()
      }
    }
  }
}
