// command center: brightness row — tap-icon-to-zero button, slider,
// percentage readout. Brightness state comes from /sys like the bar stats;
// writes go through brightnessctl. Hidden when no backlight exists.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."
import "../ui"

RowLayout {
    id: brightnessControls

    property string backlightPath: ""
    property int brightMax: 1
    property int brightNow: 0
    property int prevBright: 0
    readonly property int brightPerc: Math.min(100, Math.max(0, Math.round(100 * brightNow / Math.max(1, brightMax))))

    visible: backlightPath !== ""
    Layout.fillWidth: true
    spacing: 8

    FileView {
        id: brightMaxLoader

        path: brightnessControls.backlightPath !== "" ? brightnessControls.backlightPath + "/max_brightness" : ""
    }

    FileView {
        id: brightNowLoader

        path: brightnessControls.backlightPath !== "" ? brightnessControls.backlightPath + "/actual_brightness" : ""
    }

    Process {
        id: brightResolve

        command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -e \"$d/max_brightness\" ] && { echo \"$d\"; exit 0; }; done"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                brightnessControls.backlightPath = data.trim();
            }
        }
    }

    Process {
        id: brightSet

        command: ["brightnessctl", "-q", "set", "0%"]
        running: false
    }

    // keeps the slider in sync (set is done by brightnessctl, files catch up
    // a moment later)
    Timer {
        interval: 1500
        running: brightnessControls.backlightPath !== "" && brightnessControls.Window.window !== null && brightnessControls.Window.window.visible
        triggeredOnStart: true
        repeat: true
        onTriggered: {
            brightMaxLoader.reload();
            brightNowLoader.reload();
            brightnessControls.brightMax = parseInt(brightMaxLoader.text().trim()) || 1;
            brightnessControls.brightNow = parseInt(brightNowLoader.text().trim()) || 0;
        }
    }

    CcButton {
        implicitWidth: 28
        glyph: "󰃟"
        name: brightnessControls.brightPerc > 0 ? "Turn screen off" : "Restore brightness"
        onActivate: () => {
            // tap the icon: jump to 0 / back to previous
            if (brightnessControls.brightPerc > 0) {
                brightnessControls.prevBright = brightnessControls.brightNow;
                brightnessControls.brightNow = 0;
            } else {
                brightnessControls.brightNow = brightnessControls.prevBright > 0 ? brightnessControls.prevBright : Math.round(brightnessControls.brightMax / 3);
            }

            brightSet.command = ["brightnessctl", "-q", "set", Math.round(100 * brightnessControls.brightNow / Math.max(1, brightnessControls.brightMax)) + "%"];
            brightSet.running = true;
        }
    }

    CcSlider {
        id: brightSlider

        Layout.fillWidth: true
        from: 0
        to: 100
        stepSize: 1
        value: brightSlider.pressed ? brightSlider.value : brightnessControls.brightPerc
        onPressedChanged: {
            if (pressed)
                return ;

            brightnessControls.brightNow = Math.round(brightSlider.value / 100 * brightnessControls.brightMax);
            brightSet.command = ["brightnessctl", "-q", "set", Math.round(brightSlider.value) + "%"];
            brightSet.running = true;
        }
    }

    CcValueText {
        text: Math.round(brightSlider.value) + "%"
    }

}
