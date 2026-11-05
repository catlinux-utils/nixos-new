// CPU / memory / temperature segment — /sys + /proc polled on timers;
// temperature hidden when no CPU sensor resolves (VMs, some desktops).
// Click opens btop.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../.."
import "../../ui"

Item {
    id: resourcesSegment

    property int cpuUsage: 0
    property int memUsage: 0
    property real cpuTemp: 0
    property string tempPath: ""
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    Layout.fillHeight: true
    Layout.preferredWidth: resourcesRow.implicitWidth

    FileView {
        id: cpuLoader

        path: "/proc/stat"
    }

    FileView {
        id: memLoader

        path: "/proc/meminfo"
    }

    FileView {
        id: tempLoader

        path: resourcesSegment.tempPath
    }

    // resolve the CPU sensor once — zone0 is often acpitz or the wifi card,
    // so match the sensor by its type/name instead of taking the first file;
    // no match leaves tempPath empty and the temperature readout hidden
    Process {
        id: tempResolve

        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do case $(cat \"$z/type\" 2>/dev/null) in *x86_pkg_temp*|*cpu*|*k10temp*) echo \"$z/temp\"; exit 0;; esac; done; for h in /sys/class/hwmon/hwmon*; do case $(cat \"$h/name\" 2>/dev/null) in coretemp|k10temp|zenpower|cpu_thermal) for f in \"$h\"/temp*_input; do [ -e \"$f\" ] && { echo \"$f\"; exit 0; }; done;; esac; done"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                resourcesSegment.tempPath = data.trim();
            }
        }
    }

    // shared with the command center's quick actions: pidof guard keeps a
    // second instance from spawning
    Process {
        id: btop

        command: ["sh", "-c", "pidof btop >/dev/null || uwsm app -- btop.desktop"]
        running: false
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cpuLoader.reload();
            var parts = cpuLoader.text().trim().split(/\s+/);
            var user = parseInt(parts[1]) || 0;
            var nice = parseInt(parts[2]) || 0;
            var system = parseInt(parts[3]) || 0;
            var idle = parseInt(parts[4]) || 0;
            var iowait = parseInt(parts[5]) || 0;
            var irq = parseInt(parts[6]) || 0;
            var softirq = parseInt(parts[7]) || 0;
            var steal = parseInt(parts[8]) || 0;
            var total = user + nice + system + idle + iowait + irq + softirq + steal;
            var idleTime = idle + iowait;
            if (resourcesSegment.lastCpuTotal > 0) {
                var totalDiff = total - resourcesSegment.lastCpuTotal;
                var idleDiff = idleTime - resourcesSegment.lastCpuIdle;
                if (totalDiff > 0)
                    resourcesSegment.cpuUsage = Math.round(100 * (totalDiff - idleDiff) / totalDiff);

            }
            resourcesSegment.lastCpuTotal = total;
            resourcesSegment.lastCpuIdle = idleTime;
            memLoader.reload();
            var memTotal = 0, memAvailable = 0;
            var lines = memLoader.text().split('\n');
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.startsWith("MemTotal:"))
                    memTotal = parseInt(line.split(/\s+/)[1]) || 0;
                else if (line.startsWith("MemAvailable:"))
                    memAvailable = parseInt(line.split(/\s+/)[1]) || 0;
            }
            if (memTotal > 0 && memAvailable > 0)
                resourcesSegment.memUsage = Math.round(100 * (memTotal - memAvailable) / memTotal);

        }
    }

    Timer {
        interval: 2000
        running: resourcesSegment.tempPath !== ""
        triggeredOnStart: true
        repeat: true
        onTriggered: {
            tempLoader.reload();
            var raw = parseInt(tempLoader.text().trim()) || 0;
            resourcesSegment.cpuTemp = raw > 1000 ? raw / 1000 : raw;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: btop.running = true
        cursorShape: Qt.PointingHandCursor
    }

    RowLayout {
        id: resourcesRow

        anchors.centerIn: parent
        spacing: 5

        BarIcon {
            text: Utils.cpuIcon(resourcesSegment.cpuUsage)
            color: Utils.cpuColor(resourcesSegment.cpuUsage)
        }

        BarText {
            text: resourcesSegment.cpuUsage + "%"
            color: Utils.cpuColor(resourcesSegment.cpuUsage)
        }

        MiniSeparator { }

        BarIcon {
            text: Utils.memIcon(resourcesSegment.memUsage)
            color: Utils.memColor(resourcesSegment.memUsage)
        }

        BarText {
            text: resourcesSegment.memUsage + "%"
            color: Utils.memColor(resourcesSegment.memUsage)
        }

        // temperature — hidden when no CPU sensor resolved (VMs, some
        // desktops)
        MiniSeparator {
            visible: resourcesSegment.tempPath !== ""
        }

        BarIcon {
            visible: resourcesSegment.tempPath !== ""
            text: Utils.tempIcon(resourcesSegment.cpuTemp)
            color: Utils.tempColor(resourcesSegment.cpuTemp)
        }

        BarText {
            visible: resourcesSegment.tempPath !== ""
            text: resourcesSegment.cpuTemp.toFixed(1) + "°C"
            color: Utils.tempColor(resourcesSegment.cpuTemp)
        }

    }

}
