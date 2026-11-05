// Microphone segment — icon only, hidden when no input device exists;
// click toggles default-source mute
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../.."
import "../../ui"

Item {
    id: micSegment

    readonly property PwNode mic: Pipewire.defaultAudioSource

    visible: mic !== null
    Layout.fillHeight: true
    Layout.preferredWidth: micRow.implicitWidth

    RowLayout {
        id: micRow

        anchors.centerIn: parent
        spacing: 5

        BarIcon {
            text: Utils.micIcon(micSegment.mic?.audio?.muted ?? false)
            color: (micSegment.mic?.audio?.muted ?? false) ? Theme.col3 : Theme.col14
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (micSegment.mic?.audio)
                micSegment.mic.audio.muted = !micSegment.mic.audio.muted;
        }
    }

}
