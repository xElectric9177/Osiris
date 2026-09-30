import QtQuick

// Builds the exact argv vectors and the human-readable preview string for a
// schedule. Pure — no side effects. Scheduler consumes these.
//
// Design: every action is scheduled as a transient *user* systemd timer via
// `systemd-run --user`, which fires `systemctl <action>` through logind. This
//   - needs no root (polkit grants the active graphical session poweroff/
//     reboot/suspend/hibernate),
//   - survives the GUI closing (the timer lives in the user manager), and
//   - interprets `--on-calendar` in the system LOCAL timezone, so a specific
//     time fires at the wall-clock moment the user picked.
QtObject {
  id: root

  // Stable unit names so status/abort are trivial and only one schedule exists.
  readonly property string unit: "gamers-need-sleep"
  readonly property string warnUnit: "gamers-need-sleep-warn"

  readonly property var actions: ["poweroff", "reboot", "suspend", "hibernate"]

  function actionLabel(action) {
    switch (action) {
    case "poweroff": return "Power Off"
    case "reboot": return "Restart"
    case "suspend": return "Suspend"
    case "hibernate": return "Hibernate"
    }
    return action
  }

  function actionVerb(action) {
    switch (action) {
    case "poweroff": return "power off"
    case "reboot": return "restart"
    case "suspend": return "suspend"
    case "hibernate": return "hibernate"
    }
    return action
  }

  // Whether the wall/broadcast toggle is meaningful for this action. Only the
  // shutdown-family verbs emit a wall message; suspend/hibernate never do.
  function supportsWall(action) {
    return action === "poweroff" || action === "reboot"
  }

  // The `systemctl <verb> [flags]` argv that the timer ultimately runs.
  //   force + poweroff/reboot -> --force (skip the clean manager shutdown)
  //   force + suspend/hibernate -> -i (ignore inhibitor locks)
  //   wall off + poweroff/reboot -> --no-wall
  function actionArgv(action, opts) {
    var argv = ["systemctl", action]
    if (opts.force) {
      if (action === "poweroff" || action === "reboot") argv.push("--force")
      else argv.push("-i")
    }
    if (supportsWall(action) && !opts.wall) argv.push("--no-wall")
    return argv
  }

  // Full argv for arming. `spec` is {kind:"countdown", seconds} or
  // {kind:"specific", calendar:"YYYY-MM-DD HH:MM:SS"}.
  function armArgv(spec, action, opts) {
    var argv = ["systemd-run", "--user", "--collect", "--unit=" + unit,
                "--timer-property=AccuracySec=1s", "--quiet"]
    if (spec.kind === "countdown") argv.push("--on-active=" + spec.seconds + "s")
    else argv.push("--on-calendar=" + spec.calendar)
    return argv.concat(actionArgv(action, opts))
  }

  // Optional pre-execution desktop warning, fired ~`lead` seconds before the
  // action. Only scheduled when notify is on and there is room before the run.
  function warnArgv(spec, action, opts, leadSeconds) {
    var body = "The system will " + actionVerb(action) + " in " + Math.round(leadSeconds / 60) + " min."
    var notify = ["notify-send", "-u", "critical", "-a", "Gamers Need Sleep",
                  "Shutdown timer", body]
    var argv = ["systemd-run", "--user", "--collect", "--unit=" + warnUnit,
                "--timer-property=AccuracySec=1s", "--quiet"]
    if (spec.kind === "countdown") {
      argv.push("--on-active=" + Math.max(1, spec.seconds - leadSeconds) + "s")
    } else {
      argv.push("--on-active=" + Math.max(1, spec.secondsUntil - leadSeconds) + "s")
    }
    return argv.concat(notify)
  }

  // Cancel everything this app may have scheduled. Stopping the .timer cancels
  // a pending run; stopping the .service covers an in-flight one; reset-failed
  // clears any lingering failed transient unit so the fixed name is reusable.
  function abortArgv() {
    return ["systemctl", "--user", "stop",
            unit + ".timer", unit + ".service",
            warnUnit + ".timer", warnUnit + ".service"]
  }

  function resetFailedArgv() {
    return ["systemctl", "--user", "reset-failed",
            unit + ".timer", unit + ".service",
            warnUnit + ".timer", warnUnit + ".service"]
  }

  // Query whether our timer is currently armed. We restore the exact target
  // time from the persisted state file rather than from systemd, because
  // `systemctl show --value` formats the next-elapse as a localized date string
  // that is awkward to parse reliably — ActiveState is all we need here.
  function statusArgv() {
    return ["systemctl", "--user", "show", unit + ".timer",
            "--property=ActiveState", "--value"]
  }

  function inhibitorArgv() {
    return ["systemd-inhibit", "--list", "--no-pager"]
  }

  // Human-readable preview matching what will run, for the live command box.
  function preview(spec, action, opts) {
    return armArgv(spec, action, opts).join(" ")
  }
}
