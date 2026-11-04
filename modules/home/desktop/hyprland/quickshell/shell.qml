//@ pragma UseQApplication

// Layout: workspaces (left) | spacer | media, stats (volume, battery,
// resources), tray, clock (right). Every cluster sits in a pill-shaped
// BarBox with a contrasting 1px border. Icons are separate Text items in a
// fixed-size icon font instead of being interpolated into value strings —
// that is what keeps text and glyphs optically level and the spacing
// proportional.
// Metrics live in the "layout metrics" properties below; palette comes from
// Theme.qml (matugen with hand-tuned fallbacks).
//
// This is a vendored asset: copyable to non-NixOS machines, never generated
// from Nix values (AGENTS.md feature-module pattern #9). On machines without
// JetBrainsMono Nerd Font the glyphs fall back through fontconfig.

import QtQuick
import QtQuick.Controls
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
    property int pad: 4               // small inset at the bar edges

    // ── command center (toggled by clicking the clock) ──
    // A small Overlay-layer panel under the clock with media controls, volume
    // and brightness sliders, quick actions and a month calendar. `ccScreen`
    // keeps it on the monitor whose clock was clicked; hovering off it (and the
    // clock) dismisses it, clicks outside it never land on the popup at all.
    property bool ccOpen: false
    // hover-dismiss: the popup stays open while the pointer is over the popup
    // itself or the clock; a short grace timer closes it once it's over neither
    property bool ccHoverPopup: false
    property bool ccHoverClock: false
    property var ccScreen: null
    property date ccMonth: {
        var n = new Date();
        return new Date(n.getFullYear(), n.getMonth(), 1);
    }
    property var ccCells: root.calendarCells(ccMonth)
    property var ccWeekdays: {
        var names = [];
        for (var i = 0; i < 7; i++)
            names.push(Qt.locale().standaloneDayName((i + 1) % 7, Locale.ShortFormat));
        return names;
    }
    // y offset of the bar surface per output, read from Hyprland's layer
    // list when the command center opens — with a second (test) bar stacked
    // above, the bar does not sit at y=0 and the popup must anchor below its
    // real position. Our bar is identified by its layer namespace.
    property var barTops: ({})
    // brightness comes from /sys like the other stats; writes go through
    // brightnessctl
    property string backlightPath: ""
    property int brightMax: 1
    property int brightNow: 0
    property int ccPrevBright: 0
    readonly property int brightPerc: Math.min(100, Math.max(0, Math.round(100 * root.brightNow / Math.max(1, root.brightMax))))
    readonly property var sinkAudio: Pipewire.defaultAudioSink?.audio ?? null

    // 42-cell Monday-first month grid, neighbouring months dimmed
    function calendarCells(d) {
        var cells = [];
        var offset = (new Date(d.getFullYear(), d.getMonth(), 1).getDay() + 6) % 7;
        var dim = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
        var dimPrev = new Date(d.getFullYear(), d.getMonth(), 0).getDate();
        for (var i = 0; i < 42; i++) {
            if (i < offset)
                cells.push({
                    "day": dimPrev - offset + 1 + i,
                    "other": true
                });
            else if (i - offset < dim)
                cells.push({
                    "day": i - offset + 1,
                    "other": false
                });
            else
                cells.push({
                    "day": i - offset - dim + 1,
                    "other": true
                });
        }
        return cells;
    }

    function toggleCc(screen) {
        layerQuery.running = true;
        if (root.ccOpen && root.ccScreen === screen) {
            root.ccOpen = false;
            return ;
        }
        root.ccScreen = screen;
        root.activePlayer?.positionChanged(); // refresh the position binding now, not at the first tick
        root.ccOpen = true;
    }

    // MprisPlayer reports position/length in seconds (ms precision)
    function fmtSec(sec) {
        if (!sec || sec <= 0)
            return "0:00";
        var s = Math.floor(sec);
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    SystemClock {
        id: ccClock

        precision: SystemClock.Seconds
    }

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

    // volume follows the sink state: md-volume_off when muted, otherwise
    // md-volume_high/medium/low stepped by level
    function volumeIcon(muted, v) {
        if (muted)
            return "󰖁";
        if (v >= 0.5)
            return "󰕾";
        if (v >= 0.2)
            return "󰖀";
        return "󰕿";
    }

    // load steps the glyph up with severity: cpu moves to md-speedometer on
    // warning and md-alert on critical; memory switches to md-alert on critical
    function cpuIcon(u) {
        if (u >= 85)
            return "󰀦";
        if (u >= 70)
            return "󰓅";
        return "󰻠";
    }

    function memIcon(u) {
        if (u >= 90)
            return "󰀦";
        return "󰍛";
    }

    // temperature steps up md-thermometer -> md-thermometer_high -> md-thermometer_alert
    function tempIcon(t) {
        if (t >= 85)
            return "󰸁";
        if (t >= 70)
            return "󱃂";
        return "󰔏";
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
    // livestreams (Twitch, browser live tabs) report no usable length — Chromium
    // emits INT64_MAX, some players emit 0 — treat that as live and hide the
    // progress/time row instead of showing a bogus clock
    readonly property bool mediaLive: root.activePlayer !== null
        && (root.activePlayer.length <= 0 || root.activePlayer.length > 86400) // > 24h can't be a track

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

    FileView {
        id: brightMaxLoader

        path: root.backlightPath !== "" ? root.backlightPath + "/max_brightness" : ""
    }

    FileView {
        id: brightNowLoader

        path: root.backlightPath !== "" ? root.backlightPath + "/actual_brightness" : ""
    }

    Process {
        id: brightResolve

        command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -e \"$d/max_brightness\" ] && { echo \"$d\"; exit 0; }; done"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                root.backlightPath = data.trim();
            }
        }
    }

    Process {
        id: brightSet

        command: ["brightnessctl", "-q", "set", "0%"]
        running: false
    }

    // command center: locate the bar's layer surface per output
    Process {
        id: layerQuery

        command: ["hyprctl", "-j", "layers"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var tops = {};
                try {
                    var outputs = JSON.parse(text);
                    for (var output in outputs) {
                        var levels = outputs[output].levels;
                        for (var level in levels)
                            for (var i = 0; i < levels[level].length; i++)
                                if (levels[level][i].namespace === "quickshell:bar")
                                    tops[output] = levels[level][i].y;
                    }
                } catch (e) {}
                root.barTops = tops;
            }
        }

    }

    // command-center quick actions
    Process {
        id: ccScreenshot

        command: ["uwsm", "app", "--", "hyprshot", "-m", "region", "-z"]
        running: false
    }

    Process {
        id: ccLock

        command: ["uwsm", "app", "--", "hyprlock"]
        running: false
    }

    // MprisPlayer.position is not reactive — reading it is always current but
    // bindings only refresh when positionChanged fires (players emit it on
    // seeks, not continuously). Re-emit it on a fast tick while the command
    // center is open and a track is playing so the progress row moves.
    Timer {
        interval: 500
        running: root.ccOpen && root.activePlayer !== null && root.activePlayer.isPlaying
        repeat: true
        triggeredOnStart: true
        onTriggered: root.activePlayer.positionChanged()
    }

    // keeps brightness sliders in sync (set is done by brightnessctl, files
    // catch up a moment later)
    Timer {
        interval: 1500
        running: root.ccOpen && root.backlightPath !== ""
        triggeredOnStart: true
        repeat: true
        onTriggered: {
            brightMaxLoader.reload();
            brightNowLoader.reload();
            root.brightMax = parseInt(brightMaxLoader.text().trim()) || 1;
            root.brightNow = parseInt(brightNowLoader.text().trim()) || 0;
        }
    }

    // tracked once at root — the bar's volume readout and the command-center
    // slider both read the default sink/source through it
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // shared by the cpu/memory/temperature boxes: click opens btop
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

    // accent-tinted icon glyph, vertically centered (color overridable per instance)
    component BarIcon: Text {
        color: root.col11
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
        color: root.col15
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

    // rounded group box: lays its children out in a centered row inside a
    // slightly rounded outline — border only, no fill (the bar background
    // shows through); `interactive` boxes get a faint tint fill on hover
    // (same treatment as the workspace pills). `tint` colors the border
    // (and the hover fill).
    component BarBox: Rectangle {
        default property alias content: boxRow.data
        property bool interactive: false
        property color tint: "white"

        Layout.preferredHeight: root.barHeight - 8
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 3
        Layout.rightMargin: 3
        implicitWidth: boxRow.implicitWidth + 20
        radius: 6
        color: interactive && boxHover.hovered ? Qt.alpha(tint, 0.10) : "transparent"
        border.width: 1
        border.color: Qt.alpha(tint, interactive && boxHover.hovered ? 0.55 : 0.35)

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

        HoverHandler {
            id: boxHover

            cursorShape: interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        RowLayout {
            id: boxRow

            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }

            spacing: 5
        }

    }

    // short separator between stats inside one box
    component MiniSeparator: Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 10
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 7
        Layout.rightMargin: 7
        color: root.col1
    }

    // ── command center building blocks ──

    // card wrapping one command-center section; children land in an inner
    // column pinned to the card's full width
    component CcSection: Rectangle {
        default property alias content: secCol.data

        Layout.fillWidth: true
        radius: 6
        color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.15)
        implicitHeight: secCol.implicitHeight + 16

        ColumnLayout {
            id: secCol

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }

            spacing: 8
        }

    }

    // small icon button used for transport, month nav and quick actions
    component CcButton: Rectangle {
        id: ccBtn

        property string glyph
        property var onActivate: () => {
        }

        implicitWidth: 34
        implicitHeight: 26
        radius: 5
        color: btnMa.containsMouse ? Qt.alpha(root.col16, 0.30) : Qt.alpha(root.col16, 0.12)

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

        Text {
            anchors.centerIn: parent
            text: ccBtn.glyph
            font.family: root.iconFont
            font.pixelSize: root.iconSize
            color: btnMa.containsMouse ? root.col15 : root.col14
        }

        MouseArea {
            id: btnMa

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ccBtn.onActivate()
        }

    }

    // themed slider: thin accent track over a dim groove, round handle
    component CcSlider: Slider {
        id: ccSlider

        implicitHeight: 22

        background: Rectangle {
            x: ccSlider.leftPadding
            y: ccSlider.topPadding + (ccSlider.availableHeight - height) / 2
            width: ccSlider.availableWidth
            height: 4
            radius: 2
            color: Qt.alpha(root.col16, 0.15)

            Rectangle {
                width: ccSlider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: root.col16
            }

        }

        handle: Rectangle {
            x: ccSlider.leftPadding + ccSlider.visualPosition * (ccSlider.availableWidth - width)
            y: ccSlider.topPadding + (ccSlider.availableHeight - height) / 2
            width: 12
            height: 12
            radius: 6
            color: root.col15
            border.width: 1
            border.color: root.colBg
        }

    }

    // right-aligned dim value readout next to a slider
    component CcValueText: Text {
        color: root.col5
        font.pixelSize: root.fontSize - 1
        font.family: root.fontFamily
        Layout.preferredWidth: 34
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
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

            // identifies the bar in `hyprctl layers` so the command center
            // can anchor to its real (possibly stacked) position
            WlrLayershell.namespace: "quickshell:bar"

            Rectangle {
                anchors.fill: parent
                color: root.colBg

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // ── left: workspaces ──
                    // one shared pill behind the row; the buttons keep their
                    // own hover/active pill inside it
                    Rectangle {
                        id: workspaceContainer

                        Layout.preferredHeight: root.barHeight - 8
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: root.pad
                        Layout.preferredWidth: workspaceRow.implicitWidth + 12
                        radius: 6
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.35)

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

                                    width: wsLabel.implicitWidth + 10
                                    height: root.barHeight - 14
                                    radius: 5
                                    // active workspace gets a translucent accent
                                    // fill — visible without shouting
                                    color: isActive ? Qt.alpha(root.col16, 0.40) : (hoverArea.containsPress ? Qt.rgba(1, 1, 1, 0.13) : (hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"))

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }

                                    }

                                    Text {
                                        id: wsLabel

                                        anchors.centerIn: parent
                                        text: modelData
                                        color: isActive ? root.col15 : (hasWindows ? root.col15 : root.col1)
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
                    BarBox {
                        visible: root.audioTitle !== ""
                        tint: root.activePlayer?.isPlaying ? root.col7 : root.col3

                        BarIcon {
                            text: root.activePlayer?.isPlaying ? "󰎈" : "󰏤"
                            color: root.activePlayer?.isPlaying ? root.col7 : root.col3
                        }

                        BarText {
                            text: root.audioAuthor !== "" ? root.audioAuthor + " - " + root.audioTitle : root.audioTitle
                            color: root.activePlayer?.isPlaying ? root.col7 : root.col3
                            Layout.maximumWidth: 300
                            elide: Text.ElideRight
                        }

                    }

                    // Stats: volume + battery + resources share one box.
                    // Volume — click toggles mute, middle-click opens pavucontrol, wheel steps 1%
                    BarBox {
                        interactive: true

                        Item {
                            id: volumeRoot

                            readonly property PwNode defaultSink: Pipewire.defaultAudioSink
                            readonly property PwNode source: Pipewire.defaultAudioSource

                            Layout.fillHeight: true
                            Layout.preferredWidth: volumeRow.implicitWidth

                            RowLayout {
                                id: volumeRow

                                anchors.centerIn: parent
                                spacing: 5

                                BarIcon {
                                    text: volumeIcon(volumeRoot.defaultSink?.audio?.muted ?? false, volumeRoot.defaultSink?.audio?.volume || 0)
                                    color: volumeRoot.defaultSink?.audio?.muted ? root.col3 : root.col14
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

                        MiniSeparator { }

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

                        MiniSeparator {
                            visible: root.hasBattery
                        }

                        // CPU / memory / temperature — click opens btop
                        // (shared root process)
                        Item {
                            id: resourcesContainer

                            Layout.fillHeight: true
                            Layout.preferredWidth: resourcesRow.implicitWidth

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
                                    text: cpuIcon(root.cpuUsage)
                                    color: root.cpuColor(root.cpuUsage)
                                }

                                BarText {
                                    text: root.cpuUsage + "%"
                                    color: root.cpuColor(root.cpuUsage)
                                }

                                MiniSeparator { }

                                BarIcon {
                                    text: memIcon(root.memUsage)
                                    color: root.memColor(root.memUsage)
                                }

                                BarText {
                                    text: root.memUsage + "%"
                                    color: root.memColor(root.memUsage)
                                }

                                MiniSeparator { }

                                BarIcon {
                                    text: tempIcon(root.cpuTemp)
                                    color: root.tempColor(root.cpuTemp)
                                }

                                BarText {
                                    text: root.cpuTemp.toFixed(1) + "°C"
                                    color: root.tempColor(root.cpuTemp)
                                }

                            }

                        }

                    }

                    // Tray
                    BarBox {
                        visible: sysTray.count > 0

                        Row {
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

                    // Clock — click toggles the command center
                    BarBox {
                        Layout.rightMargin: root.pad
                        tint: root.col16
                        interactive: true

                        Item {
                            id: clockRoot

                            Layout.fillHeight: true
                            Layout.preferredWidth: clockText.implicitWidth

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onContainsMouseChanged: root.ccHoverClock = containsMouse
                                onClicked: root.toggleCc(modelData)
                            }

                            BarText {
                                id: clockText

                                anchors.verticalCenter: parent.verticalCenter
                                text: Qt.locale().toString(clock.date, "dddd - dd/MM/yyyy - hh:mm")
                                color: root.col16

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

    }

    // ── command center hover-dismiss: the popup closes on its own when the
    // pointer rests over neither the popup nor the clock for a moment. There is
    // deliberately no full-screen click-catcher — clicks outside the popup pass
    // through to the windows below.
    Timer {
        interval: 150
        running: root.ccOpen && !root.ccHoverPopup && !root.ccHoverClock
        onTriggered: root.ccOpen = false
    }

    // ── command center panel: media, volume, brightness, quick actions,
    // calendar — anchored under the clock on the screen whose clock was clicked
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData

            screen: modelData
            visible: root.ccOpen && root.ccScreen === modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 340
            implicitHeight: ccBox.implicitHeight

            anchors {
                top: true
                right: true
            }

            margins {
                top: (root.barTops[modelData.name] ?? 0) + root.barHeight
                right: root.pad
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Rectangle {
                id: ccBox

                anchors.fill: parent
                radius: 10
                color: root.colBg
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)
                implicitHeight: ccCol.implicitHeight + 20

                HoverHandler {
                    onHoveredChanged: root.ccHoverPopup = hovered
                }

                ColumnLayout {
                    id: ccCol

                    anchors {
                        fill: parent
                        margins: 10
                    }

                    spacing: 10

                    // ── media ──
                    CcSection {
                        visible: root.activePlayer !== null

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "󰎈"
                                font.family: root.iconFont
                                font.pixelSize: root.iconSize + 7
                                color: root.activePlayer?.isPlaying ? root.col16 : root.col3

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }

                                }

                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: root.audioTitle !== "" ? root.audioTitle : "No media"
                                    color: root.col14
                                    font.pixelSize: root.fontSize
                                    font.family: root.fontFamily
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: root.audioAuthor
                                    visible: root.audioAuthor !== ""
                                    color: root.col5
                                    font.pixelSize: root.fontSize - 1
                                    font.family: root.fontFamily
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                            }

                        }

                        // progress: thin accent fill on a dim groove
                        // (hidden for livestreams — no meaningful length)
                        RowLayout {
                            visible: root.activePlayer !== null && !root.mediaLive
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: root.fmtSec(root.activePlayer?.position ?? 0)
                                color: root.col5
                                font.pixelSize: root.fontSize - 1
                                font.family: root.fontFamily
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 4
                                radius: 2
                                color: Qt.alpha(root.col16, 0.15)

                                Rectangle {
                                    width: parent.width * ((root.activePlayer && root.activePlayer.length > 0) ? Math.min(1, (root.activePlayer.position ?? 0) / root.activePlayer.length) : 0)
                                    height: parent.height
                                    radius: 2
                                    color: root.col16
                                }

                            }

                            Text {
                                text: root.fmtSec(root.activePlayer?.length ?? 0)
                                color: root.col5
                                font.pixelSize: root.fontSize - 1
                                font.family: root.fontFamily
                            }

                        }

                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            CcButton {
                                glyph: "󰒮"
                                onActivate: () => root.activePlayer?.previous()
                            }

                            CcButton {
                                implicitWidth: 44
                                glyph: root.activePlayer?.isPlaying ? "󰏤" : "󰐊"
                                onActivate: () => root.activePlayer?.togglePlaying()
                            }

                            CcButton {
                                glyph: "󰒭"
                                onActivate: () => root.activePlayer?.next()
                            }

                        }

                    }

                    // ── volume + brightness ──
                    CcSection {
                        RowLayout {
                            visible: root.sinkAudio !== null
                            Layout.fillWidth: true
                            spacing: 8

                            CcButton {
                                implicitWidth: 28
                                glyph: root.volumeIcon(root.sinkAudio?.muted ?? false, root.sinkAudio?.volume ?? 0)
                                onActivate: () => {
                                    if (root.sinkAudio)
                                        root.sinkAudio.muted = !root.sinkAudio.muted;
                                }
                            }

                            CcSlider {
                                id: volSlider

                                Layout.fillWidth: true
                                from: 0
                                to: 1
                                stepSize: 0.01
                                wheelEnabled: true // scroll to step
                                value: volSlider.pressed ? volSlider.value : (root.sinkAudio?.volume ?? 0)
                                onMoved: {
                                    if (root.sinkAudio)
                                        root.sinkAudio.volume = volSlider.value;
                                }
                            }

                            CcValueText {
                                text: Math.floor(volSlider.value * 100) + "%"
                            }

                        }

                        RowLayout {
                            visible: root.backlightPath !== ""
                            Layout.fillWidth: true
                            spacing: 8

                            CcButton {
                                implicitWidth: 28
                                glyph: "󰃟"
                                onActivate: () => {
                                    // tap the icon: jump to 0 / back to previous
                                    if (root.brightPerc > 0) {
                                        root.ccPrevBright = root.brightNow;
                                        root.brightNow = 0;
                                    } else {
                                        root.brightNow = root.ccPrevBright > 0 ? root.ccPrevBright : Math.round(root.brightMax / 3);
                                    }

                                    brightSet.command = ["brightnessctl", "-q", "set", Math.round(100 * root.brightNow / Math.max(1, root.brightMax)) + "%"];
                                    brightSet.running = true;
                                }
                            }

                            CcSlider {
                                id: brightSlider

                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                stepSize: 1
                                value: brightSlider.pressed ? brightSlider.value : root.brightPerc
                                onPressedChanged: {
                                    if (pressed)
                                        return ;

                                    root.brightNow = Math.round(brightSlider.value / 100 * root.brightMax);
                                    brightSet.command = ["brightnessctl", "-q", "set", Math.round(brightSlider.value) + "%"];
                                    brightSet.running = true;
                                }
                            }

                            CcValueText {
                                text: Math.round(brightSlider.value) + "%"
                            }

                        }

                    }

                    // ── quick actions ──
                    CcSection {
                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            CcButton {
                                glyph: "󰄀"
                                onActivate: () => ccScreenshot.running = true
                            }

                            CcButton {
                                glyph: "󰌾"
                                onActivate: () => ccLock.running = true
                            }

                            CcButton {
                                glyph: "󰻠"
                                onActivate: () => btop.running = true
                            }

                        }

                    }

                    // ── calendar ──
                    CcSection {
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            CcButton {
                                glyph: "‹"
                                onActivate: () => root.ccMonth = new Date(root.ccMonth.getFullYear(), root.ccMonth.getMonth() - 1, 1)
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Qt.locale().standaloneMonthName(root.ccMonth.getMonth(), Locale.LongFormat) + " " + root.ccMonth.getFullYear()
                                color: root.col14
                                font.pixelSize: root.fontSize
                                font.family: root.fontFamily
                                font.bold: true

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.ccMonth = new Date(ccClock.date.getFullYear(), ccClock.date.getMonth(), 1)
                                }

                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            CcButton {
                                glyph: "›"
                                onActivate: () => root.ccMonth = new Date(root.ccMonth.getFullYear(), root.ccMonth.getMonth() + 1, 1)
                            }

                        }

                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2

                            Repeater {
                                model: root.ccWeekdays

                                Item {
                                    width: 40
                                    height: 20

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: root.col3
                                        font.pixelSize: root.fontSize - 1
                                        font.family: root.fontFamily
                                    }

                                }

                            }

                        }

                        Grid {
                            Layout.alignment: Qt.AlignHCenter
                            columns: 7
                            spacing: 2

                            Repeater {
                                model: root.ccCells

                                Item {
                                    id: ccDay

                                    readonly property bool isToday: !modelData.other && new Date(root.ccMonth.getFullYear(), root.ccMonth.getMonth(), modelData.day).toDateString() === ccClock.date.toDateString()

                                    width: 40
                                    height: 24

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 5
                                        color: ccDay.isToday ? Qt.alpha(root.col16, 0.40) : "transparent"
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.day
                                        color: modelData.other ? root.col3 : (ccDay.isToday ? root.col15 : root.col14)
                                        font.pixelSize: root.fontSize - 1
                                        font.family: root.fontFamily
                                        font.bold: ccDay.isToday
                                    }

                                }

                            }

                        }

                    }

                }

            }

        }

    }

}
