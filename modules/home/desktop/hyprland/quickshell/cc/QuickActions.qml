// command center: quick actions — screenshot, lock, caffeine (idle
// inhibit), btop. The caffeine state lives in the AppState singleton (the
// bar surface holds the Wayland idle-inhibit); the processes are owned here.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."
import "../ui"

CcSection {
    id: quickActions

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

    // own btop launcher — pidof guard keeps it from doubling with the
    // resources segment's
    Process {
        id: btop

        command: ["sh", "-c", "pidof btop >/dev/null || uwsm app -- btop.desktop"]
        running: false
    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        CcButton {
            glyph: "󰄀"
            name: "Screenshot"
            onActivate: () => ccScreenshot.running = true
        }

        CcButton {
            glyph: "󰌾"
            name: "Lock"
            onActivate: () => ccLock.running = true
        }

        // caffeine: filled cup + accent while inhibiting
        CcButton {
            glyph: AppState.idleInhibited ? "󰅶" : "󰅵"
            active: AppState.idleInhibited
            name: AppState.idleInhibited ? "Allow idle" : "Inhibit idle"
            onActivate: () => {
                AppState.idleInhibited = !AppState.idleInhibited;
            }
        }

        CcButton {
            glyph: "󰻠"
            name: "System resources"
            onActivate: () => btop.running = true
        }

    }

}
