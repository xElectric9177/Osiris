import QtQuick
import qs.Ui
import qs.Commons
import "ui" as Gns
import "core" as Core

// Omarchy bar widget: a power-glyph button that toggles a drop-down carrying
// the shared TimerPanel, themed by OmarchyTheme. When a timer is armed the
// button shows the remaining time so it reads at a glance from the bar.
BarWidget {
  id: root
  moduleName: "amendale.shutdown"

  implicitWidth: button.implicitWidth
  implicitHeight: barSize

  property bool popupOpen: false
  function close() { popupOpen = false }

  OmarchyTheme { id: gnsTheme; bar: root.bar }

  // Owned here (not inside the popup) so the bar keeps counting down while the
  // drop-down is closed.
  Core.Scheduler { id: sched }

  function shortRemaining() {
    var s = Math.max(0, Math.floor(sched.remainingSeconds))
    var h = Math.floor(s / 3600)
    var m = Math.floor((s % 3600) / 60)
    if (h > 0) return h + "h" + (m < 10 ? "0" : "") + m
    if (m > 0) return m + "m"
    return (s % 60) + "s"
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // nf-md-power (U+F0425); shows the remaining time alongside it when armed.
    text: sched.active ? ("󰐥 " + root.shortRemaining()) : "󰐥"
    fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
    active: sched.active
    useActiveColor: sched.active && sched.remainingSeconds < 300   // red in the last 5 min
    tooltipText: sched.active
      ? ("System " + sched.activeAction + " in " + root.shortRemaining())
      : "Shutdown / sleep timer"
    onPressed: function (btn) {
      root.popupOpen = !root.popupOpen
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(340))
    contentHeight: popup.fittedContentHeight(panel.contentHeight)

    Gns.TimerPanel {
      id: panel
      anchors.fill: parent
      theme: gnsTheme
      externalScheduler: sched
    }
  }
}
