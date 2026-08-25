import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "amendale.media"

  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("amendale.media")
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property var sourcePlayers: mediaService ? mediaService.sourcePlayers : []

  readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle || activePlayer.trackArtist)
  readonly property string playIcon: activePlayer && activePlayer.isPlaying ? "󰏤" : "󰐊"
  readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""

  readonly property real trackLength: activePlayer && activePlayer.lengthSupported ? activePlayer.length : 0
  readonly property bool hasProgress: activePlayer && activePlayer.positionSupported && activePlayer.lengthSupported && trackLength > 0

  // MPRIS only pushes position updates on seeks/play-pause, not every second,
  // so track a local base position + timestamp and interpolate between
  // updates while playing, resyncing whenever the backend actually changes.
  property real trackPositionBase: 0
  property real trackPositionBaseTime: 0
  property int _positionTick: 0

  readonly property real trackPosition: {
    var _tick = root._positionTick
    if (!root.activePlayer || !root.activePlayer.positionSupported) return 0
    if (!root.activePlayer.isPlaying) return root.trackPositionBase
    var elapsed = (Date.now() - root.trackPositionBaseTime) / 1000
    var value = root.trackPositionBase + elapsed
    return root.trackLength > 0 ? Math.min(root.trackLength, value) : value
  }

  function formatTrackTime(seconds) {
    var total = Math.max(0, Math.floor(seconds))
    var m = Math.floor(total / 60)
    var s = total % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }

  function resyncTrackPosition() {
    root.trackPositionBase = root.activePlayer ? root.activePlayer.position : 0
    root.trackPositionBaseTime = Date.now()
  }

  property bool popupOpen: false
  onPopupOpenChanged: if (popupOpen) root.resyncTrackPosition()

  function close() { popupOpen = false }
  property real maxLabelWidth: 180

  visible: hasMedia
  implicitWidth: hasMedia ? row.implicitWidth + Style.space(14) : 0
  implicitHeight: barSize

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      id: glyph
      anchors.verticalCenter: parent.verticalCenter
      text: root.playIcon
      color: activePlayer && activePlayer.isPlaying ? root.bar.barForeground : Qt.darker(root.bar.barForeground, 1.5)
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
      Behavior on color {
        enabled: !root.bar || root.bar.foregroundAnimationEnabled
        ColorAnimation { duration: 160 }
      }
    }

    Item {
      id: scrollClip
      width: Math.min(root.maxLabelWidth, labelText.implicitWidth)
      height: glyph.height
      clip: true
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.bar.vertical && root.title !== ""

      Text {
        id: labelText
        text: root.title + (root.artist ? "  ·  " + root.artist : "")
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        anchors.verticalCenter: parent.verticalCenter

        // Text metrics take a couple of layout passes to settle (font
        // loading, subpixel reflow) and change again on every track change,
        // so implicitWidth is volatile. Binding the animation's from/to/
        // duration live to it means every jump implicitly restarts the
        // animation — it never gets far enough to be visible. Debounce: wait
        // for implicitWidth to stop changing for a beat, then snapshot a
        // stable scroll span. Re-fires on every text change too (not just
        // needsScroll flips), so a long track changing to another long track
        // still gets fresh distances instead of the previous track's stale
        // ones.
        property bool needsScroll: false
        property real scrollFrom: 0
        property real scrollTo: 0
        property real scrollDuration: 6000

        onImplicitWidthChanged: settleTimer.restart()
        onTextChanged: settleTimer.restart()

        Timer {
          id: settleTimer
          interval: 150
          onTriggered: {
            labelText.needsScroll = labelText.implicitWidth > scrollClip.width
            if (labelText.needsScroll) {
              labelText.scrollFrom = scrollClip.width
              labelText.scrollTo = -labelText.implicitWidth
              labelText.scrollDuration = Math.max(6000, labelText.implicitWidth * 25)
            } else {
              labelText.x = 0
            }
          }
        }

        NumberAnimation on x {
          id: scrollAnim
          running: labelText.needsScroll && !root.popupOpen && !root.bar.vertical
          loops: Animation.Infinite
          duration: labelText.scrollDuration
          from: labelText.scrollFrom
          to: labelText.scrollTo
          easing.type: Easing.Linear
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.activePlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (!root.activePlayer) return
      if (mouse.button === Qt.MiddleButton) {
        if (root.mediaService) root.mediaService.runAction("next", false)
      } else if (mouse.button === Qt.RightButton) {
        if (root.mediaService) root.mediaService.runAction("playPause", false)
      } else {
        root.popupOpen = !root.popupOpen
      }
    }
    onWheel: function(wheel) {
      if (!root.activePlayer) return
      if (wheel.angleDelta.y > 0 && root.mediaService) root.mediaService.runAction("previous", false)
      else if (wheel.angleDelta.y < 0 && root.mediaService) root.mediaService.runAction("next", false)
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.hasMedia ? (root.title + (root.artist ? " — " + root.artist : "")) : "")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  Connections {
    target: root.activePlayer
    function onPositionChanged() { root.resyncTrackPosition() }
    function onIsPlayingChanged() { root.resyncTrackPosition() }
  }

  Timer {
    interval: 500
    running: root.popupOpen && root.activePlayer && root.activePlayer.isPlaying
    repeat: true
    onTriggered: root._positionTick++
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        spacing: Style.space(10)
        width: parent.width

        BorderSurface {
          width: Style.space(64)
          height: Style.space(64)
          radius: Style.space(14)
          clip: true
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

          Item {
            id: artMask
            anchors.fill: parent
            anchors.margins: Style.space(2)
            visible: false
            layer.enabled: true

            Rectangle {
              anchors.fill: parent
              radius: Style.space(12)
              color: "white"
            }
          }

          Item {
            anchors.fill: parent
            anchors.margins: Style.space(2)
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              maskEnabled: true
              maskSource: artMask
              maskThresholdMin: 0.3
              maskSpreadAtMin: 0.3
            }

            Image {
              anchors.fill: parent
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              source: root.activePlayer && root.activePlayer.trackArtUrl ? root.activePlayer.trackArtUrl : ""
              visible: source !== ""
            }
          }

          Text {
            anchors.centerIn: parent
            visible: !root.activePlayer || !root.activePlayer.trackArtUrl
            text: "󰝚"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
          }
        }

        Column {
          spacing: Style.space(4)
          width: parent.width - Style.space(74)

          Text {
            text: root.title || "Nothing playing"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            text: root.artist
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }

          Text {
            text: root.activePlayer && root.activePlayer.trackAlbum ? root.activePlayer.trackAlbum : ""
            color: Qt.darker(root.bar.foreground, 1.6)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }
        }
      }

      Column {
        width: parent.width
        spacing: Style.space(4)
        visible: root.hasProgress

        BorderSurface {
          id: progressTrack
          width: parent.width
          height: Style.space(6)
          radius: height / 2
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.none()

          Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            radius: height / 2
            color: Color.accent
            width: root.trackLength > 0
              ? Math.max(height, parent.width * Math.min(1, root.trackPosition / root.trackLength))
              : 0

            Behavior on width {
              enabled: root.popupOpen
              NumberAnimation { duration: 400; easing.type: Easing.Linear }
            }
          }
        }

        Item {
          width: parent.width
          height: elapsedLabel.implicitHeight

          Text {
            id: elapsedLabel
            anchors.left: parent.left
            text: root.formatTrackTime(root.trackPosition)
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            anchors.right: parent.right
            text: root.formatTrackTime(root.trackLength)
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)

        Button {
          iconText: "󰒮"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.activePlayer && root.activePlayer.canGoPrevious
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("previous", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          iconText: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.panelGap
          verticalPadding: Style.spacing.controlPaddingY
          iconSize: Style.font.iconLarge
          enabled: root.activePlayer && (root.activePlayer.canTogglePlaying || root.activePlayer.canPlay || root.activePlayer.canPause)
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("playPause", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          iconText: "󰒭"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.activePlayer && root.activePlayer.canGoNext
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("next", false, root.mediaService.playerKey(root.activePlayer))
        }
      }

      PanelSeparator {
        visible: root.sourcePlayers.length > 1
        foreground: root.bar.foreground
      }

      Column {
        id: sourceList
        visible: root.sourcePlayers.length > 1
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          model: root.sourcePlayers

          BorderSurface {
            id: sourceRow
            required property var modelData

            readonly property var player: modelData
            readonly property bool selected: root.activePlayer && player
              && root.mediaService.playerKey(root.activePlayer) === root.mediaService.playerKey(player)
            readonly property string sourceTitle: player ? (player.trackTitle || player.identity || player.desktopEntry || "Media source") : "Media source"
            readonly property string sourceDetail: player && player.trackArtist ? player.trackArtist : (player && player.identity ? player.identity : "")

            width: sourceList.width
            height: sourceInner.implicitHeight + Style.space(10)
            radius: Style.space(10)
            color: selected ? Style.selectedFillFor(root.bar.foreground, Color.accent) : "transparent"
            borderSpec: selected ? Border.controlSpec("normal", root.bar.foreground, Color.accent) : Border.none()

            Row {
              id: sourceInner
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: sourceRow.borderLeft + Style.space(8)
              anchors.rightMargin: sourceRow.borderRight + Style.space(8)
              spacing: Style.space(8)

              Text {
                text: sourceRow.player && sourceRow.player.isPlaying ? "󰏤" : "󰐊"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
                width: Style.space(18)
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - Style.space(26)
                spacing: Style.space(1)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  text: sourceRow.sourceTitle
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: sourceRow.selected
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  text: sourceRow.sourceDetail
                  color: Qt.darker(root.bar.foreground, 1.5)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  width: parent.width
                  visible: text !== ""
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.mediaService) root.mediaService.selectPlayer(root.mediaService.playerKey(sourceRow.player))
            }
          }
        }
      }
    }
  }
}
