import QtQuick
import Quickshell
import Quickshell.Io

// The scheduling engine. Owns all process invocation and the persisted state,
// and exposes a small surface the UI binds to:
//   active, activeAction, activeMode, targetEpochMs, remainingSeconds
//   inhibitors (array of {who, what})
//   arm(spec, action, opts), abort(), refreshStatus(), refreshInhibitors()
//
// It talks to systemd directly (Quickshell.Io.Process), so it is frontend
// agnostic — the same instance works in the standalone app and the Omarchy
// plugin. Only one schedule exists at a time (fixed unit name in CommandBuilder).
Item {
  id: root

  readonly property CommandBuilder cb: CommandBuilder {}

  // --- live state -----------------------------------------------------------
  property bool active: false
  property string activeAction: "poweroff"
  property string activeMode: "countdown"
  property real targetEpochMs: 0
  property real activeCreatedMs: 0
  property real nowMs: Date.now()
  readonly property real remainingSeconds: Math.max(0, (targetEpochMs - nowMs) / 1000)
  property var inhibitors: []
  property string lastError: ""
  // Local timezone abbreviation (e.g. "BST"), read from the system so it is
  // exact rather than derived from the JS Date string (which Qt renders without
  // a tz name). Empty until the probe returns; callers fall back meanwhile.
  property string localTz: ""

  signal armed()
  signal aborted()
  signal failed(string message)

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/gamers-need-sleep"

  // Pending arm request, held across the stop -> reset -> run chain.
  property var _spec: null
  property string _action: "poweroff"
  property var _opts: ({})

  // 2-minute pre-warning when notifications are on and there is room for it.
  readonly property int warnLead: 120

  function arm(spec, action, opts) {
    root._spec = spec
    root._action = action
    root._opts = opts || {}
    root.lastError = ""
    // Clear any prior schedule first so the fixed unit name is free.
    armStopProc.command = cb.abortArgv()
    armStopProc.running = true
  }

  function abort() {
    abortStopProc.command = cb.abortArgv()
    abortStopProc.running = true
  }

  function refreshStatus() {
    statusProc.running = true
  }

  function refreshInhibitors() {
    inhibitProc.running = true
  }

  function _doArm() {
    armProc.command = cb.armArgv(root._spec, root._action, root._opts)
    armProc.running = true
  }

  function _onArmed() {
    root.active = true
    root.activeAction = root._action
    root.activeMode = root._spec.kind
    root.targetEpochMs = root._spec.targetEpochMs
    root.activeCreatedMs = Date.now()
    root.nowMs = Date.now()
    _writeState()

    var secondsUntil = (root._spec.targetEpochMs - Date.now()) / 1000
    if (root._opts.notify && secondsUntil > root.warnLead + 15) {
      warnProc.command = cb.warnArgv(root._spec, root._action, root._opts, root.warnLead)
      warnProc.running = true
    }
    if (root._opts.notify) _notifyArmed(secondsUntil)
    root.armed()
    refreshStatus()
  }

  function _notifyArmed(secondsUntil) {
    var mins = Math.round(secondsUntil / 60)
    notifyProc.command = ["notify-send", "-a", "Gamers Need Sleep", "Timer armed",
      "System will " + cb.actionVerb(root._action) + " in ~" + mins + " min."]
    notifyProc.running = true
  }

  function _onAborted() {
    root.active = false
    root.targetEpochMs = 0
    _clearState()
    root.aborted()
  }

  // --- persistence ----------------------------------------------------------
  // The transient timer lives in the user manager independently of this UI, so
  // a small state file lets a freshly opened panel show the rich schedule
  // details (action, mode) rather than just "something is armed".
  function _writeState() {
    var payload = JSON.stringify({
      targetEpochMs: root.targetEpochMs,
      action: root.activeAction,
      mode: root.activeMode,
      createdEpochMs: Date.now()
    })
    stateWriteProc.command = ["bash", "-lc",
      'mkdir -p "$1" && printf "%s" "$2" > "$1/current.json"',
      "bash", root.stateDir, payload]
    stateWriteProc.running = true
  }

  function _clearState() {
    stateClearProc.command = ["bash", "-lc", 'rm -f "$1/current.json"', "bash", root.stateDir]
    stateClearProc.running = true
  }

  function _parseState(text) {
    try { return JSON.parse(text) } catch (e) { return null }
  }

  // --- process plumbing -----------------------------------------------------
  Process { id: armStopProc; onExited: { armResetProc.command = root.cb.resetFailedArgv(); armResetProc.running = true } }
  Process { id: armResetProc; onExited: root._doArm() }
  Process {
    id: armProc
    onExited: function (code) {
      if (code === 0) root._onArmed()
      else {
        root.lastError = "systemd-run failed (exit " + code + ")"
        root.failed(root.lastError)
      }
    }
    stderr: StdioCollector { onStreamFinished: if (text.trim()) root.lastError = text.trim() }
  }
  Process { id: warnProc }
  Process { id: notifyProc }
  Process { id: stateWriteProc }
  Process { id: stateClearProc }

  Process { id: abortStopProc; onExited: { abortResetProc.command = root.cb.resetFailedArgv(); abortResetProc.running = true } }
  Process { id: abortResetProc; onExited: root._onAborted() }

  Process {
    id: statusProc
    command: root.cb.statusArgv()
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root._applyStatus(text)
    }
  }

  function _applyStatus(text) {
    var state = String(text || "").trim().split("\n")[0].trim()
    var timerArmed = (state === "active" || state === "activating" || state === "reloading")

    if (!timerArmed) {
      // No live timer. Discard any stale persisted schedule.
      if (root.active) { root.active = false; root.targetEpochMs = 0 }
      root._loadedState = null
      _clearState()
      return
    }

    root.active = true
    // Restore the exact target/details from the persisted state file.
    if (root._loadedState && root._loadedState.targetEpochMs) {
      root.targetEpochMs = root._loadedState.targetEpochMs
    }
    if (root._loadedState) {
      root.activeAction = root._loadedState.action || root.activeAction
      root.activeMode = root._loadedState.mode || root.activeMode
      if (root._loadedState.createdEpochMs) root.activeCreatedMs = root._loadedState.createdEpochMs
    }
    if (root.activeCreatedMs <= 0) root.activeCreatedMs = Date.now()
    root.nowMs = Date.now()
  }

  Process {
    id: inhibitProc
    command: root.cb.inhibitorArgv()
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root._applyInhibitors(text)
    }
  }

  // Best-effort parse of `systemd-inhibit --list`. Only `block`-mode locks on
  // sleep/shutdown actually prevent the action — `delay` locks (NetworkManager,
  // UPower, the lock-before-suspend hook) just postpone it briefly and are
  // always present, so they are ignored here to avoid a permanent false alarm.
  // The table is space-padded; split on runs of 2+ spaces, MODE is the last
  // column.
  function _applyInhibitors(text) {
    var out = []
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].replace(/\s+$/, "")
      if (!line) continue
      if (/^WHO\b/.test(line)) continue
      if (/inhibitors? listed/.test(line)) continue
      var cols = line.split(/\s{2,}/)
      if (cols.length < 2) cols = line.trim().split(/\s+/)
      var mode = (cols[cols.length - 1] || "").trim().toLowerCase()
      if (mode !== "block") continue
      var what = ""
      for (var c = 0; c < cols.length; c++) {
        if (/\b(sleep|shutdown)\b/.test(cols[c])) { what = cols[c].trim(); break }
      }
      if (!what) continue
      out.push({ who: (cols[0] || "process").trim(), what: what })
    }
    root.inhibitors = out
  }

  // --- restore on startup ---------------------------------------------------
  property var _loadedState: null

  FileView {
    id: stateFile
    path: root.stateDir + "/current.json"
    watchChanges: false
    printErrors: false
    onLoaded: {
      root._loadedState = root._parseState(text())
      root.refreshStatus()
    }
    onLoadFailed: root.refreshStatus()
  }

  // 1 Hz tick drives the live countdown and periodic re-checks.
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      root.nowMs = Date.now()
      // Re-verify roughly every 15s so an externally cancelled/fired timer is
      // reflected, and whenever we appear to have passed the target.
      if (root.active && (root.remainingSeconds <= 0 || (root.nowMs % 15000) < 1000))
        root.refreshStatus()
    }
  }

  Process {
    id: tzProc
    command: ["date", "+%Z"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.localTz = String(text || "").trim()
    }
  }

  Component.onCompleted: {
    refreshStatus()
    refreshInhibitors()
    tzProc.running = true
  }

  // Keep the inhibitor list reasonably fresh while a panel is likely open.
  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refreshInhibitors()
  }
}
