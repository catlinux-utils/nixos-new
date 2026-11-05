// command center: volume row — mute button, slider, percentage readout;
// hidden when no default sink exists
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import ".."
import "../ui"

RowLayout {
    id: volumeControls

    readonly property var sinkAudio: Pipewire.defaultAudioSink?.audio ?? null

    visible: sinkAudio !== null
    Layout.fillWidth: true
    spacing: 8

    CcButton {
        implicitWidth: 28
        glyph: Utils.volumeIcon(volumeControls.sinkAudio?.muted ?? false, volumeControls.sinkAudio?.volume ?? 0)
        name: (volumeControls.sinkAudio?.muted ?? false) ? "Unmute" : "Mute"
        onActivate: () => {
            if (volumeControls.sinkAudio)
                volumeControls.sinkAudio.muted = !volumeControls.sinkAudio.muted;
        }
    }

    CcSlider {
        id: volSlider

        Layout.fillWidth: true
        from: 0
        to: 1
        stepSize: 0.01
        wheelEnabled: true // scroll to step
        value: volSlider.pressed ? volSlider.value : (volumeControls.sinkAudio?.volume ?? 0)
        onMoved: {
            if (volumeControls.sinkAudio)
                volumeControls.sinkAudio.volume = volSlider.value;
        }
    }

    CcValueText {
        text: Math.floor(volSlider.value * 100) + "%"
    }

}
