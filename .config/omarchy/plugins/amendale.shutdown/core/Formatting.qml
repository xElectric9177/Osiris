import QtQuick

// Pure formatting/time helpers. No state. All date math uses the JS Date
// object, which in QML resolves to the system's LOCAL timezone — this is what
// makes "specific time" scheduling fire at the local wall-clock time the user
// picked (e.g. 23:00 BST), never at a UTC-shifted moment.
QtObject {
  id: root

  function pad2(n) {
    n = Math.floor(n)
    return (n < 10 ? "0" : "") + n
  }

  // "1h 30m 05s" style, compact, drops leading zero units.
  function humanDuration(totalSeconds) {
    var s = Math.max(0, Math.floor(totalSeconds))
    var h = Math.floor(s / 3600)
    var m = Math.floor((s % 3600) / 60)
    var sec = s % 60
    var parts = []
    if (h > 0) parts.push(h + "h")
    if (m > 0 || h > 0) parts.push(m + "m")
    parts.push(sec + "s")
    return parts.join(" ")
  }

  // Fixed HH:MM:SS clock for the big countdown ring.
  function clock(totalSeconds) {
    var s = Math.max(0, Math.floor(totalSeconds))
    var h = Math.floor(s / 3600)
    var m = Math.floor((s % 3600) / 60)
    var sec = s % 60
    return pad2(h) + ":" + pad2(m) + ":" + pad2(sec)
  }

  // "fires in 6h 1m" copy for the specific-time readout.
  function firesIn(seconds) {
    if (seconds <= 0) return "in the past"
    var s = Math.floor(seconds)
    var d = Math.floor(s / 86400)
    var h = Math.floor((s % 86400) / 3600)
    var m = Math.floor((s % 3600) / 60)
    var parts = []
    if (d > 0) parts.push(d + "d")
    if (h > 0) parts.push(h + "h")
    if (m > 0 && d === 0) parts.push(m + "m")
    if (parts.length === 0) parts.push("under a minute")
    return parts.join(" ")
  }

  // Local wall-clock time of day, e.g. "23:00" or "11:45 PM" depending on 24h.
  function timeOfDay(date, use24h) {
    if (use24h) return pad2(date.getHours()) + ":" + pad2(date.getMinutes())
    var h = date.getHours()
    var ampm = h >= 12 ? "PM" : "AM"
    var h12 = h % 12
    if (h12 === 0) h12 = 12
    return h12 + ":" + pad2(date.getMinutes()) + " " + ampm
  }

  // "Today 23:00 · Tue 30 Sep" absolute target label, in local time.
  function targetLabel(date, use24h) {
    var now = new Date()
    var sameDay = date.getFullYear() === now.getFullYear()
      && date.getMonth() === now.getMonth()
      && date.getDate() === now.getDate()
    var tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1)
    var isTomorrow = date.getFullYear() === tomorrow.getFullYear()
      && date.getMonth() === tomorrow.getMonth()
      && date.getDate() === tomorrow.getDate()
    var dayWords = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    var monWords = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var prefix = sameDay ? "Today" : (isTomorrow ? "Tomorrow"
      : dayWords[date.getDay()] + " " + date.getDate() + " " + monWords[date.getMonth()])
    return prefix + " · " + timeOfDay(date, use24h)
  }

  // The local timezone abbreviation (e.g. "BST", "GMT", "CEST"). Parsed out of
  // the Date string's parenthetical; falls back to the numeric UTC offset.
  function tzAbbrev() {
    var s = new Date().toString()
    var m = s.match(/\(([^)]+)\)$/)
    if (m) {
      // "British Summer Time" -> "BST"; leave short codes as-is.
      var name = m[1]
      if (/\s/.test(name)) {
        return name.split(/\s+/).map(function (w) { return w.charAt(0) }).join("").toUpperCase()
      }
      return name
    }
    var off = -new Date().getTimezoneOffset() / 60
    return "UTC" + (off >= 0 ? "+" : "") + off
  }

  // systemd OnCalendar timestamp in local time: "YYYY-MM-DD HH:MM:SS".
  // systemd interprets an unqualified calendar spec in the system timezone,
  // so this is the timezone-correct target.
  function onCalendar(date) {
    return date.getFullYear() + "-" + pad2(date.getMonth() + 1) + "-" + pad2(date.getDate())
      + " " + pad2(date.getHours()) + ":" + pad2(date.getMinutes()) + ":" + pad2(date.getSeconds())
  }
}
