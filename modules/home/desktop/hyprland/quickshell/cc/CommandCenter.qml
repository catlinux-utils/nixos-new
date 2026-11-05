// The command center panel — media, volume, brightness, quick actions,
// calendar — anchored under the clock on the screen whose clock was
// clicked. Hover-dismiss bookkeeping lives in AppState.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../ui"
import ".."

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: ccWindow

        property var modelData

        screen: modelData
        visible: AppState.ccOpen && AppState.ccScreen === modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 340
        implicitHeight: ccBox.implicitHeight

        anchors {
            top: true
            right: true
        }

        margins {
            top: (AppState.barTops[modelData.name] ?? 0) + Theme.barHeight
            right: Theme.pad
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            id: ccBox

            anchors.fill: parent
            radius: 10
            color: Theme.colBg
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.25)
            implicitHeight: ccCol.implicitHeight + 20

            HoverHandler {
                onHoveredChanged: AppState.ccHoverPopup = hovered
            }

            ColumnLayout {
                id: ccCol

                anchors {
                    fill: parent
                    margins: 10
                }

                spacing: 10

                // ── media ──
                MediaSection {
                    visible: AppState.activePlayer !== null
                    player: AppState.activePlayer
                }

                // ── volume + brightness ──
                CcSection {
                    VolumeControls { }

                    BrightnessControls { }

                }

                // ── quick actions ──
                QuickActions { }

                // ── calendar ──
                CalendarSection { }

            }

        }

    }

}
