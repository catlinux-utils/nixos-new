//@ pragma UseQApplication

// Layout: workspaces (left) | spacer | media, volume, battery, resources,
// tray, clock (right). Every widget lives in a full-height cell whose content
// is vertically centered, and icons are separate Text items in a fixed-size
// icon font instead of being interpolated into value strings — that is what
// keeps text and glyphs optically level and the spacing proportional.
// Metrics live in the "layout metrics" properties below; palette comes from
// Theme.qml (matugen with hand-tuned fallbacks).
//
// This is a vendored asset: copyable to non-NixOS machines, never generated
// from Nix values (AGENTS.md feature-module pattern #9). On machines without
// JetBrainsMono Nerd Font the glyphs fall back through fontconfig.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

ShellRoot {
    id: root

    // Theme colors
    property color colBg: Theme.colBg
    property color colFg: Theme.colFg
    property color col0: Theme.col0
    property color col1: Theme.col1
    property color col2: Theme.col2
    property color col3: Theme.col3
    property color col4: Theme.col4
    property color col5: Theme.col5
    property color col6: Theme.col6
    property color col7: Theme.col7
    property color col8: Theme.col8
    property color col9: Theme.col9
    property color col10: Theme.col10
    property color col11: Theme.col11
    property color col12: Theme.col12
    property color col13: Theme.col13
    property color col14: Theme.col14
    property color col15: Theme.col15
    property color col16: Theme.col16
    property color colUrgent: Theme.colUrgent
    property string fontFamily: "Noto Sans"
    property int fontSize: 12

    // ── layout metrics ──
    property int barHeight: 28        // panel height (Hyprland reserves this)
    property int iconSize: 15         // nerd-font glyphs, proportional to text
    property string iconFont: "JetBrainsMono Nerd Font" // same font as kitty/vscode/hyprlock
    property int pad: 10              // horizontal padding at the bar edges
    property int gap: 9               // spacing around separators

    // status colors: warning values shift to accentAlt (col11), critical ones
    // to urgent (the matugen error color) — icon and value shift together
    function tempColor(t) {
        return t >= 85 ? root.colUrgent : (t >= 70 ? root.col11 : root.col14);
    }

    function cpuColor(u) {
        return u >= 85 ? root.colUrgent : (u >= 70 ? root.col11 : root.col14);
    }

    function memColor(u) {
        return u >= 90 ? root.colUrgent : (u >= 75 ? root.col11 : root.col14);
    }

    function batteryColor(p) {
        if (root.batteryCharging)
            return root.col14;
        return p <= 15 ? root.colUrgent : (p <= 30 ? root.col11 : root.col14);
    }
    // icon follows the charge level (md-battery_10..90), shows a bolt while
    // charging and md-battery_alert when critical
    function batteryIcon(p) {
        if (root.batteryCharging)
            return "󰂄";
        if (p <= 15)
            return "󰂃";
        if (p <= 10)
            return "󰁺";
        if (p <= 20)
            return "󰁻";
        if (p <= 30)
            return "󰁼";
        if (p <= 40)
            return "󰁽";
        if (p <= 50)
            return "󰁾";
        if (p <= 60)
            return "󰁿";
        if (p <= 70)
            return "󰂀";
        if (p <= 80)
            return "󰂁";
        if (p <= 90)
            return "󰂂";
        return "󰂎";
    }

    property int cpuUsage: 0
    property int memUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property int batteryPerc: 0
    property bool hasBattery: false
    property string batteryPath: ""
    property string batteryStatusPath: ""
    property bool batteryCharging: false
    property real cpuTemp: 0
    property string tempPath: ""
    // media comes from MPRIS (event-driven); prefer a playing player, else the first
    readonly property MprisPlayer activePlayer: Mpris.players.values.find((p) => p.isPlaying) ?? Mpris.players.values[0] ?? null
    property string audioTitle: root.activePlayer?.trackTitle ?? ""
    property string audioAuthor: root.activePlayer?.trackArtist ?? ""

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

        path: root.tempPath
    }

    // resolve the CPU sensor once — zone0 is often acpitz or the wifi card,
    // so match the sensor by its type/name instead of taking the first file
    Process {
        id: tempResolve

        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do case $(cat \"$z/type\" 2>/dev/null) in *x86_pkg_temp*|*cpu*|*k10temp*) echo \"$z/temp\"; exit 0;; esac; done; for h in /sys/class/hwmon/hwmon*; do case $(cat \"$h/name\" 2>/dev/null) in coretemp|k10temp|zenpower|cpu_thermal) for f in \"$h\"/temp*_input; do [ -e \"$f\" ] && { echo \"$f\"; exit 0; }; done;; esac; done; echo /sys/class/thermal/thermal_zone0/temp"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                root.tempPath = data.trim();
            }
        }
    }

    FileView {
        id: batteryLoader

        path: root.batteryPath
    }

    FileView {
        id: batteryStatusLoader

        path: root.batteryStatusPath
    }

    Process {
        id: batteryResolve

        command: ["sh", "-c", "for d in /sys/class/power_supply/BAT*; do [ -e \"$d/capacity\" ] && { echo \"$d/capacity $d/status\"; exit 0; }; done; exit 1"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                var paths = data.trim().split(" ");
                root.batteryPath = paths[0] ?? "";
                root.batteryStatusPath = paths[1] ?? "";
                root.hasBattery = root.batteryPath !== "";
            }
        }
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
            if (root.lastCpuTotal > 0) {
                var totalDiff = total - root.lastCpuTotal;
                var idleDiff = idleTime - root.lastCpuIdle;
                if (totalDiff > 0)
                    root.cpuUsage = Math.round(100 * (totalDiff - idleDiff) / totalDiff);

            }
            root.lastCpuTotal = total;
            root.lastCpuIdle = idleTime;
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
                root.memUsage = Math.round(100 * (memTotal - memAvailable) / memTotal);

        }
    }

    Timer {
        interval: 2000
        running: root.tempPath !== ""
        triggeredOnStart: true
        repeat: true
        onTriggered: {
            tempLoader.reload();
            var raw = parseInt(tempLoader.text().trim()) || 0;
            root.cpuTemp = raw > 1000 ? raw / 1000 : raw;
        }
    }

    Timer {
        interval: 15000
        running: root.batteryPath !== ""
        triggeredOnStart: true
        repeat: true
        onTriggered: {
            batteryLoader.reload();
            var perc = parseInt(batteryLoader.text().trim());
            if (!isNaN(perc))
                root.batteryPerc = perc;

            batteryStatusLoader.reload();
            root.batteryCharging = batteryStatusLoader.text().trim().startsWith("Charging");
        }
    }

    // ── bar building blocks ──

    // dim icon glyph, vertically centered (color overridable per instance)
    component BarIcon: Text {
        color: root.col5
        font.family: root.iconFont
        font.pixelSize: root.iconSize
        Layout.alignment: Qt.AlignVCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

    }

    // bold value text, vertically centered
    component BarText: Text {
        color: root.col14
        font.pixelSize: root.fontSize
        font.family: root.fontFamily
        font.bold: true
        Layout.alignment: Qt.AlignVCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

    }

    // separator between widgets
    component BarSeparator: Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 12
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: root.gap
        Layout.rightMargin: root.gap
        color: root.col1
    }

    // short separator between stats inside one widget
    component MiniSeparator: Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 10
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 7
        Layout.rightMargin: 7
        color: root.col1
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData

            screen: modelData
            implicitHeight: root.barHeight
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

            Rectangle {
                anchors.fill: parent
                color: root.colBg

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // ── left: workspaces ──
                    Item {
                        id: workspaceContainer

                        Layout.fillHeight: true
                        Layout.leftMargin: root.pad
                        Layout.preferredWidth: workspaceRow.implicitWidth

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y > 0)
                                    Hyprland.dispatch(`hl.dsp.focus({workspace = "-1"})`);
                                else if (wheel.angleDelta.y < 0)
                                    Hyprland.dispatch(`hl.dsp.focus({workspace = "+1"})`);
                                wheel.accepted = true;
                            }
                        }

                        Row {
                            id: workspaceRow

                            anchors.centerIn: parent
                            spacing: 3

                            Repeater {
                                model: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

                                Rectangle {
                                    property int wsId: index + 1
                                    property var workspace: Hyprland.workspaces.values.find((w) => {
                                        return w.id === wsId;
                                    })
                                    property bool hasWindows: workspace ? workspace.toplevels.values.length > 0 : false
                                    property bool isActive: Hyprland.focusedWorkspace?.id === wsId

                                    width: wsLabel.implicitWidth + 14
                                    height: root.barHeight - 8
                                    radius: height / 2
                                    color: isActive ? Qt.rgba(1, 1, 1, 0.15) : (hoverArea.containsPress ? Qt.rgba(1, 1, 1, 0.11) : (hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent"))

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                    Text {
                                        id: wsLabel

                                        anchors.centerIn: parent
                                        text: modelData
                                        color: isActive ? root.col15 : (hasWindows ? root.col15 : root.col3)
                                        font.pixelSize: root.fontSize + 1
                                        font.family: root.fontFamily
                                        font.bold: isActive

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }

                                        }

                                    }

                                    MouseArea {
                                        id: hoverArea

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${wsId} })`)
                                        onWheel: (wheel) => {
                                            return wheel.accepted = false;
                                        }
                                        cursorShape: Qt.PointingHandCursor
                                    }

                                }

                            }

                        }

                    }

                    // ── right cluster ──
                    Item {
                        Layout.fillWidth: true
                    }

                    // Media (MPRIS) — hidden entirely when nothing is playing
                    RowLayout {
                        visible: root.audioTitle !== ""
                        Layout.fillHeight: true
                        spacing: 6

                        BarIcon {
                            text: "󰎈"
                            color: root.activePlayer?.isPlaying ? root.col7 : root.col3
                        }

                        BarText {
                            text: root.audioAuthor !== "" ? root.audioAuthor + " - " + root.audioTitle : root.audioTitle
                            color: root.activePlayer?.isPlaying ? root.col7 : root.col3
                            Layout.maximumWidth: 300
                            elide: Text.ElideRight
                        }

                    }

                    BarSeparator {
                        visible: root.audioTitle !== ""
                    }

                    // Volume — click toggles mute, middle-click opens pavucontrol, wheel steps 1%
                    Item {
                        id: volumeRoot

                        readonly property PwNode defaultSink: Pipewire.defaultAudioSink
                        readonly property PwNode source: Pipewire.defaultAudioSource

                        Layout.fillHeight: true
                        Layout.preferredWidth: volumeRow.implicitWidth

                        PwObjectTracker {
                            objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
                        }

                        RowLayout {
                            id: volumeRow

                            anchors.centerIn: parent
                            spacing: 5

                            BarIcon {
                                text: volumeRoot.defaultSink?.audio?.muted ? "" : ""
                            }

                            BarText {
                                text: Math.floor((volumeRoot.defaultSink?.audio?.volume || 0) * 100) + "%"
                                color: volumeRoot.defaultSink?.audio?.muted ? root.col3 : root.col14
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
                                if (volumeRoot.defaultSink?.audio)
                                    volumeRoot.defaultSink.audio.muted = !volumeRoot.defaultSink.audio.muted;
                            }
                            onWheel: (wheel) => {
                                if (!volumeRoot.defaultSink?.audio)
                                    return ;
                                // 1%
                                let step = 0.01;
                                let vol = volumeRoot.defaultSink.audio.volume;
                                let newVol;
                                if (wheel.angleDelta.y > 0)
                                    newVol = Math.min(1, vol + step);
                                else
                                    newVol = Math.max(0, vol - step);
                                volumeRoot.defaultSink.audio.volume = newVol;
                                wheel.accepted = true;
                            }
                        }

                    }

                    BarSeparator { }

                    // Battery
                    RowLayout {
                        visible: root.hasBattery
                        Layout.fillHeight: true
                        spacing: 5

                        BarIcon {
                            text: root.batteryIcon(root.batteryPerc)
                            color: root.batteryColor(root.batteryPerc)
                        }

                        BarText {
                            text: root.batteryPerc + "%"
                            color: root.batteryColor(root.batteryPerc)
                        }

                    }

                    BarSeparator {
                        visible: root.hasBattery
                    }

                    // CPU / memory / temperature — click opens btop
                    Item {
                        id: resourcesContainer

                        Layout.fillHeight: true
                        Layout.preferredWidth: resourcesRow.implicitWidth

                        Process {
                            id: btop

                            command: ["sh", "-c", "pidof btop >/dev/null || uwsm app -- kitty -e btop"]
                            running: false
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
                                text: ""
                                color: root.cpuColor(root.cpuUsage)
                            }

                            BarText {
                                text: root.cpuUsage + "%"
                                color: root.cpuColor(root.cpuUsage)
                            }

                            MiniSeparator { }

                            BarIcon {
                                text: ""
                                color: root.memColor(root.memUsage)
                            }

                            BarText {
                                text: root.memUsage + "%"
                                color: root.memColor(root.memUsage)
                            }

                            MiniSeparator { }

                            BarIcon {
                                text: ""
                                color: root.tempColor(root.cpuTemp)
                            }

                            BarText {
                                text: root.cpuTemp.toFixed(1) + "°C"
                                color: root.tempColor(root.cpuTemp)
                            }

                        }

                    }

                    BarSeparator {
                        visible: sysTray.count > 0
                    }

                    // Tray
                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: trayRow.implicitWidth
                        visible: sysTray.count > 0

                        Row {
                            id: trayRow

                            anchors.centerIn: parent
                            spacing: 6

                            Repeater {
                                id: sysTray

                                model: SystemTray.items

                                WrapperMouseArea {
                                    id: mouseArea

                                    required property SystemTrayItem modelData

                                    acceptedButtons: Qt.AllButtons
                                    onClicked: (event) => {
                                        switch (event.button) {
                                        case Qt.LeftButton:
                                            modelData.activate();
                                            break;
                                        case Qt.RightButton:
                                            if (modelData.hasMenu)
                                                menu.open();

                                            break;
                                        }
                                        event.accepted = true;
                                    }

                                    IconImage {
                                        implicitHeight: root.iconSize
                                        implicitWidth: root.iconSize
                                        anchors.fill: parent
                                        source: modelData.icon
                                    }

                                    QsMenuAnchor {
                                        id: menu

                                        menu: mouseArea.modelData.menu

                                        anchor {
                                            item: mouseArea
                                            edges: Edges.Top
                                            gravity: Edges.Top
                                            adjustment: PopupAdjustment.All
                                        }

                                    }

                                }

                            }

                        }

                    }

                    BarSeparator {
                        visible: sysTray.count > 0
                    }

                    // Clock
                    BarText {
                        id: clockText

                        text: Qt.locale().toString(clock.date, "dddd - dd/MM/yyyy - hh:mm")
                        color: root.col16
                        Layout.rightMargin: root.pad

                        SystemClock {
                            id: clock

                            precision: SystemClock.Seconds
                        }

                    }

                }

            }

        }

    }

}
