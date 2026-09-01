// Parse the history dump the reader Process emits and format timestamps.
// The dump is: for each history file, "<filename>\x1f<json>" records joined by
// "\x1e". Explicit separators keep it robust whether the daemon wrote the JSON
// compact or pretty.
.pragma library

function parseDump(raw) {
  var out = []
  if (!raw) return out
  var records = raw.split("\x1e")
  for (var i = 0; i < records.length; i++) {
    var rec = records[i]
    if (!rec) continue
    var sep = rec.indexOf("\x1f")
    if (sep < 0) continue
    var file = rec.slice(0, sep)
    var jsonText = rec.slice(sep + 1).trim()
    if (!jsonText) continue
    try {
      var obj = JSON.parse(jsonText)
      obj.file = file
      out.push(obj)
    } catch (e) {
      // Skip a half-written file rather than break the whole list.
    }
  }
  // Newest first.
  out.sort(function(a, b) { return (b.timestamp || 0) - (a.timestamp || 0) })
  return out
}

function relTime(ts, nowMs) {
  var delta = Math.max(0, nowMs - ts)
  var s = Math.floor(delta / 1000)
  if (s < 45) return "just now"
  var m = Math.floor(s / 60)
  if (m < 60) return m + "m ago"
  var h = Math.floor(m / 60)
  if (h < 24) return h + "h ago"
  var d = Math.floor(h / 24)
  if (d < 7) return d + "d ago"
  return new Date(ts).toLocaleDateString()
}
