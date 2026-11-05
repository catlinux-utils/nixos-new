// The bar window — one PanelWindow per screen composing the clusters:
// workspaces (left) | spacer | media, stats, tray, clock (right). Every
// cluster sits in a pill-shaped BarBox with a contrasting 1px border.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: barWindow

        property var modelData

        screen: modelData
        implicitHeight: Theme.barHeight
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: 0
            bottom: 0
            left: 0
            right: 0
        }

        // identifies the bar in `hyprctl layers` so the command center
        // can anchor to its real (possibly stacked) position
        WlrLayershell.namespace: "quickshell:bar"

        // caffeine: inhibit on the bar surface itself — it is always
        // mapped, so the compositor honors the inhibit whenever
        // idleInhibited is on
        IdleInhibitor {
            window: barWindow
            enabled: AppState.idleInhibited
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.colBg

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Workspaces { }

                // ── right cluster ──
                Item {
                    Layout.fillWidth: true
                }

                MediaBox {
                    player: AppState.activePlayer
                }

                StatsBox { }

                TrayBox { }

                ClockBox {
                    ccScreen: modelData
                    onToggled: (scr) => AppState.toggleCc(scr)
                }

            }

        }

    }

}
