// Battery segment — resolves the first /sys/class/power_supply/BAT* with a
// capacity file once, then polls every 15 s. Hidden when no battery exists.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../.."
import "../../ui"

RowLayout {
    id: batterySegment

    property int perc: 0
    property bool charging: false
    property string capacityPath: ""
    property string statusPath: ""
    readonly property bool present: capacityPath !== ""

    visible: present
    Layout.fillHeight: true
    spacing: 5

    FileView {
        id: capacityLoader

        path: batterySegment.capacityPath
    }

    FileView {
        id: statusLoader

        path: batterySegment.statusPath
    }

    Process {
        id: batteryResolve

        command: ["sh", "-c", "for d in /sys/class/power_supply/BAT*; do [ -e \"$d/capacity\" ] && { echo \"$d/capacity $d/status\"; exit 0; }; done; exit 1"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                var paths = data.trim().split(" ");
                batterySegment.capacityPath = paths[0] ?? "";
                batterySegment.statusPath = paths[1] ?? "";
            }
        }
    }

    Timer {
        interval: 15000
        running: batterySegment.capacityPath !== ""
        triggeredOnStart: true
        repeat: true
        onTriggered: {
            capacityLoader.reload();
            var perc = parseInt(capacityLoader.text().trim());
            if (!isNaN(perc))
                batterySegment.perc = perc;

            statusLoader.reload();
            batterySegment.charging = statusLoader.text().trim().startsWith("Charging");
        }
    }

    BarIcon {
        text: Utils.batteryIcon(batterySegment.perc, batterySegment.charging)
        color: Utils.batteryColor(batterySegment.perc, batterySegment.charging)
    }

    BarText {
        text: batterySegment.perc + "%"
        color: Utils.batteryColor(batterySegment.perc, batterySegment.charging)
    }

}
