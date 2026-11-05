pragma Singleton
import QtQuick
import Quickshell

// Pure helpers shared by shell.qml and the extracted components: icon
// glyphs, status colors, time/calendar formatting. Colors come from Theme;
// no state lives here.
Singleton {
    // status colors: warning values shift to accentAlt (col11), critical ones
    // to urgent (the matugen error color) — icon and value shift together
    function tempColor(t) {
        return t >= 85 ? Theme.colUrgent : (t >= 70 ? Theme.col11 : Theme.col14);
    }

    function cpuColor(u) {
        return u >= 85 ? Theme.colUrgent : (u >= 70 ? Theme.col11 : Theme.col14);
    }

    function memColor(u) {
        return u >= 90 ? Theme.colUrgent : (u >= 75 ? Theme.col11 : Theme.col14);
    }

    function batteryColor(p, charging) {
        if (charging)
            return Theme.col14;
        return p <= 15 ? Theme.colUrgent : (p <= 30 ? Theme.col11 : Theme.col14);
    }

    // icon follows the charge level (md-battery_10..90), shows a bolt while
    // charging and md-battery_alert when critical
    function batteryIcon(p, charging) {
        if (charging)
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

    // md-microphone / md-microphone_off for the default source state
    function micIcon(muted) {
        return muted ? "󰍭" : "󰍬";
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

    // MprisPlayer reports position/length in seconds (ms precision)
    function fmtSec(sec) {
        if (!sec || sec <= 0)
            return "0:00";
        var s = Math.floor(sec);
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

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
}
