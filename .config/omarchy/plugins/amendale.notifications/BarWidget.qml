import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "History.js" as History

// Notification center: a bar bell that drops a box out of the top-right corner
// listing the notifications you haven't cleared. It does not run a daemon --
// Omarchy's own notification service already archives every dismissed toast to
// ~/.local/state/omarchy/notifications/history/ as one JSON per notification
// (capped at its own 10). This reads those files and calls the service to
// clear and to toggle Do Not Disturb.
BarWidget {
  id: root
  moduleName: "amendale.notifications"

  // The stock service, reached the same way the DND bar indicator reaches it.
  readonly property var service: bar && bar.shell ? bar.shell.firstPartyServiceFor("omarchy.notifications") : null
  readonly property bool dnd: service ? service.doNotDisturb : false

  readonly property string home: Quickshell.env("HOME")
  readonly property string historyDir: home + "/.local/state/omarchy/notifications/history"
  readonly property string imagesDir: home + "/.local/state/omarchy/notifications/images"

  property bool boxOpen: false
  property int unread: 0

  implicitWidth: bell.implicitWidth
  implicitHeight: bell.implicitHeight

  ListModel { id: notifModel }

  // Lets a keybind open the center, e.g.
  //   qs -p $OMARCHY_PATH/shell ipc call amendale.notifications toggle
  // Registered on every bar instance; the shell uses one and warns (harmless)
  // about the rest, exactly as the stock clock widget does.
  IpcHandler {
    target: "amendale.notifications"
    function open(): void { root.openBox() }
    function close(): void { root.closeBox() }
    function toggle(): void { root.toggleBox() }
  }

  function openBox() { boxOpen = true; readHistory() }
  function closeBox() { boxOpen = false }
  function toggleBox() { boxOpen ? closeBox() : openBox() }

  function readHistory() { if (!readProc.running) readProc.running = true }
  function refreshCount() { if (!countProc.running) countProc.running = true }

  function clearItem(file) {
    if (!file) return
    clearProc.command = ["bash", "-c",
      "rm -f \"$1/$3\"; rm -f \"$2/${3%.json}\".* 2>/dev/null; true",
      "--", root.historyDir, root.imagesDir, file]
    clearProc.running = true
  }

  function clearAll() {
    if (service && typeof service.clearHistory === "function") service.clearHistory()
    else clearAllFallbackProc.running = true
    notifModel.clear()
    unread = 0
    // Reconcile against disk shortly after the daemon's queued delete lands.
    reconcileTimer.restart()
  }

  // ---- history reader: one dump, filename + JSON per record --------------
  Process {
    id: readProc
    command: ["bash", "-c",
      "for f in \"$1\"/*.json; do [ -e \"$f\" ] || continue; printf '%s\\x1f%s\\x1e' \"${f##*/}\" \"$(cat \"$f\")\"; done",
      "--", root.historyDir]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.rebuildModel(text)
    }
  }

  function rebuildModel(raw) {
    var rows = History.parseDump(raw)
    var now = Date.now()
    notifModel.clear()
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i]
      notifModel.append({
        file: r.file || "",
        app: r.app || "",
        summary: r.summary || "",
        body: r.body || "",
        glyph: r.glyph || "",
        urgency: r.urgency === undefined ? 1 : r.urgency,
        timeText: History.relTime(r.timestamp || now, now)
      })
    }
    unread = notifModel.count
  }

  Process {
    id: countProc
    command: ["bash", "-c", "ls \"$1\"/*.json 2>/dev/null | wc -l", "--", root.historyDir]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.unread = parseInt(text.trim()) || 0
    }
  }

  Process {
    id: clearProc
    onExited: { root.readHistory(); root.refreshCount() }
  }
  Process {
    id: clearAllFallbackProc
    command: ["bash", "-c", "rm -f \"$1\"/*.json \"$2\"/* 2>/dev/null; true", "--", root.historyDir, root.imagesDir]
  }

  Timer { id: reconcileTimer; interval: 400; repeat: false; onTriggered: { root.readHistory(); root.refreshCount() } }

  // Badge count is kept fresh even while the box is closed; only the count is
  // read then, not the contents.
  Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refreshCount() }
  // While open, keep the list live.
  Timer { interval: 1500; running: root.boxOpen; repeat: true; onTriggered: root.readHistory() }

  // A toast just arrived or left -> history likely changed.
  Connections {
    target: root.service ? root.service.popupModel : null
    function onCountChanged() { root.refreshCount(); if (root.boxOpen) root.readHistory() }
  }

  // ---- the bar bell + unread badge ---------------------------------------
  WidgetButton {
    id: bell
    anchors.fill: parent
    bar: root.bar
    text: root.dnd ? "" : ""
    tooltipText: root.dnd ? "Do Not Disturb is on\nClick for notifications"
                          : (root.unread > 0 ? root.unread + " notification" + (root.unread === 1 ? "" : "s") + "\nClick to view"
                                             : "Notifications")
    onPressed: root.toggleBox()

    Rectangle {
      id: badge
      visible: root.unread > 0 && !root.dnd
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: Style.space(4)
      anchors.topMargin: Style.space(2)
      width: Math.max(height, badgeText.implicitWidth + Style.space(6))
      height: Math.round(Style.font.caption + Style.space(2))
      radius: height / 2
      color: Color.accent
      Text {
        id: badgeText
        anchors.centerIn: parent
        text: root.unread > 9 ? "9+" : root.unread
        color: Color.background
        font.family: Style.font.family
        font.pixelSize: Style.font.caption - 1
        font.bold: true
      }
    }
  }

  // ---- the top-right box --------------------------------------------------
  PanelWindow {
    id: overlay
    visible: root.boxOpen
    screen: root.QsWindow && root.QsWindow.window ? root.QsWindow.window.screen : null
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "osiris-notification-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore

    // Click anywhere outside the box closes it.
    MouseArea { anchors.fill: parent; onClicked: root.closeBox() }

    BorderSurface {
      id: box
      width: 380
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: (root.barSize > 0 ? root.barSize : 26) + Style.gapsOut
      anchors.rightMargin: Style.gapsOut
      height: content.implicitHeight + Style.space(24)
      radius: Style.cornerRadius
      // 10% translucent surface, matching the rest of the UI; alpha on the fill
      // only so the content stays fully opaque. Layer-shell overlays aren't
      // subject to Hyprland's window opacity, so this is where it goes.
      color: Qt.rgba(Color.notifications.background.r, Color.notifications.background.g, Color.notifications.background.b, 0.9)
      borderSpec: Border.flat(Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.8), 1)

      // Swallow clicks so they don't fall through to the close-catcher.
      MouseArea { anchors.fill: parent; onClicked: {} }

      // Escape closes.
      Item {
        anchors.fill: parent
        focus: root.boxOpen
        Keys.onEscapePressed: root.closeBox()
      }

      ColumnLayout {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Style.space(12)
        spacing: Style.space(10)

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)
          Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }
          Text {
            visible: notifModel.count > 0
            text: "Clear all"
            color: clearAllArea.containsMouse ? Color.accent : Qt.darker(Color.foreground, 1.3)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            MouseArea {
              id: clearAllArea
              anchors.fill: parent
              anchors.margins: -6
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.clearAll()
            }
          }
        }

        Toggle {
          Layout.fillWidth: true
          label: "Do Not Disturb"
          checked: root.dnd
          onClicked: if (root.service) root.service.setDoNotDisturb(!root.service.doNotDisturb)
        }

        ListView {
          id: list
          Layout.fillWidth: true
          Layout.preferredHeight: notifModel.count > 0
            ? Math.min(contentHeight, overlay.height * 0.55)
            : 0
          visible: notifModel.count > 0
          clip: true
          spacing: Style.space(8)
          model: notifModel
          delegate: NotificationCard {
            width: list.width
            app: model.app
            summary: model.summary
            body: model.body
            glyph: model.glyph
            urgency: model.urgency
            timeText: model.timeText
            onCloseRequested: root.clearItem(model.file)
          }
        }

        Text {
          visible: notifModel.count === 0
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(64)
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: "No notifications"
          color: Qt.darker(Color.foreground, 1.5)
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }
      }
    }
  }
}
