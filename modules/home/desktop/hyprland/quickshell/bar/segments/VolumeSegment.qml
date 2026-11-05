// Volume segment — click toggles mute, middle-click opens pavucontrol,
// wheel steps 1%. Hidden when no output device exists (VM without audio).
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../.."
import "../../ui"

Item {
    id: volumeSegment

    readonly property PwNode defaultSink: Pipewire.defaultAudioSink

    // no output device (VM without audio) — hide the segment
    visible: defaultSink !== null
    Layout.fillHeight: true
    Layout.preferredWidth: volumeRow.implicitWidth

    RowLayout {
        id: volumeRow

        anchors.centerIn: parent
        spacing: 5

        BarIcon {
            text: Utils.volumeIcon(volumeSegment.defaultSink?.audio?.muted ?? false, volumeSegment.defaultSink?.audio?.volume || 0)
            color: volumeSegment.defaultSink?.audio?.muted ? Theme.col3 : Theme.col14
        }

        BarText {
            text: Math.floor((volumeSegment.defaultSink?.audio?.volume || 0) * 100) + "%"
            color: volumeSegment.defaultSink?.audio?.muted ? Theme.col3 : Theme.col14
        }

    }

    Process {
        id: pavucontrolProc

        command: ["uwsm", "app", "--", "pavucontrol"]
        running: false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (event) => {
            if (event.button === Qt.MiddleButton) {
                pavucontrolProc.running = true;
                return ;
            }
            if (volumeSegment.defaultSink?.audio)
                volumeSegment.defaultSink.audio.muted = !volumeSegment.defaultSink.audio.muted;
        }
        onWheel: (wheel) => {
            if (!volumeSegment.defaultSink?.audio)
                return ;
            // 1%
            let step = 0.01;
            let vol = volumeSegment.defaultSink.audio.volume;
            let newVol;
            if (wheel.angleDelta.y > 0)
                newVol = Math.min(1, vol + step);
            else
                newVol = Math.max(0, vol - step);
            volumeSegment.defaultSink.audio.volume = newVol;
            wheel.accepted = true;
        }
    }

}
