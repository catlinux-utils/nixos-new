// small icon button used for transport, month nav and quick actions;
// `active` tints the glyph accent so toggles show their state, `name`
// shows as a hover tooltip
import ".."
import QtQuick
import QtQuick.Controls

Rectangle {
    id: ccBtn

    property string glyph
    property string name: ""
    property bool active: false
    property var onActivate: () => {
    }

    implicitWidth: 34
    implicitHeight: 26
    radius: 5
    color: btnMa.containsMouse ? Qt.alpha(Theme.col16, 0.30) : Qt.alpha(Theme.col16, 0.12)

    Behavior on color {
        ColorAnimation {
            duration: 150
        }

    }

    Text {
        anchors.centerIn: parent
        text: ccBtn.glyph
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        color: btnMa.containsMouse ? Theme.col15 : (ccBtn.active ? Theme.col7 : Theme.col14)
    }

    ToolTip {
        visible: ccBtn.name !== "" && btnMa.containsMouse
        delay: 450
        text: ccBtn.name
    }

    MouseArea {
        id: btnMa

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ccBtn.onActivate()
    }

}
