// Clock pill — click toggles the command center on this screen; hover
// state feeds the popup's hover-dismiss logic (AppState.ccHoverClock)
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

BarBox {
    id: clockBox

    // screen whose clock this is (command center opens on it)
    property var ccScreen: null

    signal toggled(var scr)

    Layout.rightMargin: Theme.pad
    tint: Theme.col16
    interactive: true

    Item {
        id: clockRoot

        Layout.fillHeight: true
        Layout.preferredWidth: clockText.implicitWidth

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onContainsMouseChanged: AppState.ccHoverClock = containsMouse
            onClicked: clockBox.toggled(clockBox.ccScreen)
        }

        BarText {
            id: clockText

            anchors.verticalCenter: parent.verticalCenter
            text: Qt.locale().toString(clock.date, "dddd - dd/MM/yyyy - hh:mm")
            color: Theme.col16

            SystemClock {
                id: clock

                precision: SystemClock.Seconds
            }

        }

    }

}
